import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class Base64ImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'base64image';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final base64Str = embedContext.node.value.data as String;
    try {
      final bytes = base64Decode(base64Str);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Image.memory(bytes, fit: BoxFit.contain),
      );
    } catch (_) {
      return const Icon(Icons.broken_image, size: 48, color: Colors.grey);
    }
  }
}
