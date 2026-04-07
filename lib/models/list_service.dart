class ListService {
  final String? id;
  final String typeMotorId;
  final String serviceName;
  final int minKm;
  final int maxKm;

  ListService({
    this.id,
    required this.typeMotorId,
    required this.serviceName,
    required this.minKm,
    required this.maxKm,
  });

  Map<String, dynamic> toMap() {
    return {
      'type_motor_id': typeMotorId,
      'service_name': serviceName,
      'min_km': minKm,
      'max_km': maxKm,
    };
  }

  factory ListService.fromMap(Map<String, dynamic> map, {String? id}) {
    return ListService(
      id: id ?? map['id']?.toString(),
      typeMotorId: map['type_motor_id'].toString(),
      serviceName: map['service_name'] as String,
      minKm: map['min_km'] as int,
      maxKm: map['max_km'] as int,
    );
  }
}
