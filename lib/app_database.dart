// ignore_for_file: public_member_api_docs

import 'dart:io';

import 'package:mysql_client/mysql_client.dart';

class QueryParam {
  QueryParam({required this.query, this.params});
  final String query;
  final Map<String, String?>? params;
}

///Database yang terhubung ke mysql
///instanenya akan diinject dengan @provider
class AppDatabase {
  AppDatabase._prevConstructor() {
    _init();
  }
  static AppDatabase? _prevInstance;

// ignore: prefer_constructors_over_static_methods
  /// return AppDatabase
  static AppDatabase get instance =>
      _prevInstance ??= AppDatabase._prevConstructor();

  MySQLConnection? _conn;

  Future<void> _init() async {
    _conn = await MySQLConnection.createConnection(
      host: 'localhost',
      port: 3306,
      userName: Platform.environment['DB_USER'] ?? 'dbuser',
      password: Platform.environment['DB_PASSWORD'] ?? 'dbpw',
      databaseName: Platform.environment['DB_NAME'] ?? 'heisgid_dmc', // optional
      secure: false,
    );

// actually connect to database
    await _conn?.connect();
    if (_conn?.connected != true) {
      throw Exception('Error connecting to database');
    }
  }

  Future<void> _makesureConnection() async {
    if (_conn?.connected != true) {
      await _init();
    }
  }

  Future<IResultSet> executeQuery(QueryParam queryParam) async {
    await _makesureConnection();

    /// kalau _conn null gak akan sampai ke sini
    /// jadi di sini aman untuk mengabaikan nullable _conn
    return _conn!.execute(queryParam.query, queryParam.params);
  }
}
