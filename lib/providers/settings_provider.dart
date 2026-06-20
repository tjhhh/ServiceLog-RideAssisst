import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/preferences_store.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

class SettingsState {
  final int serviceInterval;
  final int themeColorValue;

  SettingsState({required this.serviceInterval, required this.themeColorValue});

  SettingsState copyWith({int? serviceInterval, int? themeColorValue}) {
    return SettingsState(
      serviceInterval: serviceInterval ?? this.serviceInterval,
      themeColorValue: themeColorValue ?? this.themeColorValue,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  int _loadRevision = 0;

  @override
  SettingsState build() {
    final revision = ++_loadRevision;
    _loadSettings(revision);
    return SettingsState(serviceInterval: 2000, themeColorValue: 0xFF0052CC);
  }

  Future<void> _loadSettings(int revision) async {
    final prefs = ref.read(preferencesStoreProvider);
    final interval = await prefs.getInt('serviceInterval') ?? 2000;
    final colorVal = await prefs.getInt('themeColor') ?? 0xFF0052CC;
    if (revision != _loadRevision) {
      return;
    }
    state = state.copyWith(
      serviceInterval: interval,
      themeColorValue: colorVal,
    );
  }

  Future<void> updateServiceInterval(int newInterval) async {
    final prefs = ref.read(preferencesStoreProvider);
    _loadRevision += 1;
    await prefs.setInt('serviceInterval', newInterval);
    state = state.copyWith(serviceInterval: newInterval);
  }

  Future<void> updateThemeColor(int newColorValue) async {
    final prefs = ref.read(preferencesStoreProvider);
    _loadRevision += 1;
    await prefs.setInt('themeColor', newColorValue);
    state = state.copyWith(themeColorValue: newColorValue);
  }
}
