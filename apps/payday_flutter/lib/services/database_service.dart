import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/income_source.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'payday.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 수익 테이블 생성
    await db.execute('''
      CREATE TABLE incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 사용자 설정 테이블 생성
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL
      )
    ''');

    // 목표 테이블 생성
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL DEFAULT 0,
        deadline TEXT,
        created_at TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0
      )
    ''');
  }

  // 수익 추가
  Future<int> addIncome({
    required String type,
    required String title,
    required double amount,
    String? description,
    DateTime? date,
  }) async {
    final db = await database;

    return await db.insert(
      'incomes',
      {
        'type': type,
        'title': title,
        'amount': amount,
        'description': description ?? '',
        'date': (date ?? DateTime.now()).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // 모든 수익 조회
  Future<List<Map<String, dynamic>>> getAllIncomes() async {
    final db = await database;
    return await db.query(
      'incomes',
      orderBy: 'date DESC',
    );
  }

  // 특정 타입의 수익 조회
  Future<List<Map<String, dynamic>>> getIncomesByType(String type) async {
    final db = await database;
    return await db.query(
      'incomes',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );
  }

  // 날짜 범위로 수익 조회
  Future<List<Map<String, dynamic>>> getIncomesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    return await db.query(
      'incomes',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
  }

  // 총 수익 계산
  Future<double> getTotalIncome() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM incomes',
    );

    return result.first['total'] as double? ?? 0.0;
  }

  // 월별 수익 계산
  Future<double> getMonthlyIncome(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 1).toIso8601String();

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM incomes WHERE date >= ? AND date < ?',
      [startDate, endDate],
    );

    return result.first['total'] as double? ?? 0.0;
  }

  // 타입별 수익 합계
  Future<Map<String, double>> getIncomeByTypes() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT type, SUM(amount) as total FROM incomes GROUP BY type',
    );

    Map<String, double> incomeByTypes = {};
    for (var row in result) {
      incomeByTypes[row['type'] as String] = row['total'] as double;
    }

    return incomeByTypes;
  }

  // 수익 수정
  Future<int> updateIncome(int id, {
    String? title,
    double? amount,
    String? description,
    DateTime? date,
  }) async {
    final db = await database;
    Map<String, dynamic> updates = {};

    if (title != null) updates['title'] = title;
    if (amount != null) updates['amount'] = amount;
    if (description != null) updates['description'] = description;
    if (date != null) updates['date'] = date.toIso8601String();

    return await db.update(
      'incomes',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 수익 삭제
  Future<int> deleteIncome(int id) async {
    final db = await database;
    return await db.delete(
      'incomes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 설정 저장
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 설정 조회
  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result.isNotEmpty) {
      return result.first['value'] as String;
    }
    return null;
  }

  // 목표 추가
  Future<int> addGoal({
    required String title,
    required double targetAmount,
    DateTime? deadline,
  }) async {
    final db = await database;

    return await db.insert(
      'goals',
      {
        'title': title,
        'target_amount': targetAmount,
        'deadline': deadline?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // 모든 목표 조회
  Future<List<Map<String, dynamic>>> getAllGoals() async {
    final db = await database;
    return await db.query(
      'goals',
      orderBy: 'created_at DESC',
    );
  }

  // 목표 진행률 업데이트
  Future<void> updateGoalProgress(int goalId, double currentAmount) async {
    final db = await database;
    await db.update(
      'goals',
      {'current_amount': currentAmount},
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  // 데이터베이스 닫기
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}