import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/task_model.dart';
import '../models/transaction_model.dart';
import '../models/study_pod_model.dart';
import '../models/habit_model.dart';
import '../models/journal_model.dart';
import '../models/focus_session_model.dart';
import 'neon_database_helper.dart';

class DatabaseHelper {
  static const String _dbName = 'ritme_database.db';
  static const int _dbVersion = 4;

  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
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

    // 6. Tabel Habits
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        streak_count INTEGER NOT NULL,
        is_completed_today INTEGER NOT NULL,
        last_completed_date TEXT NOT NULL
      )
    ''');

    // 7. Tabel Journal Entries
    await db.execute('''
      CREATE TABLE journal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        content TEXT NOT NULL,
        mood_level INTEGER NOT NULL DEFAULT 3,
        created_at TEXT NOT NULL
      )
    ''');

    // 8. Tabel Focus Sessions
    await db.execute('''
      CREATE TABLE focus_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER,
        task_title TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        session_type TEXT NOT NULL DEFAULT 'focus',
        completed_at TEXT NOT NULL
      )
    ''');

    // Seed default habits
    await db.insert('habits', {
      'title': 'Membaca 15 Menit',
      'category': 'Pengembangan Diri',
      'streak_count': 4,
      'is_completed_today': 0,
      'last_completed_date': '',
    });
    await db.insert('habits', {
      'title': 'Olahraga Ringan / Stretches',
      'category': 'Kesehatan',
      'streak_count': 7,
      'is_completed_today': 1,
      'last_completed_date': DateTime.now().toIso8601String().split('T').first,
    });
    await db.insert('habits', {
      'title': 'Jeda Istirahat Layar & Meditasi',
      'category': 'Fokus & Mental',
      'streak_count': 3,
      'is_completed_today': 0,
      'last_completed_date': '',
    });
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
    await db.execute('''
      CREATE TABLE IF NOT EXISTS habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        streak_count INTEGER NOT NULL,
        is_completed_today INTEGER NOT NULL,
        last_completed_date TEXT NOT NULL
      )
    ''');
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS journal_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          content TEXT NOT NULL,
          mood_level INTEGER NOT NULL DEFAULT 3,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS focus_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          task_id INTEGER,
          task_title TEXT NOT NULL,
          duration_minutes INTEGER NOT NULL,
          session_type TEXT NOT NULL DEFAULT 'focus',
          completed_at TEXT NOT NULL
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

  // ================= HABITS OPERATIONS =================

  Future<List<HabitModel>> getHabits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('habits', orderBy: 'id ASC');
    if (maps.isEmpty) {
      await db.insert('habits', {
        'title': 'Membaca 15 Menit',
        'category': 'Pengembangan Diri',
        'streak_count': 4,
        'is_completed_today': 0,
        'last_completed_date': '',
      });
      await db.insert('habits', {
        'title': 'Olahraga Ringan / Stretches',
        'category': 'Kesehatan',
        'streak_count': 7,
        'is_completed_today': 1,
        'last_completed_date': DateTime.now().toIso8601String().split('T').first,
      });
      final reMaps = await db.query('habits', orderBy: 'id ASC');
      return reMaps.map((m) => HabitModel.fromMap(m)).toList();
    }
    return maps.map((m) => HabitModel.fromMap(m)).toList();
  }

  Future<int> insertHabit(HabitModel habit) async {
    final db = await database;
    return await db.insert('habits', habit.toMap());
  }

  Future<int> toggleHabitCompletion(HabitModel habit) async {
    final db = await database;
    final newStatus = !habit.isCompletedToday;
    final newStreak = newStatus ? habit.streakCount + 1 : (habit.streakCount > 0 ? habit.streakCount - 1 : 0);
    final todayStr = newStatus ? DateTime.now().toIso8601String().split('T').first : '';

    return await db.update(
      'habits',
      {
        'is_completed_today': newStatus ? 1 : 0,
        'streak_count': newStreak,
        'last_completed_date': todayStr,
      },
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(int id) async {
    final db = await database;
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  // ================= JOURNAL OPERATIONS =================

  Future<int> saveJournalEntry(JournalModel entry) async {
    final db = await database;
    // Upsert by date: hapus entri lama di hari yang sama, lalu insert baru
    await db.delete('journal_entries', where: 'date = ?', whereArgs: [entry.date]);
    return await db.insert('journal_entries', entry.toMap());
  }

  Future<JournalModel?> getJournalEntryByDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'journal_entries',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (maps.isNotEmpty) return JournalModel.fromMap(maps.first);
    return null;
  }

  Future<List<JournalModel>> getAllJournalEntries() async {
    final db = await database;
    final maps = await db.query('journal_entries', orderBy: 'date DESC');
    return maps.map((m) => JournalModel.fromMap(m)).toList();
  }

  /// Menghitung berapa hari berturut-turut user menulis jurnal
  Future<int> getJournalStreak() async {
    final db = await database;
    final maps = await db.query('journal_entries', orderBy: 'date DESC');
    if (maps.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (final m in maps) {
      final entryDate = DateTime.tryParse(m['date'] as String);
      if (entryDate == null) break;

      final diff = checkDate.difference(entryDate).inDays;
      if (diff == 0 || diff == 1) {
        streak++;
        checkDate = entryDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<int> deleteJournalEntry(int id) async {
    final db = await database;
    return await db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ================= FOCUS SESSIONS OPERATIONS =================

  Future<int> saveFocusSession(FocusSessionModel session) async {
    final db = await database;
    return await db.insert('focus_sessions', session.toMap());
  }

  Future<List<FocusSessionModel>> getFocusSessionsThisWeek() async {
    final db = await database;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartStr = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

    final maps = await db.query(
      'focus_sessions',
      where: "session_type = 'focus' AND completed_at >= ?",
      whereArgs: [weekStartStr],
      orderBy: 'completed_at ASC',
    );
    return maps.map((m) => FocusSessionModel.fromMap(m)).toList();
  }

  /// Mengembalikan total menit fokus per hari untuk 7 hari terakhir (index 0=Mon..6=Sun)
  Future<List<int>> getWeeklyFocusMinutes() async {
    final sessions = await getFocusSessionsThisWeek();
    final List<int> perDay = List.filled(7, 0); // 0=Mon, 6=Sun

    for (final s in sessions) {
      final dt = DateTime.tryParse(s.completedAt);
      if (dt == null) continue;
      final dayIndex = dt.weekday - 1; // Monday=0
      perDay[dayIndex] += s.durationMinutes;
    }
    return perDay;
  }

  Future<int> getTotalFocusMinutesThisWeek() async {
    final sessions = await getFocusSessionsThisWeek();
    return sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  // ================= CONTEXT DATA UNTUK GEMINI =================

  Future<String> getSummaryForGemini() async {
    final activeTask = await getActiveTask();
    final tasks = await getTasks(onlyIncomplete: true);
    final balance = await calculateTotalBalance();
    final pods = await getStudyPods();
    final focusMinutes = await getTotalFocusMinutesThisWeek();

    return '''
KONTEKS TERBARU DARI CLOUD NEONDB POSTGRESQL / SQLITE RITME:
1. Tugas Aktif: ${activeTask != null ? '${activeTask.title} (BPM: ${activeTask.bpm}, Kognitif: ${activeTask.cognitiveLoad}%)' : 'Tidak ada tugas aktif.'}
2. Total Tugas Belum Selesai: ${tasks.length} tugas.
3. Total Saldo Keuangan: Rp ${balance.toStringAsFixed(0)}
4. Pod Belajar Terakhir: ${pods.isNotEmpty ? pods.first.title : 'Belum ada materi.'}
5. Total Fokus Minggu Ini: $focusMinutes menit.
''';
  }
}
