import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/motorcycle.dart';
import '../models/service_record.dart';
import '../models/service_interval.dart';
import '../models/trip_record.dart';

class FirestoreService {
  // Singleton pattern
  static final FirestoreService instance = FirestoreService._internal();
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to access data');
    }
    return user.uid;
  }

  // --- MOTORCYCLES ---
  Future<List<Motorcycle>> getAllMotorcycles() async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('motorcycles')
        .where(
          'is_deleted',
          isNotEqualTo: true,
        ) // Filter agar yg dihapus tidak muncul
        .get();
    return snapshot.docs
        .map((doc) => Motorcycle.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<String> insertMotorcycle(Motorcycle motor) async {
    // Memastikan property is_deleted diset false saat dibuat
    var motorData = motor.toMap();
    motorData['is_deleted'] = false;

    final docRef = await _db
        .collection('users')
        .doc(_uid)
        .collection('motorcycles')
        .add(motorData);
    return docRef.id;
  }

  Future<void> updateMotorcycle(Motorcycle motor) async {
    if (motor.id != null) {
      await _db
          .collection('users')
          .doc(_uid)
          .collection('motorcycles')
          .doc(motor.id)
          .update(motor.toMap());
    }
  }

  // Merubah Delete asli menjadi Update Partial untuk Soft Delete
  Future<void> deleteMotorcycle(String id) async {
    if (id == '1' || id == '2')
      return; // Mencegah data dummy crash karena tidak ada di firestore
    await _db
        .collection('users')
        .doc(_uid)
        .collection('motorcycles')
        .doc(id)
        .update({'is_deleted': true});
  }

  // --- SERVICE RECORDS ---
  Future<List<ServiceRecord>> getServiceRecordsByMotorcycle(
    String motorcycleId,
  ) async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('service_records')
        .where('motorcycle_id', isEqualTo: motorcycleId)
        .get();
        
    final records = snapshot.docs
        .map((doc) => ServiceRecord.fromMap(doc.data(), id: doc.id))
        .toList();
        
    records.sort((a, b) {
      final dateA = a.createdAt ?? a.date;
      final dateB = b.createdAt ?? b.date;
      return dateB.compareTo(dateA);
    });
    
    return records;
  }

  Future<List<ServiceRecord>> getAllServiceRecords() async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('service_records')
        .get();
        
    final records = snapshot.docs
        .map((doc) => ServiceRecord.fromMap(doc.data(), id: doc.id))
        .toList();
        
    records.sort((a, b) {
      final dateA = a.createdAt ?? a.date;
      final dateB = b.createdAt ?? b.date;
      return dateB.compareTo(dateA); // descending
    });
    
    return records;
  }

  Future<String> insertServiceRecord(ServiceRecord record) async {
    final docRef = await _db
        .collection('users')
        .doc(_uid)
        .collection('service_records')
        .add(record.toMap());
    return docRef.id;
  }

  Future<void> updateServiceRecord(ServiceRecord record) async {
    if (record.id != null) {
      await _db
          .collection('users')
          .doc(_uid)
          .collection('service_records')
          .doc(record.id)
          .update(record.toMap());
    }
  }

  Future<void> deleteServiceRecord(String id) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('service_records')
        .doc(id)
        .delete();
  }

  // --- SERVICE INTERVALS ---
  Future<List<ServiceInterval>> getServiceIntervalsByMotorcycle(
    String motorcycleId,
  ) async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('service_intervals')
        .where('motorcycle_id', isEqualTo: motorcycleId)
        .get();
    return snapshot.docs
        .map((doc) => ServiceInterval.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<String> insertServiceInterval(ServiceInterval interval) async {
    final docRef = await _db
        .collection('users')
        .doc(_uid)
        .collection('service_intervals')
        .add(interval.toMap());
    return docRef.id;
  }

  Future<void> updateServiceInterval(ServiceInterval interval) async {
    if (interval.id != null) {
      await _db
          .collection('users')
          .doc(_uid)
          .collection('service_intervals')
          .doc(interval.id)
          .update(interval.toMap());
    }
  }

  Future<void> deleteServiceInterval(String id) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('service_intervals')
        .doc(id)
        .delete();
  }

  // --- TRIP RECORDS ---
  Future<String> insertTripRecord(TripRecord trip) async {
    final docRef = await _db
        .collection('users')
        .doc(_uid)
        .collection('trip_records')
        .add(trip.toMap());
    return docRef.id;
  }

  Future<List<TripRecord>> getTripRecordsByMotorcycle(
    String motorcycleId,
  ) async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('trip_records')
        .where('motorcycle_id', isEqualTo: motorcycleId)
        .orderBy('start_time', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => TripRecord.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<List<TripRecord>> getAllTripRecords() async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('trip_records')
        .orderBy('start_time', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => TripRecord.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<void> deleteTripRecord(String id) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('trip_records')
        .doc(id)
        .delete();
  }
}
