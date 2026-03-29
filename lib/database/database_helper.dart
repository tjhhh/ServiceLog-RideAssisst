import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/service_record.dart';
import '../models/motorcycle.dart';

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Table and column names
  static const String tableRecords = 'service_records';
  static const String tableMotorcycles = 'motorcycles';

  // Open connection or create the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ride_assist.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // Create tables safely
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE $tableRecords (
        id $idType,
        motorcycle_id $integerType DEFAULT 1,
        service_type $textType,
        mileage $integerType,
        location $textNullableType,
        date $textType,
        cost $realType,
        notes $textType,
        receipt_image_path $textNullableType
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableMotorcycles (
        id $idType,
        brand $textType,
        name $textType,
        image_url $textType,
        odometer $integerType,
        health_percentage $integerType,
        health_status $textType,
        next_service $textType
      )
    ''');

    // Insert Default Motorcycles
    for (var motor in defaultMotorcycles) {
      await db.insert(tableMotorcycles, motor.toMap());
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      const integerType = 'INTEGER NOT NULL';

      await db.execute(
        'ALTER TABLE $tableRecords ADD COLUMN motorcycle_id INTEGER DEFAULT 1',
      );
      await db.execute('''
        CREATE TABLE $tableMotorcycles (
          id $idType,
          brand $textType,
          name $textType,
          image_url $textType,
          odometer $integerType,
          health_percentage $integerType,
          health_status $textType,
          next_service $textType
        )
      ''');

      for (var motor in defaultMotorcycles) {
        await db.insert(tableMotorcycles, motor.toMap());
      }
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE $tableRecords ADD COLUMN location TEXT');
    }
  }

  // --- CRUD Operations ---

  // Insert a new record
  Future<int> insertRecord(ServiceRecord record) async {
    final db = await instance.database;
    return await db.insert(
      tableRecords,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read all records (sorted by date descending)
  Future<List<ServiceRecord>> getAllRecords() async {
    final db = await instance.database;
    final result = await db.query(tableRecords, orderBy: 'date DESC');

    return result.map((json) => ServiceRecord.fromMap(json)).toList();
  }

  // Update a record
  Future<int> updateRecord(ServiceRecord record) async {
    final db = await instance.database;
    return db.update(
      tableRecords,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  // Delete a record
  Future<int> deleteRecord(int id) async {
    final db = await instance.database;
    return await db.delete(tableRecords, where: 'id = ?', whereArgs: [id]);
  }

  // --- Motorcycle CRUD ---

  Future<List<Motorcycle>> getAllMotorcycles() async {
    final db = await instance.database;
    final result = await db.query(tableMotorcycles, orderBy: 'id ASC');
    return result.map((json) => Motorcycle.fromMap(json)).toList();
  }

  Future<int> insertMotorcycle(Motorcycle motor) async {
    final db = await instance.database;
    return await db.insert(
      tableMotorcycles,
      motor.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateMotorcycle(Motorcycle motor) async {
    final db = await instance.database;
    return db.update(
      tableMotorcycles,
      motor.toMap(),
      where: 'id = ?',
      whereArgs: [motor.id],
    );
  }

  // Close the database safely
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
