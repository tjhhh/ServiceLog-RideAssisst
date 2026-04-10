import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_item.dart';
import '../models/service_interval.dart';
import 'motorcycle_provider.dart';
import 'service_provider.dart';

// Provides dynamic health alert notifications across all registered motorcycles
final notificationProvider = Provider<List<NotificationItem>>((ref) {
  final motorcycles = ref.watch(motorcycleProvider);
  final allRecords = ref.watch(serviceRecordsProvider);

  List<NotificationItem> notifications = [];

  for (final motor in motorcycles) {
    if (motor.id == null) continue;

    final motorName = '${motor.brand} ${motor.name}';
    final activeMotorRecords = allRecords.where((r) => r.motorcycleId == motor.id).toList();

    // 1. Odometer Check Layer
    if (motor.odometer >= 99888) {
      notifications.add(
        NotificationItem(
          id: 'odo_${motor.id}',
          title: 'Odometer Maksimal',
          description: 'Odometer untuk $motorName telah mencapai ${motor.odometer} KM. Segera reset odometer untuk merekam siklus Cycle terbaru!',
          type: NotificationType.OdometerLimit,
          motorcycleId: motor.id!,
          motorcycleName: motorName,
        )
      );
    }

    // 2. Service Intervals Check Layer
    final intervals = getDefaultIntervals(motor.id!, motor.type);
    
    for (var interval in intervals) {
      final relatedRecords = activeMotorRecords.where((r) =>
          r.serviceType.toLowerCase().contains(interval.serviceItem.toLowerCase()) ||
          interval.serviceItem.toLowerCase().contains(r.serviceType.toLowerCase())
      ).toList()..sort((a, b) => b.date.compareTo(a.date)); // descending date is generally safe, or mileage.

      int lastReplacedOdo = 0;
      int lastReplacedCycle = 0;

      if (relatedRecords.isNotEmpty) {
        lastReplacedOdo = relatedRecords.first.mileage;
        lastReplacedCycle = relatedRecords.first.cycle;
      }

      int activeFullOdo = (motor.cycle * 100000) + motor.odometer;
      int lastFullOdo = (lastReplacedCycle * 100000) + lastReplacedOdo;

      int kmSinceLastService = activeFullOdo - lastFullOdo;
      if (lastReplacedOdo == 0 && lastReplacedCycle == 0 && activeFullOdo > 0) {
        kmSinceLastService = activeFullOdo;
      }
      if (kmSinceLastService < 0) kmSinceLastService = 0;

      final bool isCritical = kmSinceLastService >= interval.intervalKm;
      final bool isWarning = kmSinceLastService >= (interval.intervalKm * 0.85);

      if (isCritical || isWarning) {
        notifications.add(
          NotificationItem(
            id: 'svc_${motor.id}_${interval.serviceItem}',
            title: isCritical ? 'Waktunya Servis!' : 'Perlu Perhatian',
            description: '${interval.serviceItem} di motor $motorName sudah jalan $kmSinceLastService KM (Batas: ${interval.intervalKm} KM).',
            type: isCritical ? NotificationType.Critical : NotificationType.Warning,
            motorcycleId: motor.id!,
            motorcycleName: motorName,
          )
        );
      }
    }
  }

  // Sorting
  // Critical and Odometer Limits on top
  notifications.sort((a, b) {
    int getSeverity(NotificationType t) {
      switch (t) {
        case NotificationType.OdometerLimit: return 3;
        case NotificationType.Critical: return 2;
        case NotificationType.Warning: return 1;
      }
    }
    return getSeverity(b.type).compareTo(getSeverity(a.type));
  });

  return notifications;
});
