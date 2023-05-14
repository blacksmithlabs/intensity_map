import 'package:flat_map/src/widgets/shader_maps/base_shader_widget.dart';
import 'package:flutter/material.dart';

class MercatorShaderWidget extends StatelessWidget {
  final imagePath = 'assets/maps/mercator-projection.jpg';
  final shaderAsset = 'shaders/mercator_intensity.frag';

  const MercatorShaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShaderWidget(
      imagePath: imagePath,
      shaderAsset: shaderAsset,
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
