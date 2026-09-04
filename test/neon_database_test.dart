// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:ritme/database/neon_database_helper.dart';
import 'package:ritme/models/task_model.dart';
import 'package:ritme/models/transaction_model.dart';

void main() {
  test('NeonDatabaseHelper CRUD test on Neon PostgreSQL', () async {
    final neon = NeonDatabaseHelper.instance;

    print('Testing NeonDB connection and schema initialization...');
    final tasksBefore = await neon.getTasks();
    print('Current tasks count in NeonDB: ${tasksBefore.length}');

    // Test insert task
    final newTask = TaskModel(
      title: 'Uji Coba NeonDB',
      category: 'Cloud Migration',
      bpm: 72,
      genre: 'Lo-Fi Chill',
    );
    final taskId = await neon.insertTask(newTask);
    print('Inserted task to NeonDB with ID: $taskId');
    expect(taskId > 0, true);

    // Test query tasks
    final tasksAfter = await neon.getTasks();
    expect(tasksAfter.any((t) => t.title == 'Uji Coba NeonDB'), true);

    // Test insert transaction
    final newTx = TransactionModel(
      title: 'Gaji Freelance Neon',
      amount: 15000000,
      isExpense: false,
      category: 'Pemasukan',
      date: 'Hari ini',
    );
    final txId = await neon.insertTransaction(newTx);
    print('Inserted transaction to NeonDB with ID: $txId');
    expect(txId > 0, true);

    final balance = await neon.calculateTotalBalance();
    print('Calculated total balance in NeonDB: Rp $balance');

    // Clean up test data
    await neon.deleteTask(taskId);
    await neon.deleteTransaction(txId);
    print('Test cleanup completed!');
  });
}
