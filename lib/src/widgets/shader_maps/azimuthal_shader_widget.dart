import 'dart:math';

import 'package:flat_map/src/widgets/shader_maps/base_shader_widget.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart';

class AzimuthalShaderWidget extends StatelessWidget {
  final imagePath = 'assets/maps/azimuthal-projection.jpg';
  final shaderAsset = 'shaders/azimuthal_intensity.frag';

  const AzimuthalShaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShaderWidget(
      imagePath: imagePath,
      shaderAsset: shaderAsset,
      toOffsetBuilder: (size) {
        final center = Offset(size.width, size.height) / 2;
        final dlat = size.height / 360.0; // -90 to 90, use as radius

        return (latitude, longitude) {
          final long = radians(-longitude + 90);
          final lat = (-latitude + 90) * dlat;

          return center + Offset(cos(long) * lat, sin(long) * lat);
        };
      },
    );
  }
}
