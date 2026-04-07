import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_record.dart';
import '../services/firestore_service.dart';
import 'motorcycle_provider.dart';

// Di Riverpod terbaru, `Notifier` disarankan alih-alih `StateNotifier`
final serviceRecordsProvider =
    NotifierProvider<ServiceNotifier, List<ServiceRecord>>(() {
      return ServiceNotifier();
    });

class ServiceNotifier extends Notifier<List<ServiceRecord>> {
  @override
  List<ServiceRecord> build() {
    _loadRecords();
    return [];
  }

  // Memuat data dari Firebase Firestore
  Future<void> _loadRecords() async {
    try {
      final records = await FirestoreService.instance.getAllServiceRecords();
      state = records;
    } catch (e) {
      print('Error loading service records: $e');
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
