import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_interval.dart';
import '../services/firestore_service.dart';

class ServiceIntervalNotifier extends Notifier<List<ServiceInterval>> {
  @override
  List<ServiceInterval> build() => [];

  // Fetch intervals for a specific motorcycle, initialize defaults if none exist
  Future<void> fetchIntervals(String motorcycleId, String type) async {
    final db = FirestoreService.instance;
    var intervals = await db.getServiceIntervalsByMotorcycle(motorcycleId);

    if (intervals.isEmpty) {
      final defaultIntervals = getDefaultIntervals(motorcycleId, type);
      for (var interval in defaultIntervals) {
        await db.insertServiceInterval(interval);
      }
      intervals = await db.getServiceIntervalsByMotorcycle(motorcycleId);
    }

    state = intervals;
  }

  Future<void> updateInterval(ServiceInterval interval) async {
    final db = FirestoreService.instance;
  }
}

final serviceIntervalProvider =
    NotifierProvider<ServiceIntervalNotifier, List<ServiceInterval>>(() {
      return ServiceIntervalNotifier();
    });
