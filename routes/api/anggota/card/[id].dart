import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dmc_server_frog/models/base_response.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.post => await _onPost(context, id),
    _ => Response.json(
        statusCode: HttpStatus.badRequest,
        body: BaseResponse(message: 'Method not allwed'),
      ),
  };
}

Future<Response> _onPost(RequestContext context, String id) async {
  final formData = await context.request.formData();

  // ignore: omit_local_variable_types
  final List<int>? cardBytes = await formData.files['card']?.readAsBytes();
  var savedCardName = '';

  final dir = Directory('./public/images/$id');
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }

  /// simpan file jika ada
  if (cardBytes != null) {
    final file = File('${dir.path}/card.jpg');
    final IOSink ioSink = file.openWrite()..add(cardBytes);
    await ioSink.flush();
    await ioSink.close();
    savedCardName = file.uri.pathSegments.last;
  }

  final jo = BaseResponse(success: true, message: 'berhasil').toJson();
  final uri = context.request.uri;
  jo['data'] ="${uri.scheme}://${uri.host}:${uri.port}/images/$id/$savedCardName";
  return Response.json(body: jo);
}
