import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  const html = '''
<html>
<body>
<center>
<h1>
404 not found
</h1>
<center>
</body>
</html>
''';
  return Response(
    statusCode: HttpStatus.notFound,
    body: html,
    headers: {'Content-Type': 'text/html'},
  );
}
