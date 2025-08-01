import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum SnackBarIntent { success, error, warning, info }

void showIntentionSnackBar(
  BuildContext context,
  String message, {
  SnackBarIntent intent = SnackBarIntent.info,
  Duration duration = const Duration(seconds: 2),
}) {
  SnackBar snackBar;
  switch (intent) {
    case SnackBarIntent.success:
      snackBar = AppTheme.successSnackBar(message: message);
      break;
    case SnackBarIntent.warning:
      snackBar = AppTheme.warningSnackBar(message: message);
      break;
    case SnackBarIntent.error:
      snackBar = AppTheme.errorSnackBar(message: message);
      break;
    case SnackBarIntent.info:
    default:
      snackBar = AppTheme.infoSnackBar(message: message);
      break;
  }
  
  // Override duration if needed
  if (duration != const Duration(seconds: 2)) {
    snackBar = SnackBar(
      content: snackBar.content,
      backgroundColor: snackBar.backgroundColor,
      behavior: snackBar.behavior,
      shape: snackBar.shape,
      margin: snackBar.margin,
      action: snackBar.action,
      duration: duration,
    );
  }
  
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
} 