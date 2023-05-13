import 'dart:async';
import 'dart:ui' as ui show Image;

import 'package:flat_map/src/helpers/astronomy.dart';
import 'package:flat_map/src/helpers/coordinate.dart';
import 'package:flat_map/src/helpers/intensity_map.dart';
import 'package:flat_map/src/helpers/intensity_path.dart';
import 'package:flat_map/src/shapes/sun_painter.dart';
import 'package:flat_map/src/widgets/scaled_layout_builder_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef CoordinateCoverter = Offset Function(double latitude, double longitude);

typedef CoordinateConverterBuilder
    = Offset Function(double latitude, double longitude) Function(
  Size canvasSize,
);

class BaseIntensityWidget extends StatefulWidget {
  final String imagePath;
  final CoordinateConverterBuilder toOffsetBuilder;

  const BaseIntensityWidget({
    Key? key,
    required this.imagePath,
    required this.toOffsetBuilder,
  }) : super(key: key);

  @override
  State<BaseIntensityWidget> createState() => _BaseIntensityWidgetState();
}

class _BaseIntensityWidgetState extends State<BaseIntensityWidget> {
  final moonImagePath = 'assets/images/full-moon.png';

  GeodeticCoordinate? sunCoord;
  GeodeticCoordinate? moonCoord;
  ui.Image? moonImage;
  Size? mapSize;

  Timer? updateTimer;

  double latitudeDelta = 0.5;

  @override
  void initState() {
    super.initState();
    _loadSunMoonCoords();
    _loadMoonImage();
    _loadMapImage();
  }

  @override
  void dispose() {
    updateTimer?.cancel();
    super.dispose();
  }

  void _loadSunMoonCoords() async {
    final now = DateTime.now();
    // final now = DateTime.utc(2004, 1, 1);
    setState(() {
      sunCoord = getSubSolarPoint(now);
      moonCoord = getSubLunarPoint(now);
    });

    updateTimer = Timer.periodic(
      const Duration(seconds: 15),
      (timer) {
        final time = DateTime.now();
        setState(() {
          sunCoord = getSubSolarPoint(time);
          moonCoord = getSubLunarPoint(time);
        });
      },
    );
    // updateTimer = Timer.periodic(const Duration(milliseconds: 5), (timer) {
    //   if (sunCoord != null) {
    //     if (sunCoord!.latitude <= -23.5) {
    //       latitudeDelta = 0.5;
    //     } else if (sunCoord!.latitude >= 23.5) {
    //       latitudeDelta = -0.5;
    //     }

    //     var nextLongitude = sunCoord!.longitude + 1;
    //     if (nextLongitude >= 180) {
    //       nextLongitude = -180;
    //     }

    //     setState(() {
    //       sunCoord = GeodeticCoordinate(
    //         sunCoord!.latitude + latitudeDelta,
    //         nextLongitude,
    //       );
    //     });
    //   }
    // });
  }

  void _loadMoonImage() async {
    final imageData = await rootBundle.load(moonImagePath);
    final data = await decodeImageFromList(imageData.buffer.asUint8List());
    setState(() {
      moonImage = data;
    });
  }

  void _loadMapImage() async {
    final imageData = await rootBundle.load(widget.imagePath);
    final mapImage = await decodeImageFromList(imageData.buffer.asUint8List());
    final data = Size(mapImage.width.toDouble(), mapImage.height.toDouble());
    setState(() {
      mapSize = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (sunCoord == null ||
        moonCoord == null ||
        moonImage == null ||
        mapSize == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ScaledLayoutBuilder(
      toScale: mapSize!,
      builder: (context, constraints, size) {
        return CustomPaint(
          foregroundPainter: _IntensityPainter(
            sunCoord!,
            moonCoord!,
            moonImage!,
            widget.toOffsetBuilder(size),
          ),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(widget.imagePath),
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
  final GeodeticCoordinate sunCoord;
  final GeodeticCoordinate moonCoord;
  final ui.Image moonImage;
  final CoordinateCoverter toOffset;

  _IntensityPainter(
      this.sunCoord, this.moonCoord, this.moonImage, this.toOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final map = IntensityMap(sunCoord, 0.5, 0.5);
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
        toOffset != old.toOffset;
  }
}
