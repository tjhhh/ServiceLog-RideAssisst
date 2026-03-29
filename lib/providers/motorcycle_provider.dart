import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/motorcycle.dart';
import '../database/database_helper.dart';

// Provider yang bisa dipanggil untuk mengambil/mengupdate list motor
final motorcycleProvider =
    NotifierProvider<MotorcycleNotifier, List<Motorcycle>>(
      () => MotorcycleNotifier(),
    );

class MotorcycleNotifier extends Notifier<List<Motorcycle>> {
  final dbHelper = DatabaseHelper.instance;

  @override
  List<Motorcycle> build() {
    // Return empty list as initial state, then load data asynchronously
    loadMotorcycles();
    return [];
  }

  Future<void> loadMotorcycles() async {
    final motors = await dbHelper.getAllMotorcycles();
    state = motors.isEmpty ? defaultMotorcycles : motors;
  }

  Future<void> updateMotorcycle(Motorcycle motor) async {
    await dbHelper.updateMotorcycle(motor);
    await loadMotorcycles();
  }

  Future<void> addMotorcycle(Motorcycle motor) async {
    await dbHelper.insertMotorcycle(motor);
    await loadMotorcycles();
  }

  Future<void> deleteMotorcycle(int id) async {
    final db = await dbHelper.database;
    await db.delete('motorcycles', where: 'id = ?', whereArgs: [id]);
    await loadMotorcycles();
  }
}
