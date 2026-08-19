import 'package:flutter/material.dart';

/// Shows the app's unified snackbar (styling comes from
/// [AppTheme]'s `snackBarTheme`) with its text centered — the one thing
/// the shared theme can't do on its own, since `content` is an arbitrary
/// widget passed in at each call site.
class AppSnackBar {
  AppSnackBar._();

  static void show(BuildContext context, String message, {Duration? duration}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }
}
