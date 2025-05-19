import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class VideoCacheDatabase {
  static final VideoCacheDatabase _instance = VideoCacheDatabase._internal();

  factory VideoCacheDatabase() => _instance;

  VideoCacheDatabase._internal();

  Database? _database;

  // Get the database instance or initialize it if not already initialized.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database by opening or creating the SQLite database file.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'video_cache.db');

    return await openDatabase(
      path,
      version: 2,  // Incremented version for database migration.
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE videos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            videoId TEXT UNIQUE,
            filePath TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Handle migration logic (if needed).
        }
      },
    );
  }

  // Save video information (ID and file path) to the database.
  Future<void> saveVideo(String videoId, String filePath) async {
    final db = await database;
    await db.insert(
      'videos',
      {'videoId': videoId, 'filePath': filePath},
      conflictAlgorithm: ConflictAlgorithm.replace, // Replace if the videoId already exists.
    );
  }

  // Retrieve the file path of a cached video based on its ID.
  Future<String?> getVideoFilePath(String videoId) async {
    final db = await database;
    final result = await db.query(
      'videos',
      where: 'videoId = ?',
      whereArgs: [videoId],
    );

    if (result.isNotEmpty) {
      return result.first['filePath'] as String?;
    }
    return null; 
  }
}
