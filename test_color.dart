
import 'package:flutter/material.dart';

void main() {
  final List<Color> _themeColors = [
    const Color(0xFF0052CC), 
  ];
  for (final color in _themeColors) {
    int v = color.value;
    print(v);
  }
}
