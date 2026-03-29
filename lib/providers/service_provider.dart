import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_record.dart';
import '../database/database_helper.dart';
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

  // Memuat data dari database SQLite
  Future<void> _loadRecords() async {
    final records = await DatabaseHelper.instance.getAllRecords();
    state = records;
  }

  // Menambahkan record baru
  Future<void> addRecord(ServiceRecord record) async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.insertRecord(record);

    // Update odometer motor jika data baru memiliki mileage lebih tinggi
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
    await DatabaseHelper.instance.updateRecord(record);
    await _loadRecords();
  }

  // Menghapus record
  Future<void> deleteRecord(int id) async {
    await DatabaseHelper.instance.deleteRecord(id);
    await _loadRecords();
  }
}
