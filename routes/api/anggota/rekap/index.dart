import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dmc_server_frog/app_database.dart';
import 'package:dmc_server_frog/models/base_response.dart';
import 'package:dmc_server_frog/safe_convert.dart';

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
  final queryParam = context.request.uri.queryParameters;
  final levelAnggota = asString(queryParam, 'level_anggota');
  final levelWilayah = asString(queryParam, 'level_wilayah');
  final statusKeaktifan = asString(queryParam, 'statuskeaktifan');
  final idKota = asString(queryParam, 'idkota');
  final idKecamatan = asString(queryParam, 'idkecamatan');
  final idKelurahan = asString(queryParam, 'idkelurahan');

  final db = context.read<AppDatabase>();

  var sql =
      'select a.idkabupaten as idkota, b.kota, a.idkecamatan, b.kecamatan,c.idkelurahan, c.kelurahan, COUNT(a.idanggota) as jumlah';
  sql += ' FROM anggota a';
  sql +=
      ' LEFT JOIN masterkecamatan b ON a.idkecamatan = b.idkecamatan AND a.idkabupaten = b.idkota';
  sql += ' LEFT JOIN masterkelurahan c ON a.idkelurahan = c.idkelurahan';
  sql += ' WHERE a.statuskeaktifan > 0';
  if (levelAnggota.isNotEmpty) {
    sql += ' AND a.level = :levelAnggota';
  }
  if (levelWilayah.isNotEmpty) {
    sql += ' AND a.levelwilayah = :levelWilayah';
  }
  if (statusKeaktifan.isNotEmpty) {
    sql += ' AND a.statuskeaktifan = :statusKeaktifan';
  } else {
    sql += ' AND a.statuskeaktifan > 0';
  }
  if (idKota.isNotEmpty) {
    sql += ' AND a.idkabupaten = :idKota';
  }
  if (idKecamatan.isNotEmpty) {
    sql += ' AND a.idkecamatan = :idKecamatan';
  }
  sql += ' GROUP BY a.idkabupaten, a.idkecamatan, a.idkelurahan';
  sql += ' ORDER BY b.kota, b.kecamatan ';
  final params = {
    'levelAnggota': levelAnggota,
    'levelWilayah': levelWilayah,
    'statusKeaktifan': statusKeaktifan,
    'idKota': idKota,
    'idKecamatan': idKecamatan,
    'idKelurahan': idKelurahan,
  };
  final result = await db.executeQuery(QueryParam(query: sql, params: params));

  final jo = BaseResponse(success: true, message: 'berhasil').toJson();

  jo['data'] = result.rows.map((e) => e.assoc()).toList();

  return Response.json(body: jo);
}
