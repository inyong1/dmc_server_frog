import 'package:dart_frog/dart_frog.dart';
import 'package:dmc_server_frog/app_database.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart' as cors;

Handler middleware(Handler handler) {
  return (context) {
    /// before
    final response = handler
        .use(provider<AppDatabase>((c) => AppDatabase.instance))
        .use(requestLogger())
        .use(
          fromShelfMiddleware(
            cors.corsHeaders(
              headers: {
                cors.ACCESS_CONTROL_ALLOW_ORIGIN: '*',
              },
            ),
          ),
        )
        .call(context);

    /// after
    return response;
  };
}
