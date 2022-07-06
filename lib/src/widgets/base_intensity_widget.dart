import 'dart:async';
import 'dart:ui' as ui show Image;

import 'package:flat_map/src/helpers/coordinate.dart';
import 'package:flat_map/src/widgets/scaled_layout_builder_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef IntensityWidgetPainterBuilder = CustomPainter Function(
  GeodeticCoordinate sunCoord,
  GeodeticCoordinate moonCoord,
  ui.Image moonImage,
);

typedef CoordinateConverterBuilder
    = Offset Function(double latitude, double longitude) Function(
  Size canvasSize,
);

class BaseIntensityWidget extends StatefulWidget {
  final String imagePath;
  final IntensityWidgetPainterBuilder painterBuilder;
  final CoordinateConverterBuilder toOffsetBuilder;

  const BaseIntensityWidget({
    Key? key,
    required this.imagePath,
    required this.painterBuilder,
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
    setState(() {
      sunCoord = const GeodeticCoordinate(22.44, -114.32);
      // sunCoord = const GeodeticCoordinate(0, 50);
      moonCoord = const GeodeticCoordinate(4.3, -38.98);
    });

    updateTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (sunCoord != null) {
        if (sunCoord!.latitude <= -23.5) {
          latitudeDelta = 0.5;
        } else if (sunCoord!.latitude >= 23.5) {
          latitudeDelta = -0.5;
        }

        var nextLongitude = sunCoord!.longitude + 1;
        if (nextLongitude >= 180) {
          nextLongitude = -180;
        }

        setState(() {
          sunCoord = GeodeticCoordinate(
            sunCoord!.latitude + latitudeDelta,
            nextLongitude,
          );
        });
      }
    });
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
          foregroundPainter: widget.painterBuilder(
            sunCoord!,
            moonCoord!,
            moonImage!,
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
