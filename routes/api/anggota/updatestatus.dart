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
  final statusKeaktifan = formData.fields['statuskeaktifan'] ?? '';
  final id = formData.fields['idanggota'] ?? '';
  final db = context.read<AppDatabase>();
  var sql =
      'UPDATE anggota SET statuskeaktifan = :statuskeaktifan WHERE idanggota = :idanggota';
  final params = {
    'statuskeaktifan': statusKeaktifan,
    'idanggota': id,
  };
  final dbResult =
      await db.executeQuery(QueryParam(query: sql, params: params));
  if (dbResult.affectedRows == 0) {
    return Response.json(
        body: BaseResponse(message: 'Gagal mengupdate status anggota'));
  }
  return Response.json(
      body: BaseResponse(success: true, message: 'Berhasil mengupdate data anggota'));
}
