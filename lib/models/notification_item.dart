enum NotificationType { Warning, Critical, OdometerLimit }

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final NotificationType type;
  final String motorcycleId;
  final String motorcycleName;
  final DateTime date;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.motorcycleId,
    required this.motorcycleName,
    DateTime? date,
  }) : date = date ?? DateTime.now();
}
