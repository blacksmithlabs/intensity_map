import 'package:flat_map/src/coordinate/coordinate.dart';

class PointIntensity {
  final double latitude;
  final double longitude;
  final double intensity;

  PointIntensity(GeodeticCoordinate coord, this.intensity)
      : latitude = coord.latitude,
        longitude = coord.longitude;

  PointIntensity._raw(this.latitude, this.longitude, this.intensity);

  PointIntensity scale(double factor) =>
      PointIntensity._raw(latitude, longitude, intensity * factor);
}

class IntensityMap extends Iterable<PointIntensity> {
  final GeodeticCoordinate sunCoord;
  final double step;
  late List<PointIntensity> _intensityMap;

  IntensityMap(this.sunCoord, this.step) {
    _intensityMap = _calcIntensityMap();
  }

  List<PointIntensity> _calcIntensityMap() {
    var points = <PointIntensity>[];

    var minValue = 0.0;
    var maxValue = 0.0;

    var sunPos = sunCoord.toSpherical();
    for (var lat = -90.0; lat <= 90.0; lat += step) {
      for (var lon = -180.0; lon <= 180.0; lon += step) {
        var position = GeodeticCoordinate(lat, lon);
        var delta = position.toSpherical();
        var intensity = (sunPos * delta).magnitude;

        if (intensity > maxValue) {
          maxValue = intensity;
        } else if (intensity < minValue) {
          minValue = intensity;
        }

        points.add(PointIntensity(position, intensity));
      }
    }

    var maxScale = maxValue > 0 ? 1 / maxValue : 0.0;
    var minScale = minValue < 0 ? 1 / minValue.abs() : 0.0;

    return points
        .map((pt) => pt.intensity > 0 ? pt.scale(maxScale) : pt.scale(minScale))
        .toList();
  }

  @override
  Iterator<PointIntensity> get iterator => _intensityMap.iterator;
}
