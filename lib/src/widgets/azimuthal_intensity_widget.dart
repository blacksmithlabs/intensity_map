import 'dart:math';
import 'dart:ui' as ui show Image;

import 'package:flat_map/src/helpers/coordinate.dart';
import 'package:flat_map/src/helpers/intensity_map.dart';
import 'package:flat_map/src/shapes/sun_painter.dart';
import 'package:flat_map/src/widgets/base_intensity_widget.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import 'package:flutter/material.dart';

class AzimuthalIntensityWidget extends StatelessWidget {
  final imagePath = 'assets/maps/azimuthal-projection.jpg';
  final double step;

  const AzimuthalIntensityWidget({
    Key? key,
    this.step = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseIntensityWidget(
      imagePath: imagePath,
      painterBuilder: (sunCoord, moonCoord, moonImage) {
        return _IntensityPainter(
          sunCoord,
          moonCoord,
          moonImage,
          step,
        );
      },
    );
  }
}

class _IntensityPainter extends CustomPainter {
  final GeodeticCoordinate sunCoord;
  final GeodeticCoordinate moonCoord;
  final ui.Image moonImage;
  final double step;

  _IntensityPainter(this.sunCoord, this.moonCoord, this.moonImage, this.step);

  @override
  void paint(Canvas canvas, Size size) {
    final map = IntensityMap(sunCoord, step);

    final center = Offset(size.width, size.height) / 2;

    Offset toOffset(double latitude, double longitude) {
      final long = radians(longitude - 45);
      final lat = (latitude + 90);

      return center + Offset(cos(long) * lat, sin(long) * lat);
    }

    // Paint the map
    // TODO can we convert this to a shape somehow?
    for (var pt in map) {
      final offset = toOffset(pt.latitude, pt.longitude);
      final intensity = 1 - max(0, pt.normalizeIntensity());

      final paint = Paint()
        ..color = Colors.black.withAlpha((255 * intensity).ceil());

      final spacing = pi * (pt.latitude + 90) / 270;
      canvas.drawCircle(offset, spacing, paint);
    }

    // Draw sun
    SunPainter.paint(
      canvas,
      toOffset(sunCoord.latitude, sunCoord.longitude),
    );

    // Draw moon
    canvas.drawImage(
      moonImage,
      toOffset(moonCoord.latitude, moonCoord.longitude),
      Paint(),
    );
  }

  @override
  bool shouldRepaint(_IntensityPainter old) {
    return sunCoord != old.sunCoord ||
        moonCoord != old.moonCoord ||
        step != old.step;
  }
}
