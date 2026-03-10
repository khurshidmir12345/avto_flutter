import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _tokenKey = 'auth_token';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const _userKey = 'user_data';
  static const _balanceHistoryViewedAtKey = 'balance_history_viewed_at';
  static const _themeIdKey = 'theme_id';
  static const _darkModeKey = 'dark_mode';
  static const _balanceTopupEnabledKey = 'balance_topup_enabled';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> saveUserData(String userData) async {
    await _storage.write(key: _userKey, value: userData);
  }

  static Future<String?> getUserData() async {
    return await _storage.read(key: _userKey);
  }

  /// Faqat auth ma'lumotlarini o'chiradi (token, user). Theme saqlanadi.
  static Future<void> clearAuthData() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _balanceHistoryViewedAtKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  static Future<void> saveThemeId(String id) async {
    await _storage.write(key: _themeIdKey, value: id);
  }

  static Future<String?> getThemeId() async {
    return await _storage.read(key: _themeIdKey);
  }

  static Future<void> saveDarkMode(bool value) async {
    await _storage.write(key: _darkModeKey, value: value.toString());
  }

  static Future<bool> getDarkMode() async {
    final v = await _storage.read(key: _darkModeKey);
    return v == 'true';
  }

  /// Hisob tarixi oxirgi ko'rilgan vaqti (yangi xabar badge uchun)
  static Future<void> saveBalanceHistoryViewedAt(String iso8601) async {
    await _storage.write(key: _balanceHistoryViewedAtKey, value: iso8601);
  }

  static Future<String?> getBalanceHistoryViewedAt() async {
    return await _storage.read(key: _balanceHistoryViewedAtKey);
  }

  static Future<void> saveBalanceTopupEnabled(bool value) async {
    await _storage.write(key: _balanceTopupEnabledKey, value: value.toString());
  }

  static Future<bool> getBalanceTopupEnabled() async {
    final v = await _storage.read(key: _balanceTopupEnabledKey);
    return v != 'false';
  }
}
