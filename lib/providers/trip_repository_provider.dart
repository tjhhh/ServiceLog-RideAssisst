import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_record.dart';
import '../services/firestore_service.dart';

abstract class TripRepository {
  Future<String> insertTripRecord(TripRecord trip);
}

class FirestoreTripRepository implements TripRepository {
  @override
  Future<String> insertTripRecord(TripRecord trip) {
    return FirestoreService.instance.insertTripRecord(trip);
  }
}

final tripRepositoryProvider = Provider<TripRepository>(
  (ref) => FirestoreTripRepository(),
);
