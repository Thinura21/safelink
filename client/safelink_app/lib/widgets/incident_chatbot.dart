import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_state.dart';
import '../../core/i18n.dart';
import '../theme/app_theme.dart';

typedef IncidentPatchCallback = Future<void> Function(Map<String, dynamic> patch);
typedef IncidentUploadCallback = Future<void> Function(List<File> files);

enum BotStep { hi, askCasualties, askBystander, askType, askMore }

class IncidentChatBot extends StatefulWidget {
  final IncidentPatchCallback onSubmitUpdate;
  final IncidentUploadCallback onUploadImages;
  const IncidentChatBot({
    super.key,
    required this.onSubmitUpdate,
    required this.onUploadImages,
  });

  @override
  State<IncidentChatBot> createState() => _IncidentChatBotState();
}

class _IncidentChatBotState extends State<IncidentChatBot> {
  final _ctrl = TextEditingController();
  final List<_Msg> _msgs = [];
  BotStep _step = BotStep.hi;
  bool _busy = false;

  String get _lang => AppState.lang.value;
  String _t(String k) => I18n.t(_lang, k);

  @override
  void initState() {
    super.initState();
    _bot(_t('bot.hi_short'));
    _step = BotStep.askCasualties;
  }

  void _bot(String t) => setState(() => _msgs.add(_Msg(t, false)));
  void _me(String t) => setState(() => _msgs.add(_Msg(t, true)));

  Future<void> _pickAndUploadImages() async {
    final picker = ImagePicker();
    final picks = await picker.pickMultiImage(imageQuality: 85);
    if (picks.isEmpty) return;
    await widget.onUploadImages(picks.map((x) => File(x.path)).toList());
    _bot(_t('bot.img.ok'));
  }

  Future<void> _submit(Map<String, dynamic> patch) async {
    setState(() => _busy = true);
    try {
      await widget.onSubmitUpdate(patch);
      _bot(_t('bot.saved'));
    } catch (e) {
      _bot('${_t("bot.err")}: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---- Guided flow chips ----
  Widget _chips() {
    switch (_step) {
      case BotStep.askCasualties:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final n in [0, 1, 2, 3, 5])
              ActionChip(
                label: Text('$n'),
                onPressed: _busy
                    ? null
                    : () async {
                        _me('$n');
                        await _submit({'casualties': n});
                        setState(() => _step = BotStep.askBystander);
                      },
              ),
            ActionChip(
              label: Text(_t('bot.skip')),
              onPressed: () => setState(() => _step = BotStep.askBystander),
            ),
          ],
        );

      case BotStep.askBystander:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: Text(_t('common.yes')),
              onPressed: _busy
                  ? null
                  : () async {
                      _me(_t('common.yes'));
                      await _submit({'bystander': true});
                      setState(() => _step = BotStep.askType);
                    },
            ),
            ActionChip(
              label: Text(_t('common.no')),
              onPressed: _busy
                  ? null
                  : () async {
                      _me(_t('common.no'));
                      await _submit({'bystander': false});
                      setState(() => _step = BotStep.askType);
                    },
            ),
            ActionChip(
              label: Text(_t('bot.skip')),
              onPressed: () => setState(() => _step = BotStep.askType),
            ),
          ],
        );

      case BotStep.askType:
        const types = ['medical', 'fire', 'crime', 'accident', 'other'];
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in types)
              ActionChip(
                label: Text(t),
                onPressed: _busy
                    ? null
                    : () async {
                        _me(t);
                        await _submit({'type': t});
                        setState(() => _step = BotStep.askMore);
                      },
              ),
            ActionChip(
              label: Text(_t('bot.skip')),
              onPressed: () => setState(() => _step = BotStep.askMore),
            ),
          ],
        );

      case BotStep.askMore:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: Text(_t('bot.addImages')),
              onPressed: _busy ? null : () async {
                _me(_t('bot.addImages'));
                await _pickAndUploadImages();
              },
            ),
            ActionChip(
              label: Text(_t('bot.addNote')),
              onPressed: _busy ? null : () {
                _bot(_t('bot.note.hint'));
              },
            ),
            ActionChip(
              label: Text(_t('bot.restart')),
              onPressed: () {
                setState(() => _step = BotStep.askCasualties);
                _bot(_t('bot.hi_short'));
              },
            ),
          ],
        );

      case BotStep.hi:
      default:
        return const SizedBox.shrink();
    }
  }

  // Free text only used when adding a note
  Future<void> _handleSend() async {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) return;
    _ctrl.clear();
    _me(raw);
    if (_step == BotStep.askMore) {
      await _submit({'description': raw});
    } else {
      _bot(_t('bot.useChips'));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Question for current step
    String q() {
      switch (_step) {
        case BotStep.askCasualties: return _t('bot.q.casualties');
        case BotStep.askBystander:  return _t('bot.q.bystander');
        case BotStep.askType:       return _t('bot.q.type');
        case BotStep.askMore:       return _t('bot.q.more');
        default: return '';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('bot.title'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Messages area
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          height: 260,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _msgs.length,
            itemBuilder: (_, i) {
              final m = _msgs[i];
              return Align(
                alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: m.isUser
                        ? AppTheme.primaryRed.withOpacity(0.06)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(m.text),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),
        Text(q(), style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        _chips(),

        const SizedBox(height: 10),

        // Input row (constrain the button to avoid infinite width in a Row)
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: _t('bot.hint'),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 48,
                maxWidth: 120,
                minHeight: 40,
              ),
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _handleSend,
                icon: _busy
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, size: 18),
                label: Text(_t('bot.send')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Msg {
  final String text;
  final bool isUser;
  _Msg(this.text, this.isUser);
}
