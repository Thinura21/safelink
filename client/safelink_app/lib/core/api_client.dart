import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_storage.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  ApiException(this.code, this.message);
  @override
  String toString() => 'ApiException($code)';
}

class ApiClient {
  final String baseUrl;
  ApiClient(this.baseUrl);

  // ---------- AUTH ----------
  Future<AuthResponse> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final json = _decode(res);
      if (res.statusCode != 200) _throwApi(json);
      return AuthResponse.fromJson(json);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('NETWORK', e.toString());
    }
  }

  Future<void> registerUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'fullName': fullName}),
      );
      final json = _decode(res);
      if (res.statusCode != 201) _throwApi(json);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('NETWORK', e.toString());
    }
  }

  // ---------- PROFILE ----------
  Future<Map<String, dynamic>> profileMe() async {
    final t = await AuthStorage.token;
    final res = await http.get(
      Uri.parse('$baseUrl/api/profile/me'),
      headers: {'Authorization': 'Bearer $t'},
    );
    final json = _decode(res);
    if (res.statusCode != 200) _throwApi(json);
    return json['user'] is Map ? Map<String, dynamic>.from(json['user']) : Map<String, dynamic>.from(json);
  }

  /// Smart profile update:
  Future<void> profileUpdate(Map<String, dynamic> body) async {
    final t = await AuthStorage.token;

    Map<String, dynamic> cleaned = _cleanDeep(body);

    // ----- Guardian compatibility -----
    if (cleaned['guardian'] is Map) {
      final g = Map<String, dynamic>.from(cleaned['guardian'] as Map);
      // allow either 'contact' or 'phone'
      final gContact = (g['contact'] ?? g['phone'])?.toString();
      final gName = (g['name'])?.toString();
      final gAddress = (g['address'])?.toString();

      // keep nested
      cleaned['guardian'] = _cleanDeep({
        if (gName != null && gName.isNotEmpty) 'name': gName,
        if (gContact != null && gContact.isNotEmpty) 'contact': gContact,
        if (gAddress != null && gAddress.isNotEmpty) 'address': gAddress,
      });

      // also provide flat keys for older handlers
      if (gName != null && gName.isNotEmpty) cleaned['guardian.name'] = gName;
      if (gContact != null && gContact.isNotEmpty) {
        cleaned['guardian.contact'] = gContact;
        cleaned['guardian.phone'] = gContact; // some servers expect 'phone'
      }
      if (gAddress != null && gAddress.isNotEmpty) cleaned['guardian.address'] = gAddress;
    }

    // ----- Officer specializations compatibility -----
    if (cleaned.containsKey('specializations')) {
      final specRaw = cleaned['specializations'];
      // accept "a, b, c" or List
      List<String> arr;
      if (specRaw is String) {
        arr = specRaw
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (specRaw is List) {
        arr = specRaw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
      } else {
        arr = const [];
      }
      cleaned['specializations'] = arr;
      // some handlers accept only the string — keep both
      if (specRaw is String && specRaw.trim().isNotEmpty) {
        cleaned['specializationsCsv'] = specRaw.trim();
      }
    }

    // if everything got cleaned away, no-op
    if (cleaned.isEmpty) return;

    final res = await http.patch(
      Uri.parse('$baseUrl/api/profile/me'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $t'},
      body: jsonEncode(cleaned),
    );
    final json = _decode(res);
    if (res.statusCode != 200) _throwApi(json);
  }

  /// Uploads an image file and returns the absolute URL.
  Future<String> uploadAvatar(File file) async {
    final t = await AuthStorage.token;
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/profile/me/avatar'));
    req.headers['Authorization'] = 'Bearer $t';
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final json = _decode(res);
    if (res.statusCode != 200 && res.statusCode != 201) _throwApi(json);
    final url = (json['url'] ?? json['profileImage'] ?? '').toString();
    if (url.isEmpty) throw ApiException('UNKNOWN', 'No URL returned');
    return url;
  }

  Future<String> uploadNic(File file) async {
    final t = await AuthStorage.token;
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/profile/me/nic'));
    req.headers['Authorization'] = 'Bearer $t';
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final json = _decode(res);
    if (res.statusCode != 200 && res.statusCode != 201) _throwApi(json);
    final url = (json['url'] ?? json['nicImage'] ?? '').toString();
    if (url.isEmpty) throw ApiException('UNKNOWN', 'No URL returned');
    return url;
  }

  // ---------- helpers ----------
  Map<String, dynamic> _decode(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {'success': false};
    }
  }

  Never _throwApi(Map<String, dynamic> json) {
    final err = (json['error'] as Map?) ?? {};
    final code = (err['code'] ?? 'UNKNOWN').toString();
    final msg = (err['message'] ?? 'Unknown').toString();
    throw ApiException(code, msg);
  }

  /// Deep-clean a map: drops null, empty strings, and empty maps/lists.
  Map<String, dynamic> _cleanDeep(Map<String, dynamic> src) {
    final out = <String, dynamic>{};
    for (final entry in src.entries) {
      final k = entry.key;
      final v = entry.value;
      if (v == null) continue;
      if (v is String) {
        final s = v.trim();
        if (s.isEmpty) continue;
        out[k] = s;
      } else if (v is Map) {
        final m = _cleanDeep(Map<String, dynamic>.from(v));
        if (m.isNotEmpty) out[k] = m;
      } else if (v is Iterable) {
        final list = v.map((e) => e is String ? e.trim() : e).where((e) {
          if (e == null) return false;
          if (e is String) return e.isNotEmpty;
          return true;
        }).toList();
        if (list.isNotEmpty) out[k] = list;
      } else {
        out[k] = v;
      }
    }
    return out;
  }

  // Returns null if no open incident.
// Future<Map<String, dynamic>?> getMyActiveIncident() async {
//   final t = await AuthStorage.token;
//   final res = await http.get(
//     Uri.parse('$baseUrl/api/emergency/my/active'),
//     headers: {'Authorization': 'Bearer $t'},
//   );
//   if (res.statusCode == 204) return null;
//   final json = _decode(res);
//   if (res.statusCode != 200) _throwApi(json);
//   return json; // { success, incident, assignedOfficerName, etaMinutes }
// }

// === Emergency endpoints ===
  Future<Map<String, dynamic>> sendEmergencyAlert({
    required String type,
    required double lat,
    required double lng,
    String? description,
    String? priority,
  }) async {
    final t = await AuthStorage.token;
    final res = await http.post(
      Uri.parse('$baseUrl/api/emergency'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $t',
      },
      body: jsonEncode({
        'type': type,
        'lat': lat,
        'lng': lng,
        if (description != null) 'description': description,
        if (priority != null) 'priority': priority,
      }),
    );
    final json = _decode(res);
    if (res.statusCode != 201) _throwApi(json);

    final inc = (json['incident'] as Map?) ?? {};
    return {
      ...json,
      'incidentId': json['incidentId'] ?? inc['incidentId'],
      '_id': inc['_id'],
    };
  }

  Future<Map<String, dynamic>?> getMyActiveIncident() async {
    final t = await AuthStorage.token;
    final res = await http.get(
      Uri.parse('$baseUrl/api/emergency/my/active'),
      headers: {'Authorization': 'Bearer $t'},
    );
    if (res.statusCode == 204) return null;
    final json = _decode(res);
    if (res.statusCode != 200) _throwApi(json);
    return json; // { success, incident, incidentId, assignedOfficerName, etaMinutes }
  }

  // ---- Incidents: list mine ----
  Future<List<Map<String, dynamic>>> listMyIncidents() async {
    final t = await AuthStorage.token;
    final res = await http.get(
      Uri.parse('$baseUrl/api/emergency/my'),
      headers: {'Authorization': 'Bearer $t'},
    );
    final json = _decode(res);
    if (res.statusCode != 200) _throwApi(json);
    final items = (json['items'] as List? ?? []);
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ---- Read one incident by id or incidentId ----
  Future<Map<String, dynamic>> getIncident(String ref) async {
    final t = await AuthStorage.token;
    final res = await http.get(
      Uri.parse('$baseUrl/api/emergency/$ref'),
      headers: {'Authorization': 'Bearer $t'},
    );
    final json = _decode(res);
    if (res.statusCode != 200) _throwApi(json);
    return Map<String, dynamic>.from(json['incident'] as Map);
  }

  // ---- Update limited fields (see server route) ----
  Future<Map<String, dynamic>> updateIncident(String ref, Map<String, dynamic> body) async {
    final t = await AuthStorage.token;
    final res = await http.patch(
      Uri.parse('$baseUrl/api/emergency/$ref'),
      headers: {'Authorization': 'Bearer $t', 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final json = _decode(res);
    if (res.statusCode != 200) _throwApi(json);
    return Map<String, dynamic>.from(json['incident'] as Map);
  }

  // ---- Upload one or more images for the incident ----
  // Server route we add below: POST /api/emergency/:ref/images (multipart `images[]`)
  Future<List<String>> uploadIncidentImages(String ref, List<File> files) async {
    final t = await AuthStorage.token;
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/emergency/$ref/images'));
    req.headers['Authorization'] = 'Bearer $t';
    for (final f in files) {
      req.files.add(await http.MultipartFile.fromPath('images', f.path));
    }
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final json = _decode(res);
    if (res.statusCode != 200 && res.statusCode != 201) _throwApi(json);
    final urls = (json['images'] as List? ?? []).map((e) => e.toString()).toList();
    return urls;
  }


}

class AuthResponse {
  final bool success;
  final String token;
  final String refreshToken;
  final Map<String, dynamic> user;
  AuthResponse({
    required this.success,
    required this.token,
    required this.refreshToken,
    required this.user,
  });
  factory AuthResponse.fromJson(Map<String, dynamic> j) => AuthResponse(
        success: j['success'] == true,
        token: j['token'] ?? '',
        refreshToken: j['refreshToken'] ?? '',
        user: Map<String, dynamic>.from(j['user'] ?? {}),
      );
}
