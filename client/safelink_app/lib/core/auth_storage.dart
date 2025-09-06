import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _tokenKey = 'auth_token';
  static const _refreshKey = 'refresh_token';
  static final _storage = const FlutterSecureStorage();

  static Future<void> saveTokens(String token, String refresh) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  static Future<String?> get token async => await _storage.read(key: _tokenKey);
  static Future<String?> get refreshToken async => await _storage.read(key: _refreshKey);

  static Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
  }

  static Future<String?> readToken() => token;
}
