import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ritme/database/database_helper.dart';
import 'package:ritme/models/task_model.dart';
import 'package:ritme/services/gemini_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Database is empty on clean start and supports CRUD', () async {
    // Pastikan database dikosongkan (0 baris data dummy)
    await DatabaseHelper.instance.clearAllData();

    final tasks = await DatabaseHelper.instance.getTasks();
    expect(tasks, isEmpty, reason: 'Tabel tasks harus kosong pada awal instalasi');

    final transactions = await DatabaseHelper.instance.getTransactions();
    expect(transactions, isEmpty, reason: 'Tabel transactions harus kosong pada awal instalasi');

    final pods = await DatabaseHelper.instance.getStudyPods();
    expect(pods, isEmpty, reason: 'Tabel study_pods harus kosong pada awal instalasi');

    final balance = await DatabaseHelper.instance.calculateTotalBalance();
    expect(balance, equals(0.0));

    // Uji tambah 1 data baru
    final newTaskId = await DatabaseHelper.instance.insertTask(TaskModel(
      title: 'Tugas Uji Coba',
      category: 'Deep Work',
      isUrgent: true,
      isImportant: true,
      cognitiveLoad: 75,
      bpm: 65,
      genre: 'Lo-Fi Piano',
      isActive: true,
      scheduledTime: 'Sekarang',
    ));

    expect(newTaskId, isPositive);
    final activeTask = await DatabaseHelper.instance.getActiveTask();
    expect(activeTask?.title, equals('Tugas Uji Coba'));

    // Bersihkan kembali
    await DatabaseHelper.instance.clearAllData();
  });

  test('GeminiService connects successfully with gemini-3.6-flash', () async {
    await dotenv.load(fileName: '.env');
    final response = await GeminiService.instance.sendMessage('Jawab dengan kata "Siap" jika kamu aktif.');
    expect(response, isNotEmpty);
    expect(response, isNot(contains('is not found')));
    expect(response, isNot(contains('no longer available')));
  }, timeout: const Timeout(Duration(seconds: 60)));
}
