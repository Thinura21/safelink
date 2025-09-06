import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String code;
  final String message;
  ApiException(this.code, this.message);
  @override
  String toString() => 'ApiException($code)';
}

class ApiClient {
  final String baseUrl;
  final Future<String?> Function() readToken; 
  ApiClient(this.baseUrl, this.readToken);

  // ----------------- Helpers -----------------
  Future<Map<String, String>> _authHeaders({Map<String, String>? extra}) async {
    final t = await readToken();
    return {
      if (extra != null) ...extra,
      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };
  }

  Map<String, dynamic> _decode(http.Response res) {
    try { return jsonDecode(res.body) as Map<String, dynamic>; }
    catch (_) { return {'success': false}; }
  }

  Never _throwApi(Map<String, dynamic> json) {
    final err = (json['error'] as Map?) ?? {};
    final code = (err['code'] ?? 'UNKNOWN').toString();
    final msg  = (err['message'] ?? 'Unknown').toString();
    throw ApiException(code, msg);
  }

  // ----------------- Auth -----------------
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

  // =========================================================
  // ==============   ADMIN: Emergency / Incidents  ==========
  // =========================================================

  Future<List<Map<String, dynamic>>> adminListIncidents({
    String statuses = 'open,assigned,en_route,arrived,resolved,cancelled',
    String q = '',
    int limit = 300,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/emergency/incidents').replace(
      queryParameters: {
        'status': statuses,
        if (q.isNotEmpty) 'q': q,
        'limit': '$limit',
      },
    );
    final res = await http.get(uri, headers: await _authHeaders());
    final j = _decode(res);
    if (res.statusCode != 200) _throwApi(j);
    final items = (j['items'] as List? ?? []);
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Read one incident with populated reporter/officer.
  Future<Map<String, dynamic>> adminGetIncident(String ref) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/emergency/incidents/$ref'),
      headers: await _authHeaders(),
    );
    final j = _decode(res);
    if (res.statusCode != 200) _throwApi(j);
    return Map<String, dynamic>.from(j['incident'] as Map);
  }

  /// List active officers for quick-assign.
  Future<List<Map<String, dynamic>>> adminGetOfficers({String q = ''}) async {
    final uri = Uri.parse('$baseUrl/api/admin/emergency/officers')
        .replace(queryParameters: { if (q.isNotEmpty) 'q': q });
    final res = await http.get(uri, headers: await _authHeaders());
    final j = _decode(res);
    if (res.statusCode != 200) _throwApi(j);
    final items = (j['items'] as List? ?? []);
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Patch incident fields (type/status/priority/etaMinutes/note/etc).
  Future<Map<String, dynamic>> adminPatchIncident(
    String ref,
    Map<String, dynamic> body,
  ) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/emergency/incidents/$ref'),
      headers: await _authHeaders(extra: {'Content-Type': 'application/json'}),
      body: jsonEncode(body),
    );
    final j = _decode(res);
    if (res.statusCode != 200) _throwApi(j);
    return Map<String, dynamic>.from(j['incident'] as Map);
  }

  /// Assign officer + optional ETA + note.
  Future<Map<String, dynamic>> adminAssignOfficer({
    required String ref,
    required String officerId,
    int? etaMinutes,
    String? note,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/admin/emergency/incidents/$ref/assign'),
      headers: await _authHeaders(extra: {'Content-Type': 'application/json'}),
      body: jsonEncode({'officerId': officerId, 'etaMinutes': etaMinutes, 'note': note}),
    );
    final j = _decode(res);
    if (res.statusCode != 200) _throwApi(j);
    return Map<String, dynamic>.from(j['incident'] as Map);
  }

  /// Set/update ETA only.
  Future<Map<String, dynamic>> adminEtaIncident(String ref, int? etaMinutes) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/admin/emergency/incidents/$ref/eta'),
      headers: await _authHeaders(extra: {'Content-Type': 'application/json'}),
      body: jsonEncode({'etaMinutes': etaMinutes}),
    );
    final j = _decode(res);
    if (res.statusCode != 200) _throwApi(j);
    return Map<String, dynamic>.from(j['incident'] as Map);
  }

  /// Delete incident (hard delete).
  Future<void> adminDeleteIncident(String ref) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/admin/emergency/incidents/$ref'),
      headers: await _authHeaders(),
    );
    final j = _decode(res);
    if (res.statusCode != 200) _throwApi(j);
  }

  /// Get recent chat messages if backend Chat model exists.
  Future<List<Map<String, dynamic>>> adminGetMessages(String ref) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/emergency/incidents/$ref/messages'),
      headers: await _authHeaders(),
    );
    final j = _decode(res);
    if (res.statusCode != 200) _throwApi(j);
    final items = (j['items'] as List? ?? []);
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Admin adds more evidence images to an incident.
  Future<void> adminUploadIncidentImages(String ref, List<File> files) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/admin/emergency/incidents/$ref/images'),
    );
    request.headers.addAll(await _authHeaders());
    for (final f in files) {
      request.files.add(await http.MultipartFile.fromPath('images', f.path));
    }
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final j = _decode(res);
    if (res.statusCode != 200 && res.statusCode != 201) _throwApi(j);
  }

  /// Create incident from dashboard.
  Future<Map<String, dynamic>> adminCreateIncidentEmergency(
    Map<String, dynamic> body,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/admin/emergency/incidents'),
      headers: await _authHeaders(extra: {'Content-Type': 'application/json'}),
      body: jsonEncode(body),
    );
    final j = _decode(res);
    if (res.statusCode != 201) _throwApi(j);
    return Map<String, dynamic>.from(j['incident'] as Map);
  }

  // =========================================================
  // ==============          ADMIN: Users          ===========
  // =========================================================

  Future<Map<String, dynamic>> adminListUsers({
    String? q,
    String? role,
    bool? isVerified,
    bool? isActive,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (role != null && role.isNotEmpty) 'role': role,
      if (isVerified != null) 'isVerified': isVerified.toString(),
      if (isActive != null) 'isActive': isActive.toString(),
    };
    final uri = Uri.parse('$baseUrl/api/admin/users').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _authHeaders());
    final json = _decode(res);
    if (res.statusCode != 200) _throwApi(json);
    return json;
  }

  Future<Map<String, dynamic>> adminCreateUser(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/admin/users'),
      headers: await _authHeaders(extra: {'Content-Type': 'application/json'}),
      body: jsonEncode(body),
    );
    final json = _decode(res);
    if (res.statusCode != 201) _throwApi(json);
    return json;
  }

  Future<Map<String, dynamic>> adminUpdateUser(String id, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/users/$id'),
      headers: await _authHeaders(extra: {'Content-Type': 'application/json'}),
      body: jsonEncode(body),
    );
    final json = _decode(res);
    if (res.statusCode != 200) _throwApi(json);
    return json;
  }

  Future<void> adminDeleteUser(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/admin/users/$id'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      final json = _decode(res);
      _throwApi(json);
    }
  }

  // ---- thin alias used by your edit page ----
  Future<void> uploadIncidentImages(String ref, List<File> files) {
    return adminUploadIncidentImages(ref, files);
  }
  
  String fileUrl(String pathOrUrl) {
    final base = Uri.parse(baseUrl);

    // If it's a relative path, just join with base origin.
    if (!pathOrUrl.startsWith('http://') && !pathOrUrl.startsWith('https://')) {
      final p = pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl';
      return Uri(scheme: base.scheme, host: base.host, port: base.port, path: p).toString();
    }

    // Absolute URL: if it's pointing to another host but is an uploads resource,
    // swap the host to our baseUrl host so it works on web too.
    final u = Uri.tryParse(pathOrUrl);
    if (u != null && u.path.startsWith('/uploads/')) {
      if (u.host != base.host || u.port != base.port || u.scheme != base.scheme) {
        return Uri(scheme: base.scheme, host: base.host, port: base.port, path: u.path).toString();
      }
    }
    return pathOrUrl;
  }

}

// ---------- DTO ----------
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
