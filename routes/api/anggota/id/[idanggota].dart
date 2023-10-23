import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dmc_server_frog/app_database.dart';
import 'package:dmc_server_frog/models/base_response.dart';

Future<Response> onRequest(RequestContext context, String idanggota) async {
  return switch (context.request.method) {
    HttpMethod.get => await onGetAnggotaById(context, idanggota),
    _ => Response.json(
        statusCode: HttpStatus.badRequest,
        body: BaseResponse(message: 'Method not allwed'),
      ),
  };
}

Future<Response> onGetAnggotaById(
    RequestContext context, String idanggota) async {
  final db = context.read<AppDatabase>();

  var sql =
      'select a.*, b.kecamatan, b.kota, b.kodepropinsi, b.kodekota, b.kodekecamatan';
  sql += ' FROM anggota a';
  sql +=
      ' LEFT JOIN masterkecamatan b ON a.idkecamatan = b.idkecamatan AND a.idkabupaten = b.idkota';
  sql += ' WHERE a.idanggota = :idanggota LIMIT 1';
  final result = await db.executeQuery(
    QueryParam(query: sql, params: {'idanggota': idanggota}),
  );

  if (result.numOfRows == 0) {
    return Response.json(body: BaseResponse(message: 'data tidak ditemukan'));
  }
  final Map<String, dynamic> data = result.rows.first.assoc();

  var kodePropinsi = data['kodepropinsi'] as String;
  if (kodePropinsi.isEmpty) kodePropinsi = '-';
  var kodeKabupaten = data['kodekota'] as String;
  if (kodeKabupaten.isEmpty) kodeKabupaten = '-';
  var kodeKecamatan = data['kodekecamatan'] as String;
  if (kodeKecamatan.isEmpty) kodeKecamatan = '-';
  final id = (data['idanggota'] as String).padLeft(5, '0');

  data['nia'] = "DMC.$kodePropinsi.$kodeKabupaten.$kodeKecamatan.$id";

  final uri = context.request.uri;
  final foto = data['foto'] ?? '';
  if (foto.isNotEmpty) {
    data['foto'] =
        "${uri.scheme}://${uri.host}:${uri.port}/images/${data['idanggota']}/$foto";
  }
  final ktp = data['ktp'] ?? '';
  if (ktp.isNotEmpty) {
    data['ktp'] =
        "${uri.scheme}://${uri.host}:${uri.port}/images/${data['idanggota']}/$ktp";
  }
  final buktibayar = data['buktibayar'] ?? '';
  if (buktibayar.isNotEmpty) {
    data['buktibayar'] =
        "${uri.scheme}://${uri.host}:${uri.port}/images/${data['idanggota']}/$buktibayar";
  }
  final response = BaseResponse(message: 'Berhasil', success: true).toJson();
  response['data'] = data;
  return Response.json(body: response);
}
