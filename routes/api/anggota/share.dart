import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dmc_server_frog/app_database.dart';
import 'package:dmc_server_frog/models/base_response.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.post => await _onPost(context),
    _ => Response.json(
        statusCode: HttpStatus.badRequest,
        body: BaseResponse(message: 'Method not allwed'),
      ),
  };
}

Future<Response> _onPost(RequestContext context) async {
  final formData = await context.request.formData();
  var name = formData.fields['name'] ?? '';
  name = name.trim().replaceAll(' ', '-');
  final uniq = DateTime.now().millisecondsSinceEpoch;
  final kode = "$uniq-$name";
  final db = context.read<AppDatabase>();
  var sql = 'INSERT INTO kode_share (kode)VALUES(:kode)';
  final params = {
    'kode': kode,
  };
  final dbResult = await db.executeQuery(QueryParam(query: sql, params: params));
  if (dbResult.affectedRows == 0) {
    return Response.json(body: BaseResponse(message: 'Gagal membuat kode share'));
  }
  return Response.json(
    body: BaseResponse(success: true, message: 'Berhasil').toJson()..['kode'] = kode,
  );
}
