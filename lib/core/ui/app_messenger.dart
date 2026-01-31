import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey =
GlobalKey<ScaffoldMessengerState>();

void showBanner(String title, String message) {
  final ctx = messengerKey.currentContext;
  if (ctx == null) return;

  messengerKey.currentState?.hideCurrentSnackBar();
  messengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text("$title\n$message"),
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    ),
  );
}