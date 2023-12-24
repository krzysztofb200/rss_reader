// database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Future<void> setDarkMode(bool isDarkMode) async {
    final Database db = await openDatabase(
      join(await getDatabasesPath(), 'settings_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE settings(id INTEGER PRIMARY KEY, isDarkMode INTEGER)',
        );
      },
      version: 1,
    );

    await db.insert(
      'settings',
      {'isDarkMode': isDarkMode ? 1 : 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<bool> getDarkMode() async {
    final Database db = await openDatabase(
      join(await getDatabasesPath(), 'settings_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE settings(id INTEGER PRIMARY KEY, isDarkMode INTEGER)',
        );
      },
      version: 1,
    );

    final List<Map<String, dynamic>> result = await db.query('settings');
    if (result.isNotEmpty) {
      return result[0]['isDarkMode'] == 1;
    }

    return false;
  }
}
