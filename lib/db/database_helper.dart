import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('habit_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

/*  Future<void> initializeDatabase() async {
    final screens = await fetchScreens();
    if (screens.isEmpty) {
      await insertScreen('Habbit 1');
      for (int i = 0; i < 365; i++) {
        await insertBox(1, i, 0); // Screen ID 1
      }
    }
  }*/

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE screens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE boxes (
        screen_id INTEGER,
        box_index INTEGER,
        hours INTEGER,
        FOREIGN KEY (screen_id) REFERENCES screens (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertScreen(String title) async {
    final db = await instance.database;
    return await db.insert('screens', {'title': title});
  }

  Future<int> updateScreen(int screenId, String title) async {
    final db = await instance.database;
    return await db.update(
      'screens',
      {'title': title},
      where: "id = ?",
      whereArgs: [screenId],
    );
  }

  Future<int> insertBox(int screenId, int boxIndex, int hours) async {
    final db = await instance.database;
    return await db.insert(
      'boxes',
      {'screen_id': screenId, 'box_index': boxIndex, 'hours': hours},
    );
  }

  Future<void> updateBox(int screenId, int boxIndex, int hours) async {
    final db = await instance.database;
    await db.update(
      'boxes',
      {'hours': hours},
      where: 'screen_id = ? AND box_index = ?',
      whereArgs: [screenId, boxIndex],
    );
  }

  Future<List<Map<String, dynamic>>> fetchScreens() async {
    final db = await instance.database;

    return await db.query('screens');
  }

  Future<List<Map<String, dynamic>>> fetchBoxes(int screenId) async {
    final db = await instance.database;
    return await db.query(
      'boxes',
      where: 'screen_id = ?',
      whereArgs: [screenId],
    );
  }

  Future<void> deleteScreen(int screenId) async {
    ///TODO: ON DELETE CASCADE better?
    final db = await instance.database;
    await db.delete(
      'screens',
      where: 'id = ?',
      whereArgs: [screenId],
    );
    await db.delete(
      'boxes',
      where: 'screen_id = ?',
      whereArgs: [screenId],
    );
  }

/*  Future close() async {
    final db = await instance.database;
    db.close();
  }*/
}
