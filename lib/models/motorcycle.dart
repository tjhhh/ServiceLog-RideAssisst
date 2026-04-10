class Motorcycle {
  final String? id;
  final String brand;
  final String name;
  final String type; // matic, bebek, sport
  final String? licensePlate; // Plat Nomor
  final int? year; // Tahun Motor
  final String imageUrl;
  final int odometer;
  final int healthPercentage;
  final String healthStatus;
  final String nextService;
  final bool isDeleted; // Tambahan untuk fitur soft delete
  final int cycle;

  Motorcycle({
    this.id,
    required this.brand,
    required this.name,
    this.type = 'matic', // Default type
    this.licensePlate,
    this.year,
    required this.imageUrl,
    required this.odometer,
    required this.healthPercentage,
    required this.healthStatus,
    required this.nextService,
    this.isDeleted = false, // Set bawaan false
    this.cycle = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand': brand,
      'name': name,
      'type': type,
      'license_plate': licensePlate,
      'year': year,
      'image_url': imageUrl,
      'odometer': odometer,
      'health_percentage': healthPercentage,
      'health_status': healthStatus,
      'next_service': nextService,
      'is_deleted': isDeleted,
      'cycle': cycle,
    };
  }

  factory Motorcycle.fromMap(Map<String, dynamic> map, {String? id}) {
    return Motorcycle(
      id: id ?? map['id']?.toString(),
      brand: map['brand'] as String,
      name: map['name'] as String,
      type: map['type'] as String? ?? 'matic',
      licensePlate: map['license_plate'] as String?,
      year: map['year'] as int?,
      imageUrl: map['image_url'] as String,
      odometer: map['odometer'] as int,
      healthPercentage: map['health_percentage'] as int,
      healthStatus: map['health_status'] as String,
      nextService: map['next_service'] as String,
      isDeleted: map['is_deleted'] as bool? ?? false,
      cycle: map['cycle'] as int? ?? 0,
    );
  }

  Motorcycle copyWith({
    String? id,
    String? brand,
    String? name,
    String? type,
    String? licensePlate,
    int? year,
    String? imageUrl,
    int? odometer,
    int? healthPercentage,
    String? healthStatus,
    String? nextService,
    bool? isDeleted,
    int? cycle,
  }) {
    return Motorcycle(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      name: name ?? this.name,
      type: type ?? this.type,
      licensePlate: licensePlate ?? this.licensePlate,
      year: year ?? this.year,
      imageUrl: imageUrl ?? this.imageUrl,
      odometer: odometer ?? this.odometer,
      healthPercentage: healthPercentage ?? this.healthPercentage,
      healthStatus: healthStatus ?? this.healthStatus,
      nextService: nextService ?? this.nextService,
      isDeleted: isDeleted ?? this.isDeleted,
      cycle: cycle ?? this.cycle,
    );
  }
} // End MotorCycle class

// Data Dummy untuk UI awal/Insert Database
final List<Motorcycle> defaultMotorcycles = [
  Motorcycle(
    id: '1',
    brand: 'BMW R nineT',
    name: 'Midnight Shadow',
    type: 'sport',
    imageUrl:
        'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?q=80&w=800&auto=format&fit=crop',
    odometer: 24560,
    healthPercentage: 75,
    healthStatus: 'OPTIMAL',
    nextService: 'Change Engine Oil',
  ),
  Motorcycle(
    id: '2',
    brand: 'Ducati Scrambler',
    name: 'Desert Sled',
    type: 'sport',
    imageUrl:
        'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?q=80&w=800&auto=format&fit=crop',
    odometer: 12400,
    healthPercentage: 90,
    healthStatus: 'EXCELLENT',
    nextService: 'Chain Lube',
  ),
];
