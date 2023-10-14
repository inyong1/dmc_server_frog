import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dmc_server_frog/app_database.dart';
import 'package:dmc_server_frog/models/base_response.dart';
import 'package:dmc_server_frog/safe_convert.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: BaseResponse(message: 'Method not allwed'),
    );
  }
  final queryParam = context.request.uri.queryParameters;
  final page = asInt(queryParam, 'page', defaultValue: 1);
  const limit = 50;
  final offset = (page - 1) * limit;
  final db = context.read<AppDatabase>();
  var sql = 'select a.*, b.kecamatan, b.kota';
  sql +=
      ' FROM anggota a LEFT JOIN masterkecamatan b on a.idkecamatan = b.idkecamatan';
  sql += ' ORDER BY a.namaanggota ASC LIMIT $limit OFFSET $offset';
  final result = await db.executeQuery(
    QueryParam(query: sql),
  );
  if (result.isEmpty) {
    return Response.json(body: BaseResponse(message: 'data tidak ditemukan'));
  }
  final jo = BaseResponse(success: true, message: 'berhasil').toJson();
  jo['data'] = result.rows.map((e) => e.assoc()).toList();
  return Response.json(body: jo);
}
