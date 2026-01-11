import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class TumblingE extends StatelessWidget {
  final String direction;
  final double blurLevel;

  const TumblingE({
    Key? key,
    required this.direction,
    required this.blurLevel,
  }) : super(key: key);

  double _getRotation() {
    switch (direction) {
      case 'right':
        return 0;
      case 'down':
        return 90;
      case 'left':
        return 180;
      case 'up':
        return 270;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _getRotation() * (3.14159 / 180),
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blurLevel,
          sigmaY: blurLevel,
        ),
        child: const Text(
          'E',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: Colors.black,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}