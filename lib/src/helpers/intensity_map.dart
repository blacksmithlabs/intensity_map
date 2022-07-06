import 'dart:collection';
import 'dart:math';

import 'package:flat_map/src/helpers/coordinate.dart';

enum LightIntensity {
  daylight,
  civil,
  nautical,
  astronomical,
  night,
}

extension LightIntensityExtension on LightIntensity {
  bool isEqual(LightIntensity other) {
    return index == other.index;
  }

  double toDouble() {
    // 1 - max(0, pt.normalizeIntensity())
    switch (this) {
      case LightIntensity.daylight:
        return 1;
      case LightIntensity.civil:
        return 0.85;
      case LightIntensity.nautical:
        return 0.75;
      case LightIntensity.astronomical:
        return 0.65;
      case LightIntensity.night:
        return 0.5;
    }
  }

  int toAlpha() {
    return (255 * (1 - max(0, toDouble()))).ceil();
  }
}

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

  LightIntensity normalizeIntensity() {
    // Normal range is -1 to 1, make intensity bands
    if (intensity > 0) {
      // Anything greater than 1 is in the full sun
      return LightIntensity.daylight;
    } else if (intensity > -0.1) {
      // Civil twilight
      return LightIntensity.civil;
    } else if (intensity > -0.2) {
      // Nautical twilight
      return LightIntensity.nautical;
    } else if (intensity > -0.3) {
      // Astronomical twilight
      return LightIntensity.astronomical;
    }
    // Night
    return LightIntensity.night;
  }

  @override
  String toString() {
    return '($latitude, $longitude, $intensity)';
  }
}

class IntensityMap extends Iterable<PointIntensity> {
  final double latitudeStep;
  final double longitudeStep;
  late final List<PointIntensity> _intensityMap;

  Map<LightIntensity, Map<double, List<double>>>? _normalizedMap;

  IntensityMap(
    GeodeticCoordinate sunCoord,
    this.latitudeStep,
    this.longitudeStep,
  ) {
    _intensityMap = _calcIntensityMap(sunCoord);
  }

  List<PointIntensity> _calcIntensityMap(GeodeticCoordinate sunCoord) {
    final points = <PointIntensity>[];

    var minValue = 0.0;
    var maxValue = 0.0;

    final sunPos = sunCoord.toSpherical();
    for (var lat = -90.0; lat <= 90.0; lat += latitudeStep) {
      for (var lon = -180.0; lon <= 180.0; lon += longitudeStep) {
        final position = GeodeticCoordinate(lat, lon);
        final delta = position.toSpherical();
        final intensity = (sunPos * delta).magnitude;

        if (intensity > maxValue) {
          maxValue = intensity;
        } else if (intensity < minValue) {
          minValue = intensity;
        }

        points.add(PointIntensity(position, intensity));
      }
    }

    final maxScale = maxValue > 0 ? 1 / maxValue : 0.0;
    final minScale = minValue < 0 ? 1 / minValue.abs() : 0.0;

    return points
        .map((pt) => pt.intensity > 0 ? pt.scale(maxScale) : pt.scale(minScale))
        .toList();
  }

  Map<LightIntensity, Map<double, List<double>>> normalizedMap() {
    if (_normalizedMap != null) {
      return _normalizedMap!;
    }

    _normalizedMap = <LightIntensity, Map<double, List<double>>>{};

    // Group by intenisty and longitude
    // { 0.25: { -75: [-120, 120 ], 25: [ -100, 90 ] } }
    for (var pt in this) {
      final longitudeValues = _normalizedMap!.putIfAbsent(
        pt.normalizeIntensity(),
        () => SplayTreeMap<double, List<double>>(),
      );

      final latitudes =
          longitudeValues.putIfAbsent(pt.longitude, () => <double>[]);
      latitudes.add(pt.latitude);
    }

    return _normalizedMap!;
  }

  @override
  Iterator<PointIntensity> get iterator => _intensityMap.iterator;
}
