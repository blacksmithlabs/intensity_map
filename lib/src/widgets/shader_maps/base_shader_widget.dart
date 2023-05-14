import 'dart:async';
import 'dart:ui' as ui;

import 'package:flat_map/src/helpers/astronomy.dart';
import 'package:flat_map/src/helpers/coordinate.dart';
import 'package:flat_map/src/shapes/sun_painter.dart';
import 'package:flat_map/src/widgets/scaled_layout_builder_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:vector_math/vector_math.dart';

typedef CoordinateCoverter = Offset Function(double latitude, double longitude);

typedef CoordinateConverterBuilder
    = Offset Function(double latitude, double longitude) Function(
  Size canvasSize,
);

class BaseShaderWidget extends StatefulWidget {
  final String imagePath;
  final String shaderAsset;
  final CoordinateConverterBuilder toOffsetBuilder;
  final Duration? updateDuration;

  const BaseShaderWidget({
    super.key,
    required this.imagePath,
    required this.shaderAsset,
    required this.toOffsetBuilder,
    this.updateDuration = const Duration(seconds: 15),
  });

  @override
  State<BaseShaderWidget> createState() => _BaseShaderWidgetState();
}

class _BaseShaderWidgetState extends State<BaseShaderWidget> {
  GeodeticCoordinate? sunCoord;
  Size? mapSize;
  Timer? updateTimer;

  double latitudeDelta = 0.5;

  @override
  void initState() {
    super.initState();
    _loadSunCoords();
    _loadMapImage();
  }

  @override
  void dispose() {
    updateTimer?.cancel();
    super.dispose();
  }

  void _loadSunCoords() async {
    final now = DateTime.now();
    setState(() {
      sunCoord = getSubSolarPoint(now);
    });

    if (widget.updateDuration != null) {
      updateTimer = Timer.periodic(
        widget.updateDuration!,
        (timer) {
          final time = DateTime.now();
          setState(() {
            sunCoord = getSubSolarPoint(time);
          });
          // if (sunCoord != null) {
          //   if (sunCoord!.latitude <= -23.5) {
          //     latitudeDelta = 0.5;
          //   } else if (sunCoord!.latitude >= 23.5) {
          //     latitudeDelta = -0.5;
          //   }

          //   var nextLongitude = sunCoord!.longitude + 1;
          //   if (nextLongitude >= 180) {
          //     nextLongitude = -180;
          //   }

          //   setState(() {
          //     sunCoord = GeodeticCoordinate(
          //       sunCoord!.latitude + latitudeDelta,
          //       nextLongitude,
          //     );
          //   });
          // }
        },
      );
    }
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
    if (sunCoord == null || mapSize == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ScaledLayoutBuilder(
      toScale: mapSize!,
      builder: (context, constraints, size) {
        return ShaderBuilder(
          assetKey: widget.shaderAsset,
          (context, shader, child) => CustomPaint(
            size: size,
            foregroundPainter: ShaderPainter(
              shader: shader,
              sunCoord: sunCoord!,
              toOffset: widget.toOffsetBuilder(size),
            ),
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(widget.imagePath),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

class ShaderPainter extends CustomPainter {
  ui.FragmentShader shader;
  GeodeticCoordinate sunCoord;
  final CoordinateCoverter toOffset;

  ShaderPainter({
    required this.shader,
    required this.sunCoord,
    required this.toOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // resolution
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);

    // sun coord
    shader.setFloat(2, radians(sunCoord.longitude));
    shader.setFloat(3, radians(sunCoord.latitude));

    final paint = Paint()..shader = shader;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    SunPainter.paint(
      canvas,
      toOffset(sunCoord.latitude, sunCoord.longitude),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
