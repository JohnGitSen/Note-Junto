import 'package:flutter/material.dart';

void buildSnackBar(
  BuildContext context,
  String message, {
  Duration duration = Durations.extralong4,
  Color backgroundColor = const Color.fromARGB(255, 226, 120, 116),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      backgroundColor: backgroundColor,
    ),
  );
}
