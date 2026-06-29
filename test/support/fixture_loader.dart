import 'dart:convert';
import 'dart:io';

Future<dynamic> loadJsonFixture(String name) async {
  final source = await File('test/fixtures/$name').readAsString();
  return jsonDecode(source);
}
