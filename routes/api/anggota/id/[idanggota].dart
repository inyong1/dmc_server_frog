import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dmc_server_frog/app_database.dart';
import 'package:dmc_server_frog/models/base_response.dart';

Future<Response> onRequest(RequestContext context, String idanggota) async {
  return switch (context.request.method) {
    HttpMethod.get => await onGetAnggotaById(context, idanggota),
    HttpMethod.post => await _updateAnggota(context, idanggota),
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
      'select a.*, b.kecamatan, b.kota, b.kodepropinsi, b.kodekota, b.kodekecamatan,c.kelurahan';
  sql += ' FROM anggota a';
  sql +=
      ' LEFT JOIN masterkecamatan b ON a.idkecamatan = b.idkecamatan AND a.idkabupaten = b.idkota';
  sql += ' LEFT JOIN masterkelurahan c ON a.idkelurahan = c.idkelurahan';
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

Future<Response> _updateAnggota(
    RequestContext context, String idAnggota) async {
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
  final hp = formData.fields['hp'] ?? '';
  final idkelurahan = formData.fields['idkelurahan'] ?? '';
  final hobi = formData.fields['hobi'] ?? '';
  final usaha = formData.fields['usaha'] ?? '';

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

  var sqlInto =
      'UPDATE anggota SET barcode=:barcode,namaanggota=:namaanggota,idkabupaten=:idkabupaten,';
  sqlInto +=
      ' idkecamatan=:idkecamatan,tempattanggallahir=:tempattanggallahir,level=:level,';
  sqlInto += 'levelwilayah=:levelwilayah,jabatan=:jabatan, alamat=:alamat,';
  sqlInto +=
      ' ukuranbaju=:ukuranbaju, hp=:hp, hobi=:hobi, usaha=:usaha,idkelurahan=:idkelurahan';
  sqlInto += ' WHERE idanggota=:idanggota';

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
    'hp': hp,
    'hobi': hobi,
    'usaha': usaha,
    'idanggota': idAnggota,
    'idkelurahan': idkelurahan.isEmpty ? null : idkelurahan,
  };
  final result =
      await db.executeQuery(QueryParam(query: sqlInto, params: params));
  if (result.affectedRows < BigInt.one) {
    return Response.json(
        statusCode: HttpStatus.notModified,
        body: BaseResponse(message: 'Gagal input data'));
  }

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
    var sql = 'UPDATE anggota SET ktp = :ktp WHERE idanggota = :idanggota';
    params = {'ktp': file.uri.pathSegments.last, 'idanggota': idAnggota};
    db.executeQuery(QueryParam(query: sql, params: params));
  }
  if (fotoBytes != null) {
    final file =
        File('${dir.path}/foto_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final ioSink = file.openWrite()..add(fotoBytes);
    await ioSink.flush();
    await ioSink.close();
    var sql = 'UPDATE anggota SET foto = :foto WHERE idanggota = :idanggota';
    params = {'foto': file.uri.pathSegments.last, 'idanggota': idAnggota};
    db.executeQuery(QueryParam(query: sql, params: params));
  }
  if (fotoBuktiBayar != null) {
    final file = File(
        '${dir.path}/buktibayar_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final ioSink = file.openWrite()..add(fotoBuktiBayar);
    await ioSink.flush();
    await ioSink.close();
    var sql =
        'UPDATE anggota SET buktibayar = :buktibayar WHERE idanggota = :idanggota';
    params = {'buktibayar': file.uri.pathSegments.last, 'idanggota': idAnggota};
    db.executeQuery(QueryParam(query: sql, params: params));
  }

  final jo = BaseResponse(success: true, message: 'berhasil').toJson();
  jo['idanggota'] = idAnggota;
  return Response.json(body: jo);
}
