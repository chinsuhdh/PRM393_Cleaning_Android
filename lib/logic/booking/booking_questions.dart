import 'dart:convert';

bool isQuestionAnswered(dynamic value) {
  if (value == null || value == '') return false;
  if (value is Iterable && value.isEmpty) return false;
  return true;
}

List<Map<String, dynamic>> parseBookingQuestions(Map<String, dynamic>? service) {
  final raw = service?['bookingFormSchema'];
  final schema = raw is String ? jsonDecode(raw) : raw;
  if (schema is! Map || schema['questions'] is! List) return const [];
  return List<Map<String, dynamic>>.from(schema['questions'] as List);
}
