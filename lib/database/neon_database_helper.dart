import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:postgres/postgres.dart';
import '../models/task_model.dart';
import '../models/transaction_model.dart';
import '../models/study_pod_model.dart';

class NeonDatabaseHelper {
  static final NeonDatabaseHelper instance = NeonDatabaseHelper._internal();
  NeonDatabaseHelper._internal();

  Connection? _connection;
  bool _isTableInitialized = false;

  String get _host {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env['NEON_DB_HOST'] ??
            'ep-curly-surf-at3sk8s8-pooler.c-9.us-east-1.aws.neon.tech';
      }
    } catch (_) {}
    return 'ep-curly-surf-at3sk8s8-pooler.c-9.us-east-1.aws.neon.tech';
  }

  String get _user {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env['NEON_DB_USER'] ?? 'neondb_owner';
      }
    } catch (_) {}
    return 'neondb_owner';
  }

  String get _password {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env['NEON_DB_PASSWORD'] ?? 'npg_YhCO6NJL2tDf';
      }
    } catch (_) {}
    return 'npg_YhCO6NJL2tDf';
  }

  String get _databaseName {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env['NEON_DB_NAME'] ?? 'neondb';
      }
    } catch (_) {}
    return 'neondb';
  }

  int get _port {
    try {
      if (dotenv.isInitialized) {
        return int.tryParse(dotenv.env['NEON_DB_PORT'] ?? '5432') ?? 5432;
      }
    } catch (_) {}
    return 5432;
  }

  Future<Connection> getConnection() async {
    if (_connection != null && _connection!.isOpen) {
      return _connection!;
    }

    final endpoint = Endpoint(
      host: _host,
      database: _databaseName,
      username: _user,
      password: _password,
      port: _port,
    );

    _connection = await Connection.open(
      endpoint,
      settings: const ConnectionSettings(
        sslMode: SslMode.require,
      ),
    );

    if (!_isTableInitialized) {
      await _initSchema(_connection!);
      _isTableInitialized = true;
    }

    return _connection!;
  }

  Future<void> _initSchema(Connection conn) async {
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        is_urgent INT NOT NULL,
        is_important INT NOT NULL,
        cognitive_load INT NOT NULL,
        bpm INT NOT NULL,
        genre TEXT NOT NULL,
        is_active INT NOT NULL,
        is_completed INT NOT NULL,
        scheduled_time TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        amount DOUBLE PRECISION NOT NULL,
        is_expense INT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS study_pods (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        subtitle TEXT NOT NULL,
        duration_seconds INT NOT NULL,
        progress_seconds INT NOT NULL,
        audio_url TEXT NOT NULL,
        ai_notes TEXT NOT NULL,
        is_active INT NOT NULL
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id SERIAL PRIMARY KEY,
        is_user INT NOT NULL,
        text TEXT NOT NULL,
        has_card INT NOT NULL,
        timestamp TEXT NOT NULL
      );
    ''');
  }

  // ================= TASKS OPERATIONS =================

  Future<List<TaskModel>> getTasks({bool? onlyIncomplete}) async {
    final conn = await getConnection();
    final String query = onlyIncomplete == true
        ? 'SELECT id, title, category, is_urgent, is_important, cognitive_load, bpm, genre, is_active, is_completed, scheduled_time, created_at FROM tasks WHERE is_completed = 0 ORDER BY is_active DESC, id ASC;'
        : 'SELECT id, title, category, is_urgent, is_important, cognitive_load, bpm, genre, is_active, is_completed, scheduled_time, created_at FROM tasks ORDER BY is_active DESC, id ASC;';

    final result = await conn.execute(query);
    return result.map((row) {
      return TaskModel(
        id: row[0] as int,
        title: row[1] as String,
        category: row[2] as String,
        isUrgent: (row[3] as int) == 1,
        isImportant: (row[4] as int) == 1,
        cognitiveLoad: row[5] as int,
        bpm: row[6] as int,
        genre: row[7] as String,
        isActive: (row[8] as int) == 1,
        isCompleted: (row[9] as int) == 1,
        scheduledTime: row[10] as String,
        createdAt: row[11] as String,
      );
    }).toList();
  }

  Future<TaskModel?> getActiveTask() async {
    final conn = await getConnection();
    final result = await conn.execute(
        'SELECT id, title, category, is_urgent, is_important, cognitive_load, bpm, genre, is_active, is_completed, scheduled_time, created_at FROM tasks WHERE is_active = 1 AND is_completed = 0 LIMIT 1;');

    if (result.isNotEmpty) {
      final row = result.first;
      return TaskModel(
        id: row[0] as int,
        title: row[1] as String,
        category: row[2] as String,
        isUrgent: (row[3] as int) == 1,
        isImportant: (row[4] as int) == 1,
        cognitiveLoad: row[5] as int,
        bpm: row[6] as int,
        genre: row[7] as String,
        isActive: (row[8] as int) == 1,
        isCompleted: (row[9] as int) == 1,
        scheduledTime: row[10] as String,
        createdAt: row[11] as String,
      );
    }
    return null;
  }

  Future<int> insertTask(TaskModel task) async {
    final conn = await getConnection();
    final result = await conn.execute(
      Sql.named(
        'INSERT INTO tasks (title, category, is_urgent, is_important, cognitive_load, bpm, genre, is_active, is_completed, scheduled_time, created_at) VALUES (@title, @category, @isUrgent, @isImportant, @cognitiveLoad, @bpm, @genre, @isActive, @isCompleted, @scheduledTime, @createdAt) RETURNING id;',
      ),
      parameters: {
        'title': task.title,
        'category': task.category,
        'isUrgent': task.isUrgent ? 1 : 0,
        'isImportant': task.isImportant ? 1 : 0,
        'cognitiveLoad': task.cognitiveLoad,
        'bpm': task.bpm,
        'genre': task.genre,
        'isActive': task.isActive ? 1 : 0,
        'isCompleted': task.isCompleted ? 1 : 0,
        'scheduledTime': task.scheduledTime,
        'createdAt': task.createdAt,
      },
    );

    if (result.isNotEmpty && result.first[0] != null) {
      return result.first[0] as int;
    }
    return 1;
  }

  Future<int> updateTask(TaskModel task) async {
    if (task.id == null) return 0;
    final conn = await getConnection();
    await conn.execute(
      Sql.named(
        'UPDATE tasks SET title = @title, category = @category, is_urgent = @isUrgent, is_important = @isImportant, cognitive_load = @cognitiveLoad, bpm = @bpm, genre = @genre, is_active = @isActive, is_completed = @isCompleted, scheduled_time = @scheduledTime WHERE id = @id;',
      ),
      parameters: {
        'id': task.id,
        'title': task.title,
        'category': task.category,
        'isUrgent': task.isUrgent ? 1 : 0,
        'isImportant': task.isImportant ? 1 : 0,
        'cognitiveLoad': task.cognitiveLoad,
        'bpm': task.bpm,
        'genre': task.genre,
        'isActive': task.isActive ? 1 : 0,
        'isCompleted': task.isCompleted ? 1 : 0,
        'scheduledTime': task.scheduledTime,
      },
    );
    return 1;
  }

  Future<int> setActiveTask(int taskId) async {
    final conn = await getConnection();
    await conn.execute('UPDATE tasks SET is_active = 0;');
    await conn.execute(
      Sql.named('UPDATE tasks SET is_active = 1 WHERE id = @id;'),
      parameters: {'id': taskId},
    );
    return 1;
  }

  Future<int> deleteTask(int id) async {
    final conn = await getConnection();
    await conn.execute(
      Sql.named('DELETE FROM tasks WHERE id = @id;'),
      parameters: {'id': id},
    );
    return 1;
  }

  // ================= TRANSACTIONS OPERATIONS =================

  Future<List<TransactionModel>> getTransactions() async {
    final conn = await getConnection();
    final result = await conn.execute(
        'SELECT id, title, amount, is_expense, category, date, created_at FROM transactions ORDER BY id DESC;');

    return result.map((row) {
      return TransactionModel(
        id: row[0] as int,
        title: row[1] as String,
        amount: (row[2] as num).toDouble(),
        isExpense: (row[3] as int) == 1,
        category: row[4] as String,
        date: row[5] as String,
        createdAt: row[6] as String,
      );
    }).toList();
  }

  Future<double> calculateTotalBalance() async {
    final conn = await getConnection();
    final result = await conn
        .execute('SELECT amount, is_expense FROM transactions;');

    double balance = 0.0;
    for (final row in result) {
      final amount = (row[0] as num).toDouble();
      final isExpense = (row[1] as int) == 1;
      if (isExpense) {
        balance -= amount;
      } else {
        balance += amount;
      }
    }
    return balance;
  }

  Future<int> insertTransaction(TransactionModel tx) async {
    final conn = await getConnection();
    final result = await conn.execute(
      Sql.named(
        'INSERT INTO transactions (title, amount, is_expense, category, date, created_at) VALUES (@title, @amount, @isExpense, @category, @date, @createdAt) RETURNING id;',
      ),
      parameters: {
        'title': tx.title,
        'amount': tx.amount,
        'isExpense': tx.isExpense ? 1 : 0,
        'category': tx.category,
        'date': tx.date,
        'createdAt': tx.createdAt,
      },
    );

    if (result.isNotEmpty && result.first[0] != null) {
      return result.first[0] as int;
    }
    return 1;
  }

  Future<int> deleteTransaction(int id) async {
    final conn = await getConnection();
    await conn.execute(
      Sql.named('DELETE FROM transactions WHERE id = @id;'),
      parameters: {'id': id},
    );
    return 1;
  }

  // ================= STUDY PODS OPERATIONS =================

  Future<List<StudyPodModel>> getStudyPods() async {
    final conn = await getConnection();
    final result = await conn.execute(
        'SELECT id, title, subtitle, duration_seconds, progress_seconds, audio_url, ai_notes, is_active FROM study_pods ORDER BY id ASC;');

    return result.map((row) {
      return StudyPodModel(
        id: row[0] as int,
        title: row[1] as String,
        subtitle: row[2] as String,
        durationSeconds: row[3] as int,
        progressSeconds: row[4] as int,
        audioUrl: row[5] as String,
        aiNotes: row[6] as String,
        isActive: (row[7] as int) == 1,
      );
    }).toList();
  }

  Future<StudyPodModel?> getActiveStudyPod() async {
    final conn = await getConnection();
    final result = await conn.execute(
        'SELECT id, title, subtitle, duration_seconds, progress_seconds, audio_url, ai_notes, is_active FROM study_pods WHERE is_active = 1 LIMIT 1;');

    if (result.isNotEmpty) {
      final row = result.first;
      return StudyPodModel(
        id: row[0] as int,
        title: row[1] as String,
        subtitle: row[2] as String,
        durationSeconds: row[3] as int,
        progressSeconds: row[4] as int,
        audioUrl: row[5] as String,
        aiNotes: row[6] as String,
        isActive: (row[7] as int) == 1,
      );
    }
    return null;
  }

  Future<int> insertStudyPod(StudyPodModel pod) async {
    final conn = await getConnection();
    final result = await conn.execute(
      Sql.named(
        'INSERT INTO study_pods (title, subtitle, duration_seconds, progress_seconds, audio_url, ai_notes, is_active) VALUES (@title, @subtitle, @durationSeconds, @progressSeconds, @audioUrl, @aiNotes, @isActive) RETURNING id;',
      ),
      parameters: {
        'title': pod.title,
        'subtitle': pod.subtitle,
        'durationSeconds': pod.durationSeconds,
        'progressSeconds': pod.progressSeconds,
        'audioUrl': pod.audioUrl,
        'aiNotes': pod.aiNotes,
        'isActive': pod.isActive ? 1 : 0,
      },
    );

    if (result.isNotEmpty && result.first[0] != null) {
      return result.first[0] as int;
    }
    return 1;
  }

  Future<int> updateStudyPodProgress(int id, int progressSeconds) async {
    final conn = await getConnection();
    await conn.execute(
      Sql.named(
        'UPDATE study_pods SET progress_seconds = @progressSeconds WHERE id = @id;',
      ),
      parameters: {
        'id': id,
        'progressSeconds': progressSeconds,
      },
    );
    return 1;
  }

  Future<int> deleteStudyPod(int id) async {
    final conn = await getConnection();
    await conn.execute(
      Sql.named('DELETE FROM study_pods WHERE id = @id;'),
      parameters: {'id': id},
    );
    return 1;
  }

  // ================= CHAT MESSAGES OPERATIONS =================

  Future<List<Map<String, dynamic>>> getChatMessages() async {
    final conn = await getConnection();
    final result = await conn.execute(
        'SELECT is_user, text, has_card FROM chat_messages ORDER BY id ASC;');

    return result.map((row) {
      return {
        'isUser': (row[0] as int) == 1,
        'text': row[1] as String,
        'hasCard': (row[2] as int) == 1,
      };
    }).toList();
  }

  Future<int> insertChatMessage({
    required bool isUser,
    required String text,
    required bool hasCard,
  }) async {
    final conn = await getConnection();
    final result = await conn.execute(
      Sql.named(
        'INSERT INTO chat_messages (is_user, text, has_card, timestamp) VALUES (@isUser, @text, @hasCard, @timestamp) RETURNING id;',
      ),
      parameters: {
        'isUser': isUser ? 1 : 0,
        'text': text,
        'hasCard': hasCard ? 1 : 0,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (result.isNotEmpty && result.first[0] != null) {
      return result.first[0] as int;
    }
    return 1;
  }

  Future<int> clearChatMessages() async {
    final conn = await getConnection();
    await conn.execute('TRUNCATE TABLE chat_messages;');
    return 1;
  }

  Future<void> clearAllData() async {
    final conn = await getConnection();
    await conn.execute('TRUNCATE TABLE tasks, transactions, study_pods, chat_messages, user_settings;');
  }
}
