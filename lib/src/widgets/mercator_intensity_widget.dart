import 'package:flat_map/src/widgets/base_intensity_widget.dart';
import 'package:flutter/material.dart';

class MercatorIntensityWidget extends StatelessWidget {
  final imagePath = 'assets/maps/mercator-projection.jpg';

  const MercatorIntensityWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseIntensityWidget(
      imagePath: imagePath,
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
