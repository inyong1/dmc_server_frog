// ignore_for_file: public_member_api_docs

import 'dart:convert';

import 'package:crypto/crypto.dart';

extension StringExt on String {
  String get sha256Hash {
    // Convert the input string to a list of bytes
    final inputBytes = utf8.encode(this);

    // Create an instance of the SHA-256 hasher
    final hash = sha256.convert(inputBytes);

    // Convert the hash bytes to a hexadecimal string

    return hash.toString();
  }
}
