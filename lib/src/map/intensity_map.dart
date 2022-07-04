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

  double normalizeIntensity() {
    // Normal range is -1 to 1, make intensity bands
    if (intensity > 0) {
      // Anything greater than 1 is in the full sun
      return 1;
    } else if (intensity > -0.08) {
      // Civil twilight
      return 0.85;
    } else if (intensity > -0.18) {
      // Nautical twilight
      return 0.75;
    } else if (intensity > -0.32) {
      // Astronomical twilight
      return 0.65;
    }
    // Night
    return 0.5;
  }
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
