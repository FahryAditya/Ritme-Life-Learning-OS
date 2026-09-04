import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/task_model.dart';
import '../models/transaction_model.dart';
import '../models/study_pod_model.dart';
import 'neon_database_helper.dart';

class DatabaseHelper {
  static const String _dbName = 'ritme_database.db';
  static const int _dbVersion = 3;

  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Inisialisasi FFI untuk platform desktop (Windows, Linux, macOS)
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabel Tasks
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        is_urgent INTEGER NOT NULL,
        is_important INTEGER NOT NULL,
        cognitive_load INTEGER NOT NULL,
        bpm INTEGER NOT NULL,
        genre TEXT NOT NULL,
        is_active INTEGER NOT NULL,
        is_completed INTEGER NOT NULL,
        scheduled_time TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Tabel Transactions
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        is_expense INTEGER NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 3. Tabel Study Pods
    await db.execute('''
      CREATE TABLE study_pods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subtitle TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        progress_seconds INTEGER NOT NULL,
        audio_url TEXT NOT NULL,
        ai_notes TEXT NOT NULL,
        is_active INTEGER NOT NULL
      )
    ''');

    // 4. Tabel Settings
    await db.execute('''
      CREATE TABLE user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 5. Tabel Chat Messages
    await db.execute('''
      CREATE TABLE chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        is_user INTEGER NOT NULL,
        text TEXT NOT NULL,
        has_card INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.delete('tasks');
      await db.delete('transactions');
      await db.delete('study_pods');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_messages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          is_user INTEGER NOT NULL,
          text TEXT NOT NULL,
          has_card INTEGER NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');
    }
  }

  /// Mengosongkan seluruh data tabel untuk pengujian fresh-install
  Future<void> clearAllData() async {
    try {
      await NeonDatabaseHelper.instance.clearAllData();
    } catch (_) {}
    final db = await database;
    await db.delete('tasks');
    await db.delete('transactions');
    await db.delete('study_pods');
    await db.delete('chat_messages');
  }

  // ================= TASKS OPERATIONS =================

  Future<List<TaskModel>> getTasks({bool? onlyIncomplete}) async {
    try {
      return await NeonDatabaseHelper.instance.getTasks(onlyIncomplete: onlyIncomplete);
    } catch (_) {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: onlyIncomplete == true ? 'is_completed = 0' : null,
        orderBy: 'is_active DESC, id ASC',
      );
      return maps.map((m) => TaskModel.fromMap(m)).toList();
    }
  }

  Future<TaskModel?> getActiveTask() async {
    try {
      return await NeonDatabaseHelper.instance.getActiveTask();
    } catch (_) {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: 'is_active = 1 AND is_completed = 0',
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return TaskModel.fromMap(maps.first);
      }
      return null;
    }
  }

  Future<int> insertTask(TaskModel task) async {
    try {
      return await NeonDatabaseHelper.instance.insertTask(task);
    } catch (_) {
      final db = await database;
      return await db.insert('tasks', task.toMap());
    }
  }

  Future<int> updateTask(TaskModel task) async {
    try {
      return await NeonDatabaseHelper.instance.updateTask(task);
    } catch (_) {
      final db = await database;
      return await db.update(
        'tasks',
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
    }
  }

  Future<int> setActiveTask(int taskId) async {
    try {
      return await NeonDatabaseHelper.instance.setActiveTask(taskId);
    } catch (_) {
      final db = await database;
      await db.update('tasks', {'is_active': 0});
      return await db.update(
        'tasks',
        {'is_active': 1},
        where: 'id = ?',
        whereArgs: [taskId],
      );
    }
  }

  Future<int> deleteTask(int id) async {
    try {
      return await NeonDatabaseHelper.instance.deleteTask(id);
    } catch (_) {
      final db = await database;
      return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    }
  }

  // ================= TRANSACTIONS OPERATIONS =================

  Future<List<TransactionModel>> getTransactions() async {
    try {
      return await NeonDatabaseHelper.instance.getTransactions();
    } catch (_) {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        orderBy: 'id DESC',
      );
      return maps.map((m) => TransactionModel.fromMap(m)).toList();
    }
  }

  Future<double> calculateTotalBalance() async {
    try {
      return await NeonDatabaseHelper.instance.calculateTotalBalance();
    } catch (_) {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('transactions');
      double balance = 0.0;
      for (var m in maps) {
        final amount = (m['amount'] as num).toDouble();
        final isExpense = (m['is_expense'] as int) == 1;
        if (isExpense) {
          balance -= amount;
        } else {
          balance += amount;
        }
      }
      return balance;
    }
  }

  Future<int> insertTransaction(TransactionModel tx) async {
    try {
      return await NeonDatabaseHelper.instance.insertTransaction(tx);
    } catch (_) {
      final db = await database;
      return await db.insert('transactions', tx.toMap());
    }
  }

  Future<int> deleteTransaction(int id) async {
    try {
      return await NeonDatabaseHelper.instance.deleteTransaction(id);
    } catch (_) {
      final db = await database;
      return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    }
  }

  // ================= STUDY PODS OPERATIONS =================

  Future<List<StudyPodModel>> getStudyPods() async {
    try {
      return await NeonDatabaseHelper.instance.getStudyPods();
    } catch (_) {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('study_pods');
      return maps.map((m) => StudyPodModel.fromMap(m)).toList();
    }
  }

  Future<StudyPodModel?> getActiveStudyPod() async {
    try {
      return await NeonDatabaseHelper.instance.getActiveStudyPod();
    } catch (_) {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'study_pods',
        where: 'is_active = 1',
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return StudyPodModel.fromMap(maps.first);
      }
      return null;
    }
  }

  Future<int> insertStudyPod(StudyPodModel pod) async {
    try {
      return await NeonDatabaseHelper.instance.insertStudyPod(pod);
    } catch (_) {
      final db = await database;
      return await db.insert('study_pods', pod.toMap());
    }
  }

  Future<int> updateStudyPodProgress(int id, int progressSeconds) async {
    try {
      return await NeonDatabaseHelper.instance.updateStudyPodProgress(id, progressSeconds);
    } catch (_) {
      final db = await database;
      return await db.update(
        'study_pods',
        {'progress_seconds': progressSeconds},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<int> deleteStudyPod(int id) async {
    try {
      return await NeonDatabaseHelper.instance.deleteStudyPod(id);
    } catch (_) {
      final db = await database;
      return await db.delete('study_pods', where: 'id = ?', whereArgs: [id]);
    }
  }

  // ================= CHAT MESSAGES OPERATIONS =================

  Future<List<Map<String, dynamic>>> getChatMessages() async {
    try {
      return await NeonDatabaseHelper.instance.getChatMessages();
    } catch (_) {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'chat_messages',
        orderBy: 'id ASC',
      );
      return maps.map((m) => {
        'isUser': (m['is_user'] as int) == 1,
        'text': m['text'] as String,
        'hasCard': (m['has_card'] as int) == 1,
      }).toList();
    }
  }

  Future<int> insertChatMessage({
    required bool isUser,
    required String text,
    required bool hasCard,
  }) async {
    try {
      return await NeonDatabaseHelper.instance.insertChatMessage(
        isUser: isUser,
        text: text,
        hasCard: hasCard,
      );
    } catch (_) {
      final db = await database;
      return await db.insert('chat_messages', {
        'is_user': isUser ? 1 : 0,
        'text': text,
        'has_card': hasCard ? 1 : 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<int> clearChatMessages() async {
    try {
      return await NeonDatabaseHelper.instance.clearChatMessages();
    } catch (_) {
      final db = await database;
      return await db.delete('chat_messages');
    }
  }

  // ================= CONTEXT DATA UNTUK GEMINI =================

  Future<String> getSummaryForGemini() async {
    final activeTask = await getActiveTask();
    final tasks = await getTasks(onlyIncomplete: true);
    final balance = await calculateTotalBalance();
    final pods = await getStudyPods();

    return '''
KONTEKS TERBARU DARI CLOUD NEONDB POSTGRESQL / SQLITE RITME:
1. Tugas Aktif: ${activeTask != null ? '${activeTask.title} (BPM: ${activeTask.bpm}, Kognitif: ${activeTask.cognitiveLoad}%)' : 'Tidak ada tugas aktif.'}
2. Total Tugas Belum Selesai: ${tasks.length} tugas.
3. Total Saldo Keuangan: Rp ${balance.toStringAsFixed(0)}
4. Pod Belajar Terakhir: ${pods.isNotEmpty ? pods.first.title : 'Belum ada materi.'}
''';
  }
}
