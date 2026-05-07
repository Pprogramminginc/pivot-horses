import 'package:flutter/material.dart';

class RenderLayer {
  const RenderLayer({
    required this.slot,
    required this.label,
    required this.assetPath,
    this.tintColor,
    this.opacity = 1,
    this.blendMode = BlendMode.modulate,
  });

  final String slot;
  final String label;
  final String assetPath;
  final Color? tintColor;
  final double opacity;
  final BlendMode blendMode;
}
