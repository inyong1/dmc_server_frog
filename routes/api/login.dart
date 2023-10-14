// ignore_for_file: directives_ordering

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:uuid/uuid.dart';

import 'package:dmc_server_frog/app_database.dart';
import 'package:dmc_server_frog/extensions/string_ext.dart';

Future<Response> onRequest(RequestContext context) async {
  /// siapin default response
  final response = <String, dynamic>{
    'success': false,
    'message': 'Terjadi kesalahan tidak diketahui',
  };

  /// pastikan http methodnya post
  if (context.request.method != HttpMethod.post ||
      context.request.headers['Content-Type'] !=
          'application/x-www-form-urlencoded') {
    response['message'] = 'Bad request';
    return Response.json(statusCode: HttpStatus.badRequest, body: response);
  }

  final formData = await context.request.formData();
  final username = formData.fields['username'] ?? '';
  final password = formData.fields['password'] ?? '';

  // return Response(body: b);
  final db = context.read<AppDatabase>();
  final result = await db.executeQuery(
    QueryParam(
      query:
          'SELECT idadmin, nama, level FROM admins WHERE username = :username AND password = :password LIMIT 1',
      params: {
        'username': username,
        'password': password.sha256Hash,
      },
    ),
  );

  if (result.rows.isEmpty) {
    response['message'] = 'Invalid credentials';
    return Response.json(statusCode: HttpStatus.unauthorized, body: response);
  }

  final token = const Uuid().v4();

  final row = result.rows.first.typedAssoc()..['token'] = token;
  // ..remove('username')
  // ..remove('createdon')
  // ..remove('updateon')
  // ..remove('idadmin');
  response['success'] = true;
  response['message'] = 'Login berhasil';
  response['data'] = row;
  var sql = 'UPDATE admins SET token = :token, updateon = :updateon';
  sql += ' WHERE idadmin = :idadmin';
  await db.executeQuery(
    QueryParam(
      query: sql,
      params: {
        'token': token,
        'updateon': DateTime.now().toIso8601String(),
        'idadmin': "${row['idadmin']}",
      },
    ),
  );

  return Response.json(body: response);
}
