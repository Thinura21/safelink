import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../core/app_state.dart';
import '../core/i18n.dart';
import '../theme/app_theme.dart';

// ========= ML server =========
const String kMlApiBase = 'http://10.0.2.2:8000';

typedef PatchFn = Future<void> Function(Map<String, dynamic> patch);
typedef UploadFn = Future<void> Function(List<File> files);

enum _Step { hi, askType, askCasualties, askBystander, askMore }

String _mapSeverityToPriority(String label) {
  switch (label.toLowerCase()) {
    case 'low':
      return 'low';      
    case 'medium':
      return 'high';     
    case 'high':
      return 'critical';
    default:
      return 'normal';
  }
}

class SimpleGuidedBot extends StatefulWidget {
  const SimpleGuidedBot({
    super.key,
    required this.incidentRef,
    required this.patchIncident,
    required this.uploadImages,
  });

  final String incidentRef;
  final PatchFn patchIncident;
  final UploadFn uploadImages;

  @override
  State<SimpleGuidedBot> createState() => _SimpleGuidedBotState();
}

class _SimpleGuidedBotState extends State<SimpleGuidedBot> {
  final _ctrl = TextEditingController();
  final _picker = ImagePicker();
  final _msgs = <_Msg>[];

  _Step _step = _Step.hi;
  bool _busy = false;

  String get _lang => AppState.lang.value;
  String t(String k) => I18n.t(_lang, k);

