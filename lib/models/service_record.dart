class ServiceRecord {
  final String? id;
  final String? motorcycleId; // Menyambungkan servis dengan motor spesifik
  final String serviceType;
  final int mileage;
  final String? location; // Menambahkan lokasi servis
  final DateTime date;
  final double cost;
  final String notes;
  final String? receiptImagePath;
  final DateTime? createdAt;

  ServiceRecord({
    this.id,
    this.motorcycleId,
    required this.serviceType,
    required this.mileage,
    this.location,
    required this.date,
    required this.cost,
    required this.notes,
    this.receiptImagePath,
    this.createdAt,
  });

  // Convert a ServiceRecord into a Map for SQLite/Firestore insertion
  Map<String, dynamic> toMap() {
    return {
      'motorcycle_id': motorcycleId,
      'service_type': serviceType,
      'mileage': mileage,
      'location': location,
      'date': date.toIso8601String(),
      'cost': cost,
      'notes': notes,
      'receipt_image_path': receiptImagePath,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  // Extract a ServiceRecord object from a Map
  factory ServiceRecord.fromMap(Map<String, dynamic> map, {String? id}) {
    return ServiceRecord(
      id: id ?? map['id']?.toString(),
      motorcycleId: map['motorcycle_id']?.toString(),
      serviceType: map['service_type'] as String,
      mileage: map['mileage'] as int,
      location: map['location'] as String?,
      date: DateTime.parse(map['date'] as String),
      cost: map['cost'] as double,
      notes: map['notes'] as String,
      receiptImagePath: map['receipt_image_path'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
    );
  }

  // Create a copy of the record with modified fields (useful for updates)
  ServiceRecord copyWith({
    String? id,
    String? motorcycleId,
    int? mileage,
    DateTime? date,
    double? cost,
    String? notes,
    String? receiptImagePath,
    DateTime? createdAt,
  }) {
    return ServiceRecord(
      id: id ?? this.id,
      motorcycleId: motorcycleId ?? this.motorcycleId,
      serviceType: serviceType ?? this.serviceType,
      mileage: mileage ?? this.mileage,
      date: date ?? this.date,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
