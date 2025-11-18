import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      throw Exception(
        'Failed to initialize SharedPreferences. '
        'Please ensure the app is fully rebuilt (not just hot reloaded). '
        'Error: $e',
      );
    }
  }

  // Ensure StorageService is initialized
  Future<void> ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
  }

  // String Operations
  Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  // Int Operations
  Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  // Bool Operations
  Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  // Double Operations
  Future<bool> setDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }

  double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }

  // List Operations
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs?.setStringList(key, value) ?? false;
  }

  List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }

  // Remove Operations
  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }

  // Check if key exists
  bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }

  // Get all keys
  Set<String> getKeys() {
    return _prefs?.getKeys() ?? <String>{};
  }
}
