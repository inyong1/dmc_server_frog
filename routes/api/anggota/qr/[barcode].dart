import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dmc_server_frog/app_database.dart';
import 'package:dmc_server_frog/models/base_response.dart';

import '../id/[idanggota].dart';

Future<Response> onRequest(RequestContext context, String barcode) async {
  return switch (context.request.method) {
    HttpMethod.get => await _onGet(context, barcode),
    _ => Response.json(
        statusCode: HttpStatus.badRequest,
        body: BaseResponse(message: 'Method not allwed'),
      ),
  };
}

Future<Response> _onGet(RequestContext context, String barcode) async {
  final db = context.read<AppDatabase>();

  var sql = 'select a.idanggota';
  sql += ' FROM anggota a';
  sql += ' WHERE a.barcode = :barcode LIMIT 1';
  final result = await db.executeQuery(
    QueryParam(query: sql, params: {'barcode': barcode}),
  );

  if (result.numOfRows == 0) {
    return Response.json(body: BaseResponse(message: 'data tidak ditemukan'));
  }
  final id = result.rows.first.typedColByName<String>('idanggota');
  if (id == null) {
    return Response.json(body: BaseResponse(message: 'data tidak ditemukan'));
  }

  return onGetAnggotaById(context, id);
}
