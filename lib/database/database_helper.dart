import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/service_record.dart';
import '../models/motorcycle.dart';
import '../models/service_interval.dart';
import '../models/type_motor.dart';
import '../models/list_service.dart';

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Table and column names
  static const String tableRecords = 'service_records';
  static const String tableMotorcycles = 'motorcycles';
  static const String tableIntervals = 'service_intervals';
  static const String tableTypeMotor = 'type_motor';
  static const String tableListService = 'list_service';

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
      version: 6,
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
        type $textType DEFAULT 'matic',
        image_url $textType,
        odometer $integerType,
        health_percentage $integerType,
        health_status $textType,
        next_service $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableIntervals (
        id $idType,
        motorcycle_id $integerType,
        service_item $textType,
        interval_km $integerType
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableTypeMotor (
        id $idType,
        name $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableListService (
        id $idType,
        type_motor_id $integerType,
        service_name $textType,
        min_km $integerType,
        max_km $integerType,
        FOREIGN KEY (type_motor_id) REFERENCES $tableTypeMotor (id) ON DELETE CASCADE
      )
    ''');

    // Insert Default Type Motor & Services
    await _insertDefaultTypesAndServices(db);

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
    if (oldVersion < 4) {
      await db.execute(
        "ALTER TABLE $tableMotorcycles ADD COLUMN type TEXT DEFAULT 'matic'",
      );
    }
    if (oldVersion < 5) {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      const integerType = 'INTEGER NOT NULL';

      await db.execute('''
        CREATE TABLE $tableIntervals (
          id $idType,
          motorcycle_id $integerType,
          service_item $textType,
          interval_km $integerType
        )
      ''');
    }
    if (oldVersion < 6) {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      const integerType = 'INTEGER NOT NULL';

      await db.execute('''
        CREATE TABLE $tableTypeMotor (
          id $idType,
          name $textType
        )
      ''');

      await db.execute('''
        CREATE TABLE $tableListService (
          id $idType,
          type_motor_id $integerType,
          service_name $textType,
          min_km $integerType,
          max_km $integerType,
          FOREIGN KEY (type_motor_id) REFERENCES $tableTypeMotor (id) ON DELETE CASCADE
        )
      ''');

      await _insertDefaultTypesAndServices(db);
    }
  }

  Future<void> _insertDefaultTypesAndServices(Database db) async {
    final typeMotors = [
      {'id': 1, 'name': 'Matic'},
      {'id': 2, 'name': 'Bebek'},
      {'id': 3, 'name': 'Sport'},
    ];
    for (var type in typeMotors) {
      await db.insert(
        tableTypeMotor,
        type,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final listServiceMatic = [
      {
        'type_motor_id': 1,
        'service_name': 'Oli Mesin',
        'min_km': 2000,
        'max_km': 4000,
      },
      {
        'type_motor_id': 1,
        'service_name': 'Oli Gardan (Gear Oil)',
        'min_km': 8000,
        'max_km': 10000,
      },
      {
        'type_motor_id': 1,
        'service_name': 'Servis Ringan / Tune Up (Injeksi/Karbu)',
        'min_km': 4000,
        'max_km': 8000,
      },
      {
        'type_motor_id': 1,
        'service_name': 'Servis & Bersihkan CVT',
        'min_km': 8000,
        'max_km': 10000,
      },
      {
        'type_motor_id': 1,
        'service_name': 'Ganti V-Belt & Roller',
        'min_km': 20000,
        'max_km': 24000,
      },
      {
        'type_motor_id': 1,
        'service_name': 'Ganti Kampas Ganda & Mangkok CVT',
        'min_km': 24000,
        'max_km': 30000,
      },
      {
        'type_motor_id': 1,
        'service_name': 'Ganti Busi',
        'min_km': 8000,
        'max_km': 10000,
      },
      {
        'type_motor_id': 1,
        'service_name': 'Ganti Filter Udara',
        'min_km': 12000,
        'max_km': 16000,
      },
      {
        'type_motor_id': 1,
        'service_name': 'Ganti Kampas Rem (Depan/Belakang)',
        'min_km': 10000,
        'max_km': 15000,
      },
      {
        'type_motor_id': 1,
        'service_name': 'Ganti Air Radiator (Coolant)',
        'min_km': 10000,
        'max_km': 12000,
      },
      {
        'type_motor_id': 1,
        'service_name': 'Ganti Minyak Rem',
        'min_km': 20000,
        'max_km': 24000,
      },
      {
        'type_motor_id': 1,
        'service_name': 'Ganti Oli Shockbreaker Depan',
        'min_km': 15000,
        'max_km': 20000,
      },
    ];

    final listServiceBebek = [
      {
        'type_motor_id': 2,
        'service_name': 'Oli Mesin',
        'min_km': 2000,
        'max_km': 4000,
      },
      {
        'type_motor_id': 2,
        'service_name': 'Servis Ringan / Tune Up (Injeksi/Karbu)',
        'min_km': 4000,
        'max_km': 8000,
      },
      {
        'type_motor_id': 2,
        'service_name': 'Stel & Lumasi Rantai',
        'min_km': 500,
        'max_km': 1000,
      },
      {
        'type_motor_id': 2,
        'service_name': 'Ganti Gear Set (Gir Depan, Belakang, Rantai)',
        'min_km': 15000,
        'max_km': 25000,
      },
      {
        'type_motor_id': 2,
        'service_name': 'Ganti Busi',
        'min_km': 8000,
        'max_km': 10000,
      },
      {
        'type_motor_id': 2,
        'service_name': 'Ganti Filter Udara',
        'min_km': 12000,
        'max_km': 16000,
      },
      {
        'type_motor_id': 2,
        'service_name': 'Ganti Kampas Rem (Depan/Belakang)',
        'min_km': 10000,
        'max_km': 15000,
      },
      {
        'type_motor_id': 2,
        'service_name': 'Ganti Kampas Kopling',
        'min_km': 15000,
        'max_km': 20000,
      },
      {
        'type_motor_id': 2,
        'service_name': 'Ganti Minyak Rem',
        'min_km': 20000,
        'max_km': 24000,
      },
      {
        'type_motor_id': 2,
        'service_name': 'Ganti Oli Shockbreaker Depan',
        'min_km': 15000,
        'max_km': 20000,
      },
    ];

    final listServiceSport = [
      {
        'type_motor_id': 3,
        'service_name': 'Oli Mesin',
        'min_km': 2000,
        'max_km': 3000,
      },
      {
        'type_motor_id': 3,
        'service_name': 'Servis Ringan / Tune Up (Injeksi/Karbu)',
        'min_km': 4000,
        'max_km': 8000,
      },
      {
        'type_motor_id': 3,
        'service_name': 'Stel & Lumasi Rantai',
        'min_km': 500,
        'max_km': 1000,
      },
      {
        'type_motor_id': 3,
        'service_name': 'Ganti Gear Set (Gir Depan, Belakang, Rantai)',
        'min_km': 15000,
        'max_km': 25000,
      },
      {
        'type_motor_id': 3,
        'service_name': 'Ganti Busi',
        'min_km': 8000,
        'max_km': 10000,
      },
      {
        'type_motor_id': 3,
        'service_name': 'Ganti Filter Udara',
        'min_km': 12000,
        'max_km': 16000,
      },
      {
        'type_motor_id': 3,
        'service_name': 'Ganti Kampas Rem (Depan/Belakang)',
        'min_km': 10000,
        'max_km': 15000,
      },
      {
        'type_motor_id': 3,
        'service_name': 'Ganti Kampas Kopling',
        'min_km': 15000,
        'max_km': 20000,
      },
      {
        'type_motor_id': 3,
        'service_name': 'Ganti Kabel Kopling / Kabel Gas',
        'min_km': 10000,
        'max_km': 15000,
      },
      {
        'type_motor_id': 3,
        'service_name': 'Ganti Air Radiator (Coolant)',
        'min_km': 10000,
        'max_km': 12000,
      },
      {
        'type_motor_id': 3,
        'service_name': 'Ganti Minyak Rem',
        'min_km': 20000,
        'max_km': 24000,
      },
      {
        'type_motor_id': 3,
        'service_name': 'Ganti Oli Shockbreaker Depan',
        'min_km': 15000,
        'max_km': 20000,
      },
    ];

    final allServices = [
      ...listServiceMatic,
      ...listServiceBebek,
      ...listServiceSport,
    ];
    for (var s in allServices) {
      await db.insert(
        tableListService,
        s,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
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

  // --- Service Intervals CRUD ---

  Future<int> insertServiceInterval(ServiceInterval interval) async {
    final db = await instance.database;
    return await db.insert(
      tableIntervals,
      interval.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ServiceInterval>> getServiceIntervals(int motorcycleId) async {
    final db = await instance.database;
    final result = await db.query(
      tableIntervals,
      where: 'motorcycle_id = ?',
      whereArgs: [motorcycleId],
    );
    return result.map((json) => ServiceInterval.fromMap(json)).toList();
  }

  Future<int> updateServiceInterval(ServiceInterval interval) async {
    final db = await instance.database;
    return db.update(
      tableIntervals,
      interval.toMap(),
      where: 'id = ?',
      whereArgs: [interval.id],
    );
  }

  // Close the database safely
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
