import 'package:flutter/material.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/app_colors.dart';

/// Shows a SnackBar for [error], reading the message from [AppException]
/// when available instead of falling back to a raw `Exception.toString()`
/// (which used to leak the `"Exception: "` prefix straight to users).
void showAppErrorSnackBar(BuildContext context, Object error) {
  final message = error is AppException ? error.message : 'Đã xảy ra lỗi, vui lòng thử lại.';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: kError),
  );
}

/// Shows a success SnackBar, matching the app's existing green/secondary styling.
void showAppSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: kSecondary),
  );
}
