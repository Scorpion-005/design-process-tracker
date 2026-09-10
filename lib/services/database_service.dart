import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/design.dart';

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'design_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE designs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            remarks TEXT,
            receivedDate TEXT NOT NULL,
            cadApprovedDate TEXT,
            strikeOffDate TEXT,
            rotaryScreenDate TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertDesign(Design design) async {
    final db = await database;
    return db.insert('designs', design.toMap()..remove('id'));
  }

  Future<int> updateDesign(Design design) async {
    final db = await database;
    return db.update('designs', design.toMap(),
        where: 'id = ?', whereArgs: [design.id]);
  }

  Future<int> deleteDesign(int id) async {
    final db = await database;
    return db.delete('designs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Design>> getAllDesigns() async {
    final db = await database;
    final rows = await db.query('designs', orderBy: 'receivedDate DESC');
    return rows.map((r) => Design.fromMap(r)).toList();
  }

  Future<Design?> getDesign(int id) async {
    final db = await database;
    final rows = await db.query('designs', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Design.fromMap(rows.first);
  }

  // ---- Analytics helpers ----

  Future<List<Design>> getDesignsReceivedOn(DateTime day) =>
      _filterByDateField('receivedDate', day);

  Future<List<Design>> getDesignsApprovedOn(DateTime day) =>
      _filterByDateField('cadApprovedDate', day);

  Future<List<Design>> getDesignsStrikeOffOn(DateTime day) =>
      _filterByDateField('strikeOffDate', day);

  Future<List<Design>> getDesignsRotaryOn(DateTime day) =>
      _filterByDateField('rotaryScreenDate', day);

  Future<List<Design>> _filterByDateField(String field, DateTime day) async {
    final all = await getAllDesigns();
    return all.where((d) {
      DateTime? value;
      switch (field) {
        case 'receivedDate':
          value = d.receivedDate;
          break;
        case 'cadApprovedDate':
          value = d.cadApprovedDate;
          break;
        case 'strikeOffDate':
          value = d.strikeOffDate;
          break;
        case 'rotaryScreenDate':
          value = d.rotaryScreenDate;
          break;
      }
      if (value == null) return false;
      return value.year == day.year &&
          value.month == day.month &&
          value.day == day.day;
    }).toList();
  }
}
