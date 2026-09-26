import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _keyToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyLanguage = 'selected_language';
  static const String _keyIsGuest = 'is_guest_mode';
  static const String _keyUser = 'cached_user_profile';
  static const String _keySavedLocation = 'saved_delivery_location';

  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  static Future<LocalStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorage(prefs);
  }

  String? getAccessToken() => _prefs.getString(_keyToken);
  Future<bool> setAccessToken(String token) => _prefs.setString(_keyToken, token);
  Future<bool> removeAccessToken() => _prefs.remove(_keyToken);

  String? getRefreshToken() => _prefs.getString(_keyRefreshToken);
  Future<bool> setRefreshToken(String token) => _prefs.setString(_keyRefreshToken, token);

  String getLanguage() => _prefs.getString(_keyLanguage) ?? 'en';
  Future<bool> setLanguage(String langCode) => _prefs.setString(_keyLanguage, langCode);

  bool isGuest() => _prefs.getBool(_keyIsGuest) ?? false;
  Future<bool> setGuest(bool isGuest) => _prefs.setBool(_keyIsGuest, isGuest);

  Map<String, dynamic>? getUserProfile() {
    final str = _prefs.getString(_keyUser);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> setUserProfile(Map<String, dynamic> user) =>
      _prefs.setString(_keyUser, jsonEncode(user));

  Map<String, dynamic>? getSavedLocation() {
    final str = _prefs.getString(_keySavedLocation);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> setSavedLocation(Map<String, dynamic> location) =>
      _prefs.setString(_keySavedLocation, jsonEncode(location));

  Future<void> clearSession() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyUser);
    await _prefs.setBool(_keyIsGuest, false);
  }
}
