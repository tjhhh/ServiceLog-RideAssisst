class ServiceRecord {
  final int? id;
  final int? motorcycleId; // Menyambungkan servis dengan motor spesifik
  final String serviceType;
  final int mileage;
  final String? location; // Menambahkan lokasi servis
  final DateTime date;
  final double cost;
  final String notes;
  final String? receiptImagePath;

  ServiceRecord({
    this.id,
    this.motorcycleId = 1, // Default ke 1 untuk retro-compatibility aplikasi
    required this.serviceType,
    required this.mileage,
    this.location,
    required this.date,
    required this.cost,
    required this.notes,
    this.receiptImagePath,
  });

  // Convert a ServiceRecord into a Map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'motorcycle_id': motorcycleId,
      'service_type': serviceType,
      'mileage': mileage,
      'location': location,
      'date': date.toIso8601String(),
      'cost': cost,
      'notes': notes,
      'receipt_image_path': receiptImagePath,
    };
  }

  // Extract a ServiceRecord object from a SQLite Map
  factory ServiceRecord.fromMap(Map<String, dynamic> map) {
    return ServiceRecord(
      id: map['id'] as int?,
      motorcycleId: map['motorcycle_id'] as int? ?? 1,
      serviceType: map['service_type'] as String,
      mileage: map['mileage'] as int,
      location: map['location'] as String?,
      date: DateTime.parse(map['date'] as String),
      cost: map['cost'] as double,
      notes: map['notes'] as String,
      receiptImagePath: map['receipt_image_path'] as String?,
    );
  }

  // Create a copy of the record with modified fields (useful for updates)
  ServiceRecord copyWith({
    int? id,
    int? motorcycleId,
    String? serviceType,
    int? mileage,
    DateTime? date,
    double? cost,
    String? notes,
    String? receiptImagePath,
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
    );
  }
}
