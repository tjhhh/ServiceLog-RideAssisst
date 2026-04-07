class ServiceInterval {
  final String? id;
  final String motorcycleId;
  final String serviceItem;
  final int intervalKm;

  ServiceInterval({
    this.id,
    required this.motorcycleId,
    required this.serviceItem,
    required this.intervalKm,
  });

  Map<String, dynamic> toMap() {
    return {
      'motorcycle_id': motorcycleId,
      'service_item': serviceItem,
      'interval_km': intervalKm,
    };
  }

  factory ServiceInterval.fromMap(Map<String, dynamic> map, {String? id}) {
    return ServiceInterval(
      id: id ?? map['id']?.toString(),
      motorcycleId: map['motorcycle_id'].toString(),
      serviceItem: map['service_item'] as String,
      intervalKm: map['interval_km'] as int,
    );
  }

  ServiceInterval copyWith({
    String? id,
    String? motorcycleId,
    String? serviceItem,
    int? intervalKm,
  }) {
    return ServiceInterval(
      id: id ?? this.id,
      motorcycleId: motorcycleId ?? this.motorcycleId,
      serviceItem: serviceItem ?? this.serviceItem,
      intervalKm: intervalKm ?? this.intervalKm,
    );
  }
}

List<ServiceInterval> getDefaultIntervals(String motorcycleId, String type) {
  switch (type.toLowerCase()) {
    case 'matic':
      return [
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Oli Mesin',
          intervalKm: 2000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Oli Gardan',
          intervalKm: 8000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Servis Ringan / Tune Up',
          intervalKm: 4000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Servis CVT',
          intervalKm: 8000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti V-Belt & Roller',
          intervalKm: 20000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Kampas Ganda & Mangkok',
          intervalKm: 24000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Busi',
          intervalKm: 8000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Filter Udara',
          intervalKm: 12000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Kampas Rem',
          intervalKm: 10000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Air Radiator',
          intervalKm: 10000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Minyak Rem',
          intervalKm: 20000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Oli Shockbreaker',
          intervalKm: 15000,
        ),
      ];
    case 'bebek':
      return [
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Oli Mesin',
          intervalKm: 2000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Servis Ringan / Tune Up',
          intervalKm: 4000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Stel & Lumasi Rantai',
          intervalKm: 500,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Gear Set',
          intervalKm: 15000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Busi',
          intervalKm: 8000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Filter Udara',
          intervalKm: 12000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Kampas Rem',
          intervalKm: 10000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Kampas Kopling',
          intervalKm: 15000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Minyak Rem',
          intervalKm: 20000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Oli Shockbreaker',
          intervalKm: 15000,
        ),
      ];
    case 'sport':
    default:
      return [
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Oli Mesin',
          intervalKm: 2000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Servis Ringan / Tune Up',
          intervalKm: 4000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Stel & Lumasi Rantai',
          intervalKm: 500,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Gear Set',
          intervalKm: 15000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Busi',
          intervalKm: 8000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Filter Udara',
          intervalKm: 12000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Kampas Rem',
          intervalKm: 10000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Kampas Kopling',
          intervalKm: 15000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Kabel Kopling / Gas',
          intervalKm: 10000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Air Radiator',
          intervalKm: 10000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Minyak Rem',
          intervalKm: 20000,
        ),
        ServiceInterval(
          motorcycleId: motorcycleId,
          serviceItem: 'Ganti Oli Shockbreaker',
          intervalKm: 15000,
        ),
      ];
  }
}
