import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  int? getInt(String key) => _prefs.getInt(key);

  Future<bool> remove(String key) => _prefs.remove(key);

  // User Role Helper
  Future<bool> saveUserRole(String role) => _prefs.setString(AppConstants.keyUserRole, role);
  String? getUserRole() => _prefs.getString(AppConstants.keyUserRole);

  // Onboarding Helper
  Future<bool> setOnboardingSeen() => _prefs.setBool(AppConstants.keyOnboardingSeen, true);
  bool hasSeenOnboarding() => _prefs.getBool(AppConstants.keyOnboardingSeen) ?? false;

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
