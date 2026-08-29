import 'package:flutter/material.dart';

String colorToHex(Color color) {
  final int argb = color.toARGB32();
  return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

({int r, int g, int b}) colorToRgb(Color color) {
  return (
    r: (color.r * 255).round().clamp(0, 255),
    g: (color.g * 255).round().clamp(0, 255),
    b: (color.b * 255).round().clamp(0, 255),
  );
}
