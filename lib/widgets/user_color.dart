import 'package:flutter/material.dart';

Color userColor(String uid) {
  final colors = [
    Colors.deepPurple,
    Colors.teal,
    Colors.orange,
    Colors.pink,
    Colors.indigo,
    Colors.green,
    Colors.red,
    Colors.cyan,
  ];
  final index = uid.codeUnits.fold(0, (a, b) => a + b) % colors.length;
  return colors[index];
}