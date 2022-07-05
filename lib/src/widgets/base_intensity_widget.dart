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

class BaseIntensityWidget extends StatefulWidget {
  final String imagePath;
  final IntensityWidgetPainterBuilder painterBuilder;

  const BaseIntensityWidget({
    Key? key,
    required this.imagePath,
    required this.painterBuilder,
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
      sunCoord = const GeodeticCoordinate(-22.52, 70.02);
      moonCoord = const GeodeticCoordinate(-12.27, 129.77);
    });

    updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
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
    moonImage = await decodeImageFromList(imageData.buffer.asUint8List());
  }

  void _loadMapImage() async {
    final imageData = await rootBundle.load(widget.imagePath);
    final mapImage = await decodeImageFromList(imageData.buffer.asUint8List());
    mapSize = Size(mapImage.width.toDouble(), mapImage.height.toDouble());
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
