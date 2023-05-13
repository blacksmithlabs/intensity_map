import 'dart:async';
import 'dart:ui' as ui;

import 'package:flat_map/src/helpers/coordinate.dart';
import 'package:flat_map/src/shapes/sun_painter.dart';
import 'package:flat_map/src/widgets/scaled_layout_builder_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:vector_math/vector_math.dart';

class MercatorShaderWidget extends StatelessWidget {
  final imagePath = 'assets/maps/mercator-projection.jpg';

  const MercatorShaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return _MercatorRenderer(imagePath: imagePath);
  }
}

class _MercatorRenderer extends StatefulWidget {
  final String imagePath;

  const _MercatorRenderer({super.key, required this.imagePath});

  @override
  State<_MercatorRenderer> createState() => _MercatorRendererState();
}

class _MercatorRendererState extends State<_MercatorRenderer> {
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
    setState(() {
      sunCoord = const GeodeticCoordinate(22.44, -114.32);
    });

    updateTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
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
          assetKey: 'shaders/intensity.frag',
          (context, shader, child) => CustomPaint(
            size: size,
            foregroundPainter: ShaderPainter(
              shader: shader,
              sunCoord: sunCoord!,
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

  ShaderPainter({required this.shader, required this.sunCoord});

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the lat/long to pixel conversion ratio
    final dlat = size.height / 180.0; // -90 to 90
    final dlong = size.width / 360.0; // -180 to 180

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
      Offset(
        (sunCoord.longitude + 180.0) * dlong,
        (-sunCoord.latitude + 90.0) * dlat, // Flip N/S
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
