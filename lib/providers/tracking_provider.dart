import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/trip_record.dart';
import '../services/firestore_service.dart';
import '../services/app_logger.dart';

// ─── Constants ───────────────────────────────────────────────────────────────
const double _kMinDistanceMeters = 5.0; // ignore update < 5 m
const double _kMaxSpeedKmh = 120.0; // ignore speed > 120 km/h
const double _kIdleSpeedKmh = 2.0; // below this → idle candidate
const double _kIdleThresholdSec = 5.0; // idle confirmed after 5 s

// ─── Enums ───────────────────────────────────────────────────────────────────
enum TrackingStatus { idle, moving }

// ─── State ───────────────────────────────────────────────────────────────────
class TrackingState {
  final bool isTracking;
  final double trackedDistanceMeters;
  final String? activeMotorId;
  final TrackingStatus status;
  final double currentSpeedKmh;
  final Duration elapsed;
  final DateTime? startTime;

  const TrackingState({
    this.isTracking = false,
    this.trackedDistanceMeters = 0.0,
    this.activeMotorId,
    this.status = TrackingStatus.idle,
    this.currentSpeedKmh = 0.0,
    this.elapsed = Duration.zero,
    this.startTime,
  });

  TrackingState copyWith({
    bool? isTracking,
    double? trackedDistanceMeters,
    String? activeMotorId,
    TrackingStatus? status,
    double? currentSpeedKmh,
    Duration? elapsed,
    DateTime? startTime,
  }) {
    return TrackingState(
      isTracking: isTracking ?? this.isTracking,
      trackedDistanceMeters:
          trackedDistanceMeters ?? this.trackedDistanceMeters,
      activeMotorId: activeMotorId ?? this.activeMotorId,
      status: status ?? this.status,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      elapsed: elapsed ?? this.elapsed,
      startTime: startTime ?? this.startTime,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────
class TrackingNotifier extends Notifier<TrackingState> {
  StreamSubscription<Position>? _positionSub;
  Timer? _durationTimer;

  Position? _lastPosition;
  DateTime? _lastPositionTime;
  double _idleAccumSec = 0.0;

  @override
  TrackingState build() => const TrackingState();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns an error string on failure, null on success.
  Future<String?> startTracking(String motorId) async {
    try {
      // ── Permission checks ──
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Mohon nyalakan GPS (Lokasi) di pengaturan HP kamu terlebih dahulu.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Izin akses lokasi ditolak. Harap izinkan akses lokasi untuk menggunakan fitur ini.';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return 'Izin akses lokasi diblokir permanen. Harap buka pengaturan aplikasi dan izinkan manual.';
      }

      // ── Build LocationSettings ──
      final locationSettings = _buildLocationSettings();

      // ── Reset state before listening ──
      _lastPosition = null;
      _lastPositionTime = null;
      _idleAccumSec = 0.0;

      final now = DateTime.now();
      state = TrackingState(
        isTracking: true,
        activeMotorId: motorId,
        trackedDistanceMeters: 0.0,
        status: TrackingStatus.idle,
        currentSpeedKmh: 0.0,
        elapsed: Duration.zero,
        startTime: now,
      );

      // ── Start duration ticker (every 1 s) ──
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (state.isTracking && state.startTime != null) {
          state = state.copyWith(
            elapsed: DateTime.now().difference(state.startTime!),
          );
        }
      });

      // ── Start GPS stream ──
      AppLogger.instance.i('Starting GPS stream for motor $motorId');
      _positionSub = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(_onLocationUpdate);

      return null; // success
    } catch (e) {
      AppLogger.instance.e('startTracking error: $e');
      return 'Terjadi kesalahan sistem saat mengakses GPS: $e';
    }
  }

  /// Stops tracking, persists the trip, and returns the saved TripRecord.
  Future<TripRecord?> stopTracking() async {
    _positionSub?.cancel();
    _positionSub = null;
    _durationTimer?.cancel();
    _durationTimer = null;

    // ── Capture all values BEFORE resetting state ──
    final endTime = DateTime.now();
    final startTime = state.startTime;
    final totalDistance = state.trackedDistanceMeters;
    final durationSeconds = state.elapsed.inSeconds;
    final activeMotorId = state.activeMotorId; // ← capture sebelum reset

    // ── Full state reset (termasuk trackedDistanceMeters = 0) ──
    state = const TrackingState();

    _lastPosition = null;
    _lastPositionTime = null;
    _idleAccumSec = 0.0;

    // ── Save trip only if there is meaningful data ──
    if (startTime != null &&
        totalDistance >= _kMinDistanceMeters &&
        durationSeconds > 0 &&
        activeMotorId != null) {
      // ← pakai nilai yang sudah di-capture
      final avgSpeedKmh = (totalDistance / 1000) / (durationSeconds / 3600);

      final trip = TripRecord(
        motorcycleId: activeMotorId, // ← aman, tidak bergantung pada state
        startTime: startTime,
        endTime: endTime,
        totalDistanceMeters: totalDistance,
        durationSeconds: durationSeconds,
        avgSpeedKmh: avgSpeedKmh,
      );

      try {
        final id = await FirestoreService.instance.insertTripRecord(trip);
        return trip.copyWith(id: id);
      } catch (e) {
        AppLogger.instance.e('stopTracking save error: $e');
      }
    }

    return null;
  }

