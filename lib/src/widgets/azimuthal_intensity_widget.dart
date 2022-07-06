import 'dart:math';
import 'dart:ui' as ui show Image;

import 'package:flat_map/src/helpers/coordinate.dart';
import 'package:flat_map/src/helpers/intensity_map.dart';
import 'package:flat_map/src/helpers/intensity_path.dart';
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
      toOffsetBuilder: (size) {
        final center = Offset(size.width, size.height) / 2;
        final dlat = size.height / 180.0 / 2; // -90 to 90, use as radius

        return (latitude, longitude) {
          final long = radians(-longitude + 90);
          final lat = (-latitude + 90) * dlat;

          return center + Offset(cos(long) * lat, sin(long) * lat);
        };
      },
    );
  }
}

// TODO convert to a standardized base painter

class _IntensityPainter extends CustomPainter {
  final GeodeticCoordinate sunCoord;
  final GeodeticCoordinate moonCoord;
  final ui.Image moonImage;
  final double step;

  _IntensityPainter(this.sunCoord, this.moonCoord, this.moonImage, this.step);

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the lat/long to pixel conversion ratio
    final dlat = size.height / 180.0 / 2; // -90 to 90, use as radius

    final map = IntensityMap(sunCoord, 0.5, 0.5);

    final center = Offset(size.width, size.height) / 2;

    Offset toOffset(double latitude, double longitude) {
      final dlat = size.height / 180.0 / 2; // -90 to 90, use as radius
      final long = radians(-longitude + 90);
      final lat = (-latitude + 90) * dlat;

      return center + Offset(cos(long) * lat, sin(long) * lat);
    }

    final paths = IntensityPath.getPaths(sunCoord, map);
    for (var path in paths) {
      if (path.intensity == LightIntensity.daylight) continue;

      final startCoord = path.coordinates.first;
      final startOffset = toOffset(
        startCoord.latitude,
        startCoord.longitude,
      );
      final uiPath = Path()..moveTo(startOffset.dx, startOffset.dy);
      for (var coords in path.coordinates) {
        final offset = toOffset(coords.latitude, coords.longitude);
        uiPath.lineTo(offset.dx, offset.dy);
      }

      canvas.drawPath(
        uiPath,
        Paint()..color = Colors.black.withAlpha(path.intensity.toAlpha()),
      );
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
