import 'package:dart_frog/dart_frog.dart';
import 'package:dmc_server_frog/app_database.dart';

Handler middleware(Handler handler) {
  return (context) {
    /// before
    final response = handler
    .use(provider<AppDatabase>((c) => AppDatabase.instance))
    .use(requestLogger())
    .call(context);
    /// after
    return response;
  };
}
