import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = "mayor_app_jwt_token";
  static const _rememberedEmailKey = "mayor_app_remembered_email";

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> saveRememberedEmail(String email) async {
    await _storage.write(key: _rememberedEmailKey, value: email);
  }

  static Future<String?> getRememberedEmail() async {
    return await _storage.read(key: _rememberedEmailKey);
  }

  static Future<void> removeRememberedEmail() async {
    await _storage.delete(key: _rememberedEmailKey);
  }

  static Future<void> clear() async {
    final email = await getRememberedEmail();
    await _storage.deleteAll();
    if (email != null) {
      await saveRememberedEmail(email);
    }
  }
}
