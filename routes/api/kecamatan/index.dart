import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dmc_server_frog/app_database.dart';
import 'package:dmc_server_frog/models/base_response.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => await _onGet(context),
    _ => Response.json(
        statusCode: HttpStatus.badRequest,
        body: BaseResponse(message: 'Method not allwed'),
      ),
  };
}

Future<Response> _onGet(RequestContext context) async {
  final db = context.read<AppDatabase>();

  var sql = 'select *';
  sql += ' FROM masterkecamatan';

  /// hanya ambil area jawa tengah
  sql += ' WHERE idpropinsi = 10';
  final result0 = await db.executeQuery(QueryParam(query: sql));

  if (result0.numOfRows == 0) {
    return Response.json(body: BaseResponse(message: 'data tidak ditemukan'));
  }

  final jo = BaseResponse(success: true, message: 'berhasil').toJson();
  jo['data'] = result0.rows.map((e) => e.assoc()).toList();

  return Response.json(body: jo);
}
