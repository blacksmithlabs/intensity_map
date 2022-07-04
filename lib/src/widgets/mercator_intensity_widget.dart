import 'dart:math';

import 'package:flat_map/src/coordinate/coordinate.dart';
import 'package:flat_map/src/map/intensity_map.dart';
import 'package:flat_map/src/shapes/sun_painter.dart';
import 'package:flat_map/src/widgets/scaled_layout_builder_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MercatorIntensityWidget extends StatefulWidget {
  const MercatorIntensityWidget({Key? key}) : super(key: key);

  @override
  State<MercatorIntensityWidget> createState() =>
      _MercatorIntensityWidgetState();
}

class _MercatorIntensityWidgetState extends State<MercatorIntensityWidget> {
  final imagePath = 'assets/maps/mercator-projection.jpg';

  double step = 1.0;
  GeodeticCoordinate? sunCoord;
  Size? imageSize;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        sunCoord = const GeodeticCoordinate(-22.52, 70.02);
      });
    });

    _loadImageProperties();
  }

  void _loadImageProperties() async {
    final image = await rootBundle.load(imagePath);
    final decodedImage = await decodeImageFromList(image.buffer.asUint8List());
    imageSize = Size(
      decodedImage.width.toDouble(),
      decodedImage.height.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (sunCoord == null || imageSize == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ScaledLayoutBuilder(
      toScale: imageSize!,
      builder: (context, constraints, size) {
        return CustomPaint(
          foregroundPainter: _IntensityPainter(IntensityMap(sunCoord!, step)),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.fill,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IntensityPainter extends CustomPainter {
  IntensityMap map;

  _IntensityPainter(this.map);

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the lat/long to pixel conversion ratio
    final dlat = size.height / 180.0; // -90 to 90
    final dlong = size.width / 360.0; // -180 to 180

    Offset toOffset(double latitude, double longitude) {
      return Offset(
        (longitude + 180.0) * dlong,
        (latitude + 90.0) * dlat,
      );
    }

    SunPainter.paint(
      canvas,
      toOffset(map.sunCoord.latitude, map.sunCoord.longitude),
    );

    // Paint the map
    final dr = max(dlat, dlong);
    // TODO can we convert this to a shape somehow?
    for (var pt in map) {
      final offset = toOffset(pt.latitude, pt.longitude);
      final intensity = 1 - max(0, pt.normalizeIntensity());

      final paint = Paint()
        ..color = Colors.black.withAlpha((255 * intensity).ceil());

      canvas.drawCircle(offset, dr, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
