import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_record.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

final tripProvider = NotifierProvider<TripNotifier, List<TripRecord>>(
  () => TripNotifier(),
);

class TripNotifier extends Notifier<List<TripRecord>> {
  final _db = FirestoreService.instance;
  final _auth = FirebaseAuth.instance;

  @override
  List<TripRecord> build() {
    final authState = ref.watch(authStateProvider);
    final user = authState.maybeWhen(data: (user) => user, orElse: () => null);

    if (user == null) {
      return [];
    }

    loadAll(user.uid);
    return [];
  }

  Future<void> loadAll([String? userId]) async {
    final expectedUid = userId ?? _auth.currentUser?.uid;
    if (expectedUid == null) {
      state = [];
      return;
    }

    try {
      final records = await _db.getAllTripRecords();
      if (_auth.currentUser?.uid != expectedUid) {
        return;
      }

      state = records;
    } catch (e) {
      if (_auth.currentUser?.uid != expectedUid) {
        return;
      }

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
