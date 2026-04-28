import 'package:cloud_firestore/cloud_firestore.dart';

class TripRecord {
  final String? id;
  final String motorcycleId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalDistanceMeters;
  final int durationSeconds;
  final double avgSpeedKmh;

  TripRecord({
    this.id,
    required this.motorcycleId,
    required this.startTime,
    required this.endTime,
    required this.totalDistanceMeters,
    required this.durationSeconds,
    required this.avgSpeedKmh,
  });

  double get totalDistanceKm => totalDistanceMeters / 1000;

  Map<String, dynamic> toMap() {
    return {
      'motorcycle_id': motorcycleId,
      'start_time': Timestamp.fromDate(startTime),
      'end_time': Timestamp.fromDate(endTime),
      'total_distance_meters': totalDistanceMeters,
      'duration_seconds': durationSeconds,
      'avg_speed_kmh': avgSpeedKmh,
    };
  }

  factory TripRecord.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return TripRecord(
      id: id ?? map['id']?.toString(),
      motorcycleId: map['motorcycle_id'] as String? ?? '',
      startTime: parseTimestamp(map['start_time']),
      endTime: parseTimestamp(map['end_time']),
      totalDistanceMeters:
          (map['total_distance_meters'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      avgSpeedKmh: (map['avg_speed_kmh'] as num?)?.toDouble() ?? 0.0,
    );
  }

  TripRecord copyWith({
    String? id,
    String? motorcycleId,
    DateTime? startTime,
    DateTime? endTime,
    double? totalDistanceMeters,
    int? durationSeconds,
    double? avgSpeedKmh,
  }) {
    return TripRecord(
      id: id ?? this.id,
      motorcycleId: motorcycleId ?? this.motorcycleId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
    );
  }
}
