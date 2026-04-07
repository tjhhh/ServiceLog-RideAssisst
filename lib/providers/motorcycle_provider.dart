import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/motorcycle.dart';
import '../services/firestore_service.dart';

// Provider yang bisa dipanggil untuk mengambil/mengupdate list motor
final motorcycleProvider =
    NotifierProvider<MotorcycleNotifier, List<Motorcycle>>(
      () => MotorcycleNotifier(),
    );

class MotorcycleNotifier extends Notifier<List<Motorcycle>> {
  final dbService = FirestoreService.instance;

  @override
  List<Motorcycle> build() {
    // Return empty list as initial state, then load data asynchronously
    loadMotorcycles();
    return [];
  }

  Future<void> loadMotorcycles() async {
    try {
      final motors = await dbService.getAllMotorcycles();
      // JANGAN MERESET KE defaultMotorcycles JIKA KOSONG!
      // Kalau kita reset ke default, garasi tidak bisa menjadi kosong dan terkesan 'tidak bisa dihapus'.
      state = motors;
    } catch (e) {
      print('Error loading motorcycles: $e');
      state = [];
    }
  }

  Future<void> updateMotorcycle(Motorcycle motor) async {
    await dbService.updateMotorcycle(motor);
    await loadMotorcycles();
  }

  Future<void> addMotorcycle(Motorcycle motor) async {
    await dbService.insertMotorcycle(motor);
    await loadMotorcycles();
  }

  Future<void> deleteMotorcycle(String id) async {
    await dbService.deleteMotorcycle(id);
    await loadMotorcycles();
  }
}
