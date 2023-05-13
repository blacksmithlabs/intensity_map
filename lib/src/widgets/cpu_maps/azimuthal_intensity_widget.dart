import 'dart:math';

import 'package:flat_map/src/widgets/cpu_maps/base_intensity_widget.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import 'package:flutter/material.dart';

class AzimuthalIntensityWidget extends StatelessWidget {
  final imagePath = 'assets/maps/azimuthal-projection.jpg';

  const AzimuthalIntensityWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseIntensityWidget(
      imagePath: imagePath,
      toOffsetBuilder: (size) {
        final center = Offset(size.width, size.height) / 2;
        final dlat = size.height / 180.0 / 2; // -90 to 90, use as radius

        return (latitude, longitude) {
          final long = radians(-longitude + 90);
          final lat = (-latitude + 90) * dlat;

          return center + Offset(cos(long) * lat, sin(long) * lat);
        };
      },
    );
  }
}
