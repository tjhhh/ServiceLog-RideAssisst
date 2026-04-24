import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
class TrackingState {
  final bool isTracking;
  final double trackedDistanceMeters; // in meters
  final String? activeMotorId;

  TrackingState({
    this.isTracking = false,
    this.trackedDistanceMeters = 0.0,
    this.activeMotorId,
  });

  TrackingState copyWith({
    bool? isTracking,
    double? trackedDistanceMeters,
    String? activeMotorId,
  }) {
    return TrackingState(
      isTracking: isTracking ?? this.isTracking,
      trackedDistanceMeters: trackedDistanceMeters ?? this.trackedDistanceMeters,
      activeMotorId: activeMotorId ?? this.activeMotorId,
    );
  }
}

class TrackingNotifier extends Notifier<TrackingState> {
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastPosition;

  @override
  TrackingState build() {
    return TrackingState();
  }

  Future<String?> startTracking(String motorId) async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Mohon nyalakan GPS (Lokasi) di pengaturan HP kamu terlebih dahulu.';
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Izin akses lokasi ditolak. Harap izinkan akses lokasi untuk menggunakan fitur ini.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return 'Izin akses lokasi diblokir permanen. Harap buka pengaturan aplikasi dan izinkan manual.';
      }

      // Set LocationSettings for background & foreground
      late LocationSettings locationSettings;

      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
          forceLocationManager: true,
          intervalDuration: const Duration(seconds: 5),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText:
                "RideAssist sedang melacak perjalanan kamu untuk update Odometer.",
            notificationTitle: "Auto Track Aktif",
            enableWakeLock: true,
          ),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.automotiveNavigation,
          distanceFilter: 3,
          pauseLocationUpdatesAutomatically: true,
          showBackgroundLocationIndicator: true,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        );
      }

    // Get an initial position
    _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    state = state.copyWith(
      isTracking: true,
      activeMotorId: motorId,
      trackedDistanceMeters: 0.0, // Reset distance
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings).listen(
      (Position position) {
        if (_lastPosition != null && state.isTracking) {
          final distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );

          // Update state with new distance
          state = state.copyWith(
            trackedDistanceMeters: state.trackedDistanceMeters + distance,
          );
        }
        _lastPosition = position;
      },
    );
    return null; // Success
  } catch (e) {
    print("Geolocator Error: $e");
    return 'Terjadi kesalahan sistem saat mengakses GPS: $e';
  }
}

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _lastPosition = null;

    state = state.copyWith(isTracking: false);
  }

  void resetDistance() {
    state = state.copyWith(trackedDistanceMeters: 0.0);
  }
}

final trackingProvider = NotifierProvider<TrackingNotifier, TrackingState>(
  () => TrackingNotifier(),
);
