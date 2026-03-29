class Motorcycle {
  final int? id;
  final String brand;
  final String name;
  final String imageUrl;
  final int odometer;
  final int healthPercentage;
  final String healthStatus;
  final String nextService;

  Motorcycle({
    this.id,
    required this.brand,
    required this.name,
    required this.imageUrl,
    required this.odometer,
    required this.healthPercentage,
    required this.healthStatus,
    required this.nextService,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand': brand,
      'name': name,
      'image_url': imageUrl,
      'odometer': odometer,
      'health_percentage': healthPercentage,
      'health_status': healthStatus,
      'next_service': nextService,
    };
  }

  factory Motorcycle.fromMap(Map<String, dynamic> map) {
    return Motorcycle(
      id: map['id'] as int?,
      brand: map['brand'] as String,
      name: map['name'] as String,
      imageUrl: map['image_url'] as String,
      odometer: map['odometer'] as int,
      healthPercentage: map['health_percentage'] as int,
      healthStatus: map['health_status'] as String,
      nextService: map['next_service'] as String,
    );
  }

  Motorcycle copyWith({
    int? id,
    String? brand,
    String? name,
    String? imageUrl,
    int? odometer,
    int? healthPercentage,
    String? healthStatus,
    String? nextService,
  }) {
    return Motorcycle(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      odometer: odometer ?? this.odometer,
      healthPercentage: healthPercentage ?? this.healthPercentage,
      healthStatus: healthStatus ?? this.healthStatus,
      nextService: nextService ?? this.nextService,
    );
  }
}

// Data Dummy untuk UI awal/Insert Database
final List<Motorcycle> defaultMotorcycles = [
  Motorcycle(
    id: 1,
    brand: 'BMW R nineT',
    name: 'Midnight Shadow',
    imageUrl:
        'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?q=80&w=800&auto=format&fit=crop',
    odometer: 24560,
    healthPercentage: 75,
    healthStatus: 'OPTIMAL',
    nextService: 'Change Engine Oil',
  ),
  Motorcycle(
    id: 2,
    brand: 'Ducati Scrambler',
    name: 'Desert Sled',
    imageUrl:
        'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?q=80&w=800&auto=format&fit=crop',
    odometer: 12400,
    healthPercentage: 90,
    healthStatus: 'EXCELLENT',
    nextService: 'Chain Lube',
  ),
];
