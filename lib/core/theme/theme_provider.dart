import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mặc định khi mở app sẽ tuân theo cài đặt của hệ thống máy
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});