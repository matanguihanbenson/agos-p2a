import 'package:flutter/material.dart';

extension SnackBarUtils on BuildContext {
  void showReplacingSnackBar(
    String message, {
    Color? backgroundColor,
    SnackBarBehavior? behavior,
    ShapeBorder? shape,
    Duration? duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).clearSnackBars();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: behavior ?? SnackBarBehavior.floating,
        shape:
            shape ??
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: duration ?? const Duration(seconds: 4),
        action: action,
      ),
    );
  }

  void showSuccessSnackBar(String message) {
    showReplacingSnackBar(message, backgroundColor: Colors.green);
  }

  void showErrorSnackBar(String message) {
    showReplacingSnackBar(message, backgroundColor: Colors.red);
  }

  void showInfoSnackBar(String message) {
    showReplacingSnackBar(
      message,
      backgroundColor: Theme.of(this).colorScheme.primary,
    );
  }
}
