import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AppPreferences {
  Future<int?> getInt(String key);
  Future<void> setInt(String key, int value);
}

class SharedPreferencesStore implements AppPreferences {
  SharedPreferencesStore([SharedPreferences? prefs]) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _instance() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<int?> getInt(String key) async => (await _instance()).getInt(key);

  @override
  Future<void> setInt(String key, int value) async {
    await (await _instance()).setInt(key, value);
  }
}

final preferencesStoreProvider = Provider<AppPreferences>(
  (ref) => SharedPreferencesStore(),
);
