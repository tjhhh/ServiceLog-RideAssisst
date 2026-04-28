import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/motorcycle.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

// Provider yang bisa dipanggil untuk mengambil/mengupdate list motor
final motorcycleProvider =
    NotifierProvider<MotorcycleNotifier, List<Motorcycle>>(
      () => MotorcycleNotifier(),
    );

class MotorcycleNotifier extends Notifier<List<Motorcycle>> {
  final dbService = FirestoreService.instance;
  final _auth = FirebaseAuth.instance;

  @override
  List<Motorcycle> build() {
    final authState = ref.watch(authStateProvider);
    final user = authState.maybeWhen(data: (user) => user, orElse: () => null);

    if (user == null) {
      return [];
    }

    loadMotorcycles(user.uid);
    return [];
  }

  Future<void> loadMotorcycles([String? userId]) async {
    final expectedUid = userId ?? _auth.currentUser?.uid;
    if (expectedUid == null) {
      state = [];
      return;
    }

    try {
      final motors = await dbService.getAllMotorcycles();
      if (_auth.currentUser?.uid != expectedUid) {
        return;
      }

      // JANGAN MERESET KE defaultMotorcycles JIKA KOSONG!
      // Kalau kita reset ke default, garasi tidak bisa menjadi kosong dan terkesan 'tidak bisa dihapus'.
      state = motors;
    } catch (e) {
      if (_auth.currentUser?.uid != expectedUid) {
        return;
      }

      debugPrint('Error loading motorcycles: $e');
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
