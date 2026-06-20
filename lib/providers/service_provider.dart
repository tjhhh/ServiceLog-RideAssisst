import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/service_record.dart';
import 'motorcycle_provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_repository.dart';

// Di Riverpod terbaru, `Notifier` disarankan alih-alih `StateNotifier`
final serviceRecordsProvider =
    NotifierProvider<ServiceNotifier, List<ServiceRecord>>(() {
      return ServiceNotifier();
    });

class ServiceNotifier extends Notifier<List<ServiceRecord>> {
  String? get _currentUserId => ref.read(authUserIdProvider);
  FirestoreRepository get _db => ref.read(firestoreRepositoryProvider);

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
    final expectedUid = userId ?? _currentUserId;
    if (expectedUid == null) {
      state = [];
      return;
    }

    try {
      final records = await _db.getAllServiceRecords();
      if (_currentUserId != expectedUid) {
        return;
      }

      state = records;
    } catch (e) {
      if (_currentUserId != expectedUid) {
        return;
      }

      debugPrint('Error loading service records: $e');
      // If error, set empty
      state = [];
    }
  }

  // Menambahkan record baru
  Future<void> addRecord(ServiceRecord record) async {
    final dbHelper = _db;
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
    await _db.updateServiceRecord(record);
    await _loadRecords();
  }

  // Menghapus record
  Future<void> deleteRecord(String id) async {
    await _db.deleteServiceRecord(id);
    await _loadRecords();
  }
}
