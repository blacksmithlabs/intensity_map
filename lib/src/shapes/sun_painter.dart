import 'package:flutter/material.dart';
import 'package:flutter_shapes/flutter_shapes.dart';

class SunPainter {
  static paint(Canvas canvas, Offset coord) {
    // Paint the rays
    var shapes = Shapes(
      canvas: canvas,
      radius: 15.0,
      center: coord,
      angle: 0,
      paint: Paint()..color = Colors.deepOrange,
    );

    shapes.drawType(ShapeType.Star8);

    // Paint the sun
    canvas.drawCircle(coord, 10.0, Paint()..color = Colors.deepOrange);
    canvas.drawCircle(coord, 7.75, Paint()..color = Colors.amber);
  }
}
