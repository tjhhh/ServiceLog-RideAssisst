import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_record.dart';
import '../services/firestore_service.dart';

final tripProvider =
    NotifierProvider<TripNotifier, List<TripRecord>>(() => TripNotifier());

class TripNotifier extends Notifier<List<TripRecord>> {
  final _db = FirestoreService.instance;

  @override
  List<TripRecord> build() {
    loadAll();
    return [];
  }

  Future<void> loadAll() async {
    try {
      state = await _db.getAllTripRecords();
    } catch (e) {
      state = [];
    }
  }

  Future<void> loadByMotorcycle(String motorcycleId) async {
    try {
      state = await _db.getTripRecordsByMotorcycle(motorcycleId);
    } catch (e) {
      state = [];
    }
  }

  Future<String> addTrip(TripRecord trip) async {
    final id = await _db.insertTripRecord(trip);
    await loadAll();
    return id;
  }

  Future<void> deleteTrip(String id) async {
    await _db.deleteTripRecord(id);
    state = state.where((t) => t.id != id).toList();
  }
}
