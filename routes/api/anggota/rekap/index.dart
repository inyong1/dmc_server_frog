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

  var sql =
      'select a.idkabupaten as idkota, b.kota, a.idkecamatan, b.kecamatan, COUNT(a.idkecamatan) as jumlah';
  sql += ' FROM anggota a';
  sql +=
      ' LEFT JOIN masterkecamatan b ON a.idkecamatan = b.idkecamatan AND a.idkabupaten = b.idkota';
  sql += ' WHERE a.statuskeaktifan = 1';
  sql += ' GROUP BY a.idkabupaten, a.idkecamatan';
  sql += ' ORDER BY b.kota, b.kecamatan ';

  final result = await db.executeQuery(QueryParam(query: sql));

  final jo = BaseResponse(success: true, message: 'berhasil').toJson();

  jo['data'] = result.rows.map((e) => e.assoc()).toList();

  return Response.json(body: jo);
}
