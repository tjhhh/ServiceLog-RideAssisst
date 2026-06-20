import 'package:geolocator/geolocator.dart';

class LocationSample {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double speedMetersPerSecond;
  final DateTime timestamp;

  const LocationSample({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.speedMetersPerSecond,
    required this.timestamp,
  });
}

abstract class LocationService {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Stream<LocationSample> getPositionStream({
    required LocationSettings locationSettings,
  });
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  );
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  @override
  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }

  @override
  Stream<LocationSample> getPositionStream({
    required LocationSettings locationSettings,
  }) {
    return Geolocator.getPositionStream(locationSettings: locationSettings).map(
      (position) => LocationSample(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        speedMetersPerSecond: position.speed,
        timestamp: position.timestamp,
      ),
    );
  }

  @override
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
