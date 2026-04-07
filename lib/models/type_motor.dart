class TypeMotor {
  final String? id;
  final String name;

  TypeMotor({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'name': name};
  }

  factory TypeMotor.fromMap(Map<String, dynamic> map, {String? id}) {
    return TypeMotor(
      id: id ?? map['id']?.toString(),
      name: map['name'] as String,
    );
  }
}
