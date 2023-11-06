import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart' as cors;

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
  final handler2 =
      Cascade().add(createStaticFileHandler()).add(handler).handler.use(
          fromShelfMiddleware(
            cors.corsHeaders(
              headers: {
                cors.ACCESS_CONTROL_ALLOW_ORIGIN: '*',
              },
            ),
          ),
        );
  return serve(handler2, ip, port);
}
