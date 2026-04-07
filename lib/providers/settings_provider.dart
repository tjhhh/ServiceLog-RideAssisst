import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

class SettingsState {
  final int serviceInterval;
  final int themeColorValue;

  SettingsState({
    required this.serviceInterval,
    required this.themeColorValue,
  });

  SettingsState copyWith({
    int? serviceInterval,
    int? themeColorValue,
  }) {
    return SettingsState(
      serviceInterval: serviceInterval ?? this.serviceInterval,
      themeColorValue: themeColorValue ?? this.themeColorValue,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    // Jalankan pemuatan data secara asinkron
    _loadSettings();
    // Kembalikan nilai bawaan terlebih dahulu
    return SettingsState(serviceInterval: 2000, themeColorValue: 0xFF0052CC);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final interval = prefs.getInt('serviceInterval') ?? 2000;
    final colorVal = prefs.getInt('themeColor') ?? 0xFF0052CC;
    state = state.copyWith(serviceInterval: interval, themeColorValue: colorVal);
  }

  Future<void> updateServiceInterval(int newInterval) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('serviceInterval', newInterval);
    state = state.copyWith(serviceInterval: newInterval);
  }

  Future<void> updateThemeColor(int newColorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeColor', newColorValue);
    state = state.copyWith(themeColorValue: newColorValue);
  }
}
