// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:postgres/postgres.dart';

void main() {
  test('Neon PostgreSQL connection test', () async {
    final endpoint = Endpoint(
      host: 'ep-curly-surf-at3sk8s8-pooler.c-9.us-east-1.aws.neon.tech',
      database: 'neondb',
      username: 'neondb_owner',
      password: 'npg_YhCO6NJL2tDf',
      port: 5432,
    );

    final connection = await Connection.open(
      endpoint,
      settings: const ConnectionSettings(
        sslMode: SslMode.require,
      ),
    );

    final result = await connection.execute('SELECT version();');
    expect(result.isNotEmpty, true);
    print('✅ Neon PostgreSQL Connected! Version: ${result.first[0]}');

    await connection.close();
  });
}