  // ---------- persistence ----------
  late SharedPreferences _prefs;
  String get _storeKey => 'chat_${widget.incidentRef}';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    _prefs = await SharedPreferences.getInstance();
    _loadHistory();
    if (_msgs.isEmpty) {
      _bot(t('bot.hi_short'));
      _step = _Step.askType;
    }
    if (mounted) setState(() {});
  }

  void _loadHistory() {
    final raw = _prefs.getString(_storeKey);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _msgs
      ..clear()
      ..addAll(list.map(_Msg.fromJson));
  }

  Future<void> _saveHistory() async {
    final raw = jsonEncode(_msgs.map((e) => e.toJson()).toList());
    await _prefs.setString(_storeKey, raw);
  }

  // ---------- helpers ----------
  void _bot(String text) {
    if (!mounted) return;
    setState(() => _msgs.add(_Msg(text: text, isUser: false)));
    _saveHistory();
  }

  void _botImage({
    required String path,
    String? caption,
    String? label,
    double? conf,
  }) {
    if (!mounted) return;
    setState(() => _msgs.add(_Msg(
      isUser: false,
      imagePath: path,
      text: caption ?? '',
      label: label,
      conf: conf,
    )));
    _saveHistory();
  }

  void _me(String text) {
    if (!mounted) return;
    setState(() => _msgs.add(_Msg(text: text, isUser: true)));
    _saveHistory();
  }

  Future<void> _submitPatch(Map<String, dynamic> patch) async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await widget.patchIncident(patch);
      _bot(I18n.t(_lang, 'bot.saved'));
    } catch (e) {
      _bot('${I18n.t(_lang, "bot.err")}: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- quick chips ----------
  Future<void> _setType(String type) async {
    _me(type);
    await _submitPatch({'type': type});
    setState(() => _step = _Step.askCasualties);
    _bot(I18n.t(_lang, 'bot.q.casualties'));
  }

  Future<void> _setCasualties(int n) async {
    _me('$n');
    await _submitPatch({'casualties': n});
    setState(() => _step = _Step.askBystander);
    _bot(I18n.t(_lang, 'bot.q.bystander'));
  }

  Future<void> _setBystander(bool val) async {
    _me(val ? I18n.t(_lang, 'common.yes') : I18n.t(_lang, 'common.no'));
    await _submitPatch({'bystander': val});
    setState(() => _step = _Step.askMore);
    _bot(I18n.t(_lang, 'bot.q.more'));
  }

  // ---------- photo picking + SERVER inference ----------
  Future<void> _pickPhoto() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Pick from gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (src == null) return;

    final x = await _picker.pickImage(source: src, imageQuality: 85);
    if (x == null) return;

    final file = File(x.path);
    _me(t('bot.addImages'));
    if (!mounted) return;
    setState(() => _busy = true);

    try {
      // Send image to ML API
      final uri = Uri.parse('$kMlApiBase/predict');
      final req = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final label = (data['label'] ?? '').toString();
        final conf = (data['confidence'] is num)
            ? (data['confidence'] as num).toDouble()
            : null;
        final priority = _mapSeverityToPriority(label);

        await widget.patchIncident({'priority': priority});

        _botImage(
          path: file.path,
          caption: 'Photo analyzed.',
          label: label,
          conf: conf,
        );

        _bot(
          'Severity: $label '
          '(${conf == null ? '-' : (conf * 100).toStringAsFixed(0)}%). '
          'Priority updated to "$priority".',
        );
      } else {
        _bot('❌ ML server error: ${resp.statusCode}');
        _botImage(path: file.path, caption: 'Photo uploaded.');
      }

      await widget.uploadImages([file]);
    } catch (e) {
      _bot('${I18n.t(_lang, "bot.err")}: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- simple local “NLU” ----------
  Future<void> _handleSend() async {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) return;
    _ctrl.clear();
    _me(raw);

    final low = raw.toLowerCase();

    // type
    for (final tp in ['medical', 'fire', 'crime', 'accident', 'other']) {
      if (low.contains(tp)) {
        await _setType(tp);
        return;
      }
    }

    // casualties
    if (_step == _Step.askCasualties) {
      final m = RegExp(r'\d+').firstMatch(low);
      if (m != null) {
        await _setCasualties(int.parse(m.group(0)!));
        return;
      }
    }

    // bystander
    if (_step == _Step.askBystander) {
      if (RegExp(r'\b(yes|y|true|yeah|ඔව්)\b').hasMatch(low)) {
        await _setBystander(true);
        return;
      }
      if (RegExp(r'\b(no|n|false|නැහැ)\b').hasMatch(low)) {
        await _setBystander(false);
        return;
      }
    }

    // photo
    if (low.contains('photo') ||
        low.contains('image') ||
        low.contains('upload') ||
        low.contains('පින්තූර')) {
      await _pickPhoto();
      return;
    }

    // note: <text>
    final noteIdx = low.indexOf('note:');
    if (noteIdx == 0 || low.startsWith('විස්තර:') || low.startsWith('note -')) {
      final note = raw.split(':').skip(1).join(':').trim();
      if (note.isNotEmpty) {
        await _submitPatch({'description': note});
        return;
      }
    }

    if (low == 'help' || low == 'උදවු' || low == 'instructions') {
      _bot(I18n.t(_lang, 'bot.help'));
      return;
    }

    _bot(I18n.t(_lang, 'bot.useChips'));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    String currentQ() {
      switch (_step) {
        case _Step.askType:
          return I18n.t(_lang, 'bot.q.type');
        case _Step.askCasualties:
          return I18n.t(_lang, 'bot.q.casualties');
        case _Step.askBystander:
          return I18n.t(_lang, 'bot.q.bystander');
        case _Step.askMore:
          return I18n.t(_lang, 'bot.q.more');
        default:
          return '';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(I18n.t(_lang, 'bot.title'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        Container(
          height: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _msgs.length,
            itemBuilder: (_, i) {
              final m = _msgs[i];
              final bubble = Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: m.isUser
                      ? AppTheme.primaryRed.withOpacity(0.08)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: m.isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (m.imagePath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(m.imagePath!),
                          width: 160,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (m.label != null && m.conf != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Severity: ${m.label} • ${(m.conf! * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (m.text.isNotEmpty) ...[
                      if (m.imagePath != null ||
                          (m.label != null && m.conf != null))
                        const SizedBox(height: 6),
                      Text(m.text),
                    ],
                  ],
                ),
              );

              return Align(
                alignment:
                    m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: bubble,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // chips
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (_step == _Step.askType) ...[
            for (final tp in ['medical', 'fire', 'crime', 'accident', 'other'])
              ActionChip(
                label: Text(tp),
                onPressed: _busy ? null : () => _setType(tp),
              ),
          ],
          if (_step == _Step.askCasualties) ...[
            for (final n in [0, 1, 2, 3, 5])
              ActionChip(
                label: Text('$n'),
                onPressed: _busy ? null : () => _setCasualties(n),
              ),
          ],
          if (_step == _Step.askBystander) ...[
            ActionChip(
              label: Text(I18n.t(_lang, 'common.yes')),
              onPressed: _busy ? null : () => _setBystander(true),
            ),
            ActionChip(
              label: Text(I18n.t(_lang, 'common.no')),
              onPressed: _busy ? null : () => _setBystander(false),
            ),
          ],
          ActionChip(
            label: const Text('Upload photo'),
            onPressed: _busy ? null : _pickPhoto,
          ),
        ]),

        const SizedBox(height: 8),

        // input row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText:
                      currentQ().isEmpty ? I18n.t(_lang, 'bot.hint') : currentQ(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(96, 44),
                  maximumSize: const Size(96, 44),
                ),
                onPressed: _busy ? null : _handleSend,
                child: _busy
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(I18n.t(_lang, 'bot.send')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Using server model at $kMlApiBase',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}

class _Msg {
  final bool isUser;
  final String text;
  final String? imagePath;
  final String? label;
  final double? conf;

  _Msg({
    required this.isUser,
    this.text = '',
    this.imagePath,
    this.label,
    this.conf,
  });

  Map<String, dynamic> toJson() => {
        'isUser': isUser,
        'text': text,
        'imagePath': imagePath,
        'label': label,
        'conf': conf,
      };

  factory _Msg.fromJson(Map<String, dynamic> j) => _Msg(
        isUser: j['isUser'] == true,
        text: (j['text'] ?? '').toString(),
        imagePath: j['imagePath']?.toString(),
        label: j['label']?.toString(),
        conf: (j['conf'] is num) ? (j['conf'] as num).toDouble() : null,
      );
}
