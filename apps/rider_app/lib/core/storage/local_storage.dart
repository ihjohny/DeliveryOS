import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyRiderProfile = 'rider_profile_data';
  static const String _keyIsOnline = 'rider_is_online';

  String? getAccessToken() => _prefs.getString(_keyAccessToken);
  Future<bool> setAccessToken(String token) => _prefs.setString(_keyAccessToken, token);

  String? getRefreshToken() => _prefs.getString(_keyRefreshToken);
  Future<bool> setRefreshToken(String token) => _prefs.setString(_keyRefreshToken, token);

  String? getRiderProfileJson() => _prefs.getString(_keyRiderProfile);
  Future<bool> setRiderProfileJson(String json) => _prefs.setString(_keyRiderProfile, json);

  bool getIsOnline() => _prefs.getBool(_keyIsOnline) ?? false;
  Future<bool> setIsOnline(bool online) => _prefs.setBool(_keyIsOnline, online);

  Future<void> clearAuth() async {
    await _prefs.remove(_keyAccessToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyRiderProfile);
    await _prefs.remove(_keyIsOnline);
  }
}

final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError('Initialize localStorageProvider in ProviderScope');
});
