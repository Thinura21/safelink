import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _t = 'auth_token';
  static const _r = 'refresh_token';
  
  static Future<void> save(String token, String refresh) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_t, token);
    await p.setString(_r, refresh);
  }
  
  static Future<String?> get token async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_t);
  }
  
  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_t);
    await p.remove(_r);
  }
}
