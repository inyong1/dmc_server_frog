import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  final str = await File('./public/index.html').readAsString();
  return Response.bytes(body: utf8.encode(str), headers: {
    HttpHeaders.contentTypeHeader: 'text/html; charset=utf-8',
  });
}
