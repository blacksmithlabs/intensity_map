import 'dart:ui' as ui show Image;

import 'package:flat_map/src/helpers/coordinate.dart';
import 'package:flat_map/src/helpers/intensity_map.dart';
import 'package:flat_map/src/helpers/intensity_path.dart';
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
      toOffsetBuilder: (size) {
        final dlat = size.height / 180.0; // -90 to 90
        final dlong = size.width / 360.0; // -180 to 180

        return (double latitude, double longitude) {
          return Offset(
            (longitude + 180.0) * dlong,
            (-latitude + 90.0) * dlat, // Flip N/S
          );
        };
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
    // Calculate the lat/long to pixel conversion ratio
    final dlat = size.height / 180.0; // -90 to 90
    final dlong = size.width / 360.0; // -180 to 180

    final map = IntensityMap(sunCoord, 0.5, 0.5);

    Offset toOffset(double latitude, double longitude) {
      return Offset(
        (longitude + 180.0) * dlong,
        (-latitude + 90.0) * dlat, // Flip N/S
      );
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
