import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

class SettingsState {
  final int serviceInterval;

  SettingsState({required this.serviceInterval});

  SettingsState copyWith({int? serviceInterval}) {
    return SettingsState(
      serviceInterval: serviceInterval ?? this.serviceInterval,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    // Jalankan pemuatan data secara asinkron
    _loadSettings();
    // Kembalikan nilai bawaan terlebih dahulu
    return SettingsState(serviceInterval: 2000);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final interval = prefs.getInt('serviceInterval') ?? 2000;
    state = state.copyWith(serviceInterval: interval);
  }

  Future<void> updateServiceInterval(int newInterval) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('serviceInterval', newInterval);
    state = state.copyWith(serviceInterval: newInterval);
  }
}