  void resetDistance() {
    state = state.copyWith(trackedDistanceMeters: 0.0);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  LocationSettings _buildLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 2),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
              'RideAssist sedang melacak perjalanan kamu untuk update Odometer.',
          notificationTitle: 'Auto Track Aktif',
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 3,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );
  }

  void _onLocationUpdate(Position position) {
    if (!state.isTracking) return;

    // Filter A: GPS Accuracy
    // Skip updates with very poor accuracy (> 35 meters)
    if (position.accuracy > 35) {
      AppLogger.instance.w(
        'Skip poor accuracy (${position.accuracy.toStringAsFixed(1)}m)',
      );
      return;
    }

    if (_lastPosition == null) {
      _lastPosition = position;
      _lastPositionTime = DateTime.now();
      AppLogger.instance.i(
        'GPS Initialized: ${position.latitude}, ${position.longitude}',
      );
      return;
    }

    AppLogger.instance.i(
      'GPS Update Recv -> lat: ${position.latitude.toStringAsFixed(5)}, lng: ${position.longitude.toStringAsFixed(5)}, acc: ${position.accuracy.toStringAsFixed(1)}m, spd: ${position.speed.toStringAsFixed(1)}m/s',
    );

    final now = DateTime.now();
    final deltaTimeSec =
        now.difference(_lastPositionTime!).inMilliseconds / 1000.0;

    if (deltaTimeSec <= 0.01)
      return; // Prevent division by zero or extremely fast updates

    // ── Haversine distance ──
    final distanceMeters = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    AppLogger.instance.i(
      'Dist: ${distanceMeters.toStringAsFixed(1)}m, dTime: ${deltaTimeSec.toStringAsFixed(1)}s',
    );

    // Filter B: Minimum Distance
    // If movement is less than 5m, wait for more updates to accumulate distance
    if (distanceMeters < _kMinDistanceMeters) {
      return;
    }

    // ── Speed calculation ──
    final double calculatedSpeedKmh = (distanceMeters / deltaTimeSec) * 3.6;

    // Robust speed logic:
    // Some devices report speed as 0.0 even when moving.
    // If calculated speed is significant (> 5 km/h) but GPS speed is <= 0,
    // we prefer the calculated speed.
    double speedKmh;
    if (position.speed > 0.5) {
      // 0.5 m/s ≈ 1.8 km/h
      speedKmh = position.speed * 3.6;

      // If GPS reported speed is much lower than calculated movement, trust movement
      if (speedKmh < _kIdleSpeedKmh && calculatedSpeedKmh > 10.0) {
        speedKmh = calculatedSpeedKmh;
      }
    } else {
      speedKmh = calculatedSpeedKmh;
    }

    // Filter C: Unrealistic speed (teleportation/glitch)
    if (speedKmh > _kMaxSpeedKmh) {
      AppLogger.instance.w(
        'Skip unrealistic speed (${speedKmh.toStringAsFixed(1)} km/h)',
      );
      return;
    }

    // Filter D: Idle detection
    if (speedKmh < _kIdleSpeedKmh) {
      _idleAccumSec += deltaTimeSec;

      // Update status to idle after threshold
      if (_idleAccumSec >= _kIdleThresholdSec &&
          state.status != TrackingStatus.idle) {
        state = state.copyWith(
          status: TrackingStatus.idle,
          currentSpeedKmh: speedKmh,
        );
        AppLogger.instance.i(
          'Tracking Status changed to IDLE. Speed: ${speedKmh.toStringAsFixed(1)}km/h',
        );
      }
      // When idle, we update reference position to avoid a "jump" when moving again,
      // but we don't accumulate the jitter distance.
      _lastPosition = position;
      _lastPositionTime = now;
      return;
    }

    // Valid movement detected
    _idleAccumSec = 0.0;

    // ── Accumulate valid distance ──
    state = state.copyWith(
      trackedDistanceMeters: state.trackedDistanceMeters + distanceMeters,
      status: TrackingStatus.moving,
      currentSpeedKmh: speedKmh,
    );

    AppLogger.instance.i(
      'Tracking: +${distanceMeters.toStringAsFixed(1)}m | Total: ${state.trackedDistanceMeters.toStringAsFixed(1)}m | Speed: ${speedKmh.toStringAsFixed(1)}km/h',
    );

    _lastPosition = position;
    _lastPositionTime = now;
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final trackingProvider = NotifierProvider<TrackingNotifier, TrackingState>(
  () => TrackingNotifier(),
);
