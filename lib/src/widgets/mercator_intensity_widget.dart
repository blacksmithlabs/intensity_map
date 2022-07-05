import 'dart:math';
import 'dart:ui' as ui show Image;

import 'package:flat_map/src/helpers/coordinate.dart';
import 'package:flat_map/src/helpers/intensity_map.dart';
import 'package:flat_map/src/shapes/sun_painter.dart';
import 'package:flat_map/src/widgets/base_intensity_widget.dart';
import 'package:flutter/material.dart';

class MercatorIntensityWidget extends StatelessWidget {
  final imagePath = 'assets/maps/mercator-projection.jpg';
  final double step;

  const MercatorIntensityWidget({
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

    // Calculate the lat/long to pixel conversion ratio
    final dlat = size.height / 180.0; // -90 to 90
    final dlong = size.width / 360.0; // -180 to 180

    Offset toOffset(double latitude, double longitude) {
      return Offset(
        (longitude + 180.0) * dlong,
        (latitude + 90.0) * dlat,
      );
    }

    // Paint the map
    final dr = max(dlat, dlong);
    // TODO can we convert this to a shape somehow?
    for (var pt in map) {
      final offset = toOffset(pt.latitude, pt.longitude);
      final intensity = 1 - max(0, pt.normalizeIntensity());

      if (intensity == 1) continue;

      final paint = Paint()
        ..color = Colors.black.withAlpha((255 * intensity).ceil());

      canvas.drawCircle(offset, dr, paint);
    }

    SunPainter.paint(
      canvas,
      toOffset(sunCoord.latitude, sunCoord.longitude),
    );

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
