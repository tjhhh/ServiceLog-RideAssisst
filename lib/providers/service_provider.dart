import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/service_record.dart';
import '../services/firestore_service.dart';
import 'motorcycle_provider.dart';
import '../services/auth_service.dart';

// Di Riverpod terbaru, `Notifier` disarankan alih-alih `StateNotifier`
final serviceRecordsProvider =
    NotifierProvider<ServiceNotifier, List<ServiceRecord>>(() {
      return ServiceNotifier();
    });

class ServiceNotifier extends Notifier<List<ServiceRecord>> {
  final _auth = FirebaseAuth.instance;

  @override
  List<ServiceRecord> build() {
    final authState = ref.watch(authStateProvider);
    final user = authState.maybeWhen(data: (user) => user, orElse: () => null);

    if (user == null) {
      return [];
    }

    _loadRecords(user.uid);
    return [];
  }

  // Memuat data dari Firebase Firestore
  Future<void> _loadRecords([String? userId]) async {
    final expectedUid = userId ?? _auth.currentUser?.uid;
    if (expectedUid == null) {
      state = [];
      return;
    }

    try {
      final records = await FirestoreService.instance.getAllServiceRecords();
      if (_auth.currentUser?.uid != expectedUid) {
        return;
      }

      state = records;
    } catch (e) {
      if (_auth.currentUser?.uid != expectedUid) {
        return;
      }

      debugPrint('Error loading service records: $e');
      // If error, set empty
      state = [];
    }
  }

  // Menambahkan record baru
  Future<void> addRecord(ServiceRecord record) async {
    final dbHelper = FirestoreService.instance;
    await dbHelper.insertServiceRecord(record);

    if (record.motorcycleId != null) {
      final motors = await dbHelper.getAllMotorcycles();
      try {
        final motorToUpdate = motors.firstWhere(
          (m) => m.id == record.motorcycleId,
        );
        if (record.mileage > motorToUpdate.odometer) {
          await dbHelper.updateMotorcycle(
            motorToUpdate.copyWith(odometer: record.mileage),
          );
          // Beri tahu provider motor untuk memuat ulang data
          ref.read(motorcycleProvider.notifier).loadMotorcycles();
        }
      } catch (_) {
        // Motor tidak ditemukan, abaikan
      }
    }

    await _loadRecords(); // Refresh tampilan setelah menambahkan
  }

  // Memperbarui record
  Future<void> updateRecord(ServiceRecord record) async {
    await FirestoreService.instance.updateServiceRecord(record);
    await _loadRecords();
  }

  // Menghapus record
  Future<void> deleteRecord(String id) async {
    await FirestoreService.instance.deleteServiceRecord(id);
    await _loadRecords();
  }
}
