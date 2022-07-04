import 'dart:math';

import 'package:flat_map/src/coordinate/coordinate.dart';
import 'package:flat_map/src/map/intensity_map.dart';
import 'package:flat_map/src/shapes/sun_painter.dart';
import 'package:flutter/material.dart';

class MercatorIntensityWidget extends StatefulWidget {
  const MercatorIntensityWidget({Key? key}) : super(key: key);

  @override
  State<MercatorIntensityWidget> createState() =>
      _MercatorIntensityWidgetState();
}

class _MercatorIntensityWidgetState extends State<MercatorIntensityWidget> {
  @override
  Widget build(BuildContext context) {
    const sunCoord = GeodeticCoordinate(22.88, 168.1);
    const step = 1.0;

    return CustomPaint(
      foregroundPainter: _IntensityPainter(IntensityMap(sunCoord, step)),
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/maps/mercator-projection.jpg'),
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}

class _IntensityPainter extends CustomPainter {
  IntensityMap map;

  _IntensityPainter(this.map);

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the lat/long to pixel conversion ratio
    var dlat = size.height / 180.0; // -90 to 90
    var dlong = size.width / 360.0; // -180 to 180

    double latToY(double latitude) => size.height - ((latitude + 90.0) * dlat);
    double longToX(double longitude) => (longitude + 180.0) * dlong;

    var sunX = longToX(map.sunCoord.longitude);
    var sunY = latToY(map.sunCoord.latitude);
    SunPainter.paint(canvas, Offset(sunX, sunY));

    // Paint the map
    var radius = max(dlat, dlong);
    // TODO can we convert this to a shape somehow?
    for (var pt in map) {
      var x = longToX(pt.longitude);
      var y = latToY(pt.latitude);

      // var normalizedIntensity = (1 + (pt.intensity > 0 ? 1 : pt.intensity)) / 2;
      // var intensity = 1 - max(0, (1 + pt.intensity) / 2);
      var intensity = 1 - max(0, pt.normalizeIntensity());

      var paint = Paint()
        ..color = Colors.black.withAlpha((255 * intensity).ceil());

      canvas.drawCircle(Offset(x + radius, y + radius), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
