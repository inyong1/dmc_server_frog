import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dmc_server_frog/app_database.dart';
import 'package:dmc_server_frog/models/base_response.dart';
import 'package:dmc_server_frog/safe_convert.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => await _onGet(context),
    HttpMethod.post => await _onPost(context),
    _ => Response.json(
        statusCode: HttpStatus.badRequest,
        body: BaseResponse(message: 'Method not allwed'),
      ),
  };
}

Future<Response> _onGet(RequestContext context) async {
  final queryParam = context.request.uri.queryParameters;
  final page = asInt(queryParam, 'page', defaultValue: 1);
  final search = asString(queryParam, 'search');
  const limit = 100;
  final offset = (page - 1) * limit;

  final db = context.read<AppDatabase>();

  var sql = 'select a.namaanggota, a.idanggota, a.foto, a.level';
  sql += ' FROM anggota a';
  sql += ' WHERE a.statuskeaktifan = 1 AND a.namaanggota LIKE :search';
  final result0 = await db.executeQuery(
    QueryParam(query: sql, params: {'search': '%$search%'}),
  );

  if (result0.numOfRows == 0) {
    return Response.json(body: BaseResponse(message: 'data tidak ditemukan'));
  }
  final data = <String, dynamic>{'total_data': result0.numOfRows};

  sql += ' ORDER BY a.namaanggota ASC LIMIT $limit OFFSET $offset';

  final result = await db.executeQuery(
    QueryParam(query: sql, params: {'search': '%$search%'}),
  );

  final uri = context.request.uri;
  data['anggota'] = result.rows.map((e) {
    final map = e.assoc();
    final foto = map['foto'] ?? '';
    if (foto.isNotEmpty) {
      map['foto'] =
          "${uri.scheme}://${uri.host}:${uri.port}/images/${map['idanggota']}/$foto";
    }
    return map;
  }).toList();

  final jo = BaseResponse(success: true, message: 'berhasil').toJson();
  jo['data'] = data;

  return Response.json(body: jo);
}

/// Digunakan untuk menambah anggota baru
Future<Response> _onPost(RequestContext context) async {
  final formData = await context.request.formData();
  final idKabupaten = formData.fields['idkota'] ?? '';
  final idKecamatan = formData.fields['idkecamatan'] ?? '';
  final nama = formData.fields['nama'] ?? '';
  final jabatan = formData.fields['jabatan'] ?? '';
  final ttl = formData.fields['ttl'] ?? '';
  final level = formData.fields['level'] ?? '';
  final levelWilayah = formData.fields['levelwilayah'] ?? '';
  final alamat = formData.fields['alamat'] ?? '';
  final ukuranBaju = formData.fields['ukuranbaju'] ?? '';

  // ignore: omit_local_variable_types
  final List<int>? ktpBytes = await formData.files['ktp']?.readAsBytes();
  // ignore: omit_local_variable_types
  final List<int>? fotoBytes = await formData.files['foto']?.readAsBytes();
  final List<int>? fotoBuktiBayar =
      await formData.files['buktibayar']?.readAsBytes();

// pastikan data yang diinput sudah bener
  if (idKabupaten.isEmpty || idKecamatan.isEmpty || nama.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: BaseResponse(message: 'Bad request'),
    );
  }

  final barcode = DateTime.now().millisecondsSinceEpoch.toString();

  final db = context.read<AppDatabase>();

  var sql =
      'INSERT INTO anggota(barcode,namaanggota,idkabupaten, idkecamatan,tempattanggallahir,level,levelwilayah,jabatan, alamat, ukuranbaju)';
  sql +=
      'VALUES(:barcode,:namaanggota,:idkabupaten,:idkecamatan,:tempattanggallahir,:level,:levelwilayah,:jabatan,:alamat,:ukuranbaju)';
  var params = {
    'barcode': barcode,
    'namaanggota': nama,
    'idkabupaten': idKabupaten,
    'idkecamatan': idKecamatan,
    'tempattanggallahir': ttl,
    'jabatan': jabatan,
    'level': level,
    'levelwilayah': levelWilayah,
    'alamat': alamat,
    'ukuranbaju': ukuranBaju,
  };
  final result = await db.executeQuery(QueryParam(query: sql, params: params));

  if (result.affectedRows < BigInt.one) {
    return Response.json(
        statusCode: HttpStatus.notModified,
        body: BaseResponse(message: 'Gagal input data'));
  }
  final idAnggota = result.lastInsertID.toInt().toString();

  var savedKtpFileName = '';
  var savedPhotoFileName = '';
  var savedBuktiBayarFileName = '';

  final dir = Directory('./public/images/$idAnggota');
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }

  /// simpan file jika ada
  if (ktpBytes != null) {
    final file =
        File('${dir.path}/ktp_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final IOSink ioSink = file.openWrite()..add(ktpBytes);
    await ioSink.flush();
    await ioSink.close();
    savedKtpFileName = file.uri.pathSegments.last;
  }
  if (fotoBytes != null) {
    final file =
        File('${dir.path}/foto_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final ioSink = file.openWrite()..add(fotoBytes);
    await ioSink.flush();
    await ioSink.close();
    savedPhotoFileName = file.uri.pathSegments.last;
  }
  if (fotoBuktiBayar != null) {
    final file = File(
        '${dir.path}/buktibayar_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final ioSink = file.openWrite()..add(fotoBuktiBayar);
    await ioSink.flush();
    await ioSink.close();
    savedBuktiBayarFileName = file.uri.pathSegments.last;
  }
  sql = 'UPDATE anggota SET ktp = :ktp, foto = :foto, buktibayar = :buktibayar WHERE idanggota = :idanggota';
  params = {
    'ktp': savedKtpFileName,
    'foto': savedPhotoFileName,
    'buktibayar': savedBuktiBayarFileName,
    'idanggota': idAnggota,
  };
  db.executeQuery(QueryParam(query: sql, params: params));
  final jo = BaseResponse(success: true, message: 'berhasil').toJson();
  jo['idanggota'] = idAnggota;
  return Response.json(body: jo);
}
