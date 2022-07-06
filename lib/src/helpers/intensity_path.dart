import 'dart:math';

import 'package:flat_map/src/helpers/coordinate.dart';
import 'package:flat_map/src/helpers/intensity_map.dart';

class IntensityPathPart {
  final Map<double, double> upper;
  final Map<double, double> lower;

  IntensityPathPart(this.upper, this.lower);
}

class IntensityPath {
  final LightIntensity intensity;
  final List<GeodeticCoordinate> coordinates;

  IntensityPath(this.intensity, this.coordinates);

  static List<IntensityPath> getPaths(
      GeodeticCoordinate sunCoord, IntensityMap map) {
    final intensityByLongitude = map.normalizedMap();

    var intensityPathParts = <LightIntensity, IntensityPathPart>{};

    // For each longitude find the min/max latitude
    for (var intensityEntry in intensityByLongitude.entries) {
      final intensity = intensityEntry.key;

      final upper = <double, double>{};
      final lower = <double, double>{};
      for (var longitudeEntry in intensityEntry.value.entries) {
        final longitude = longitudeEntry.key;
        final upperLatitude = longitudeEntry.value.reduce(max);
        final lowerLatitude = longitudeEntry.value.reduce(min);

        upper[longitude] = upperLatitude;
        lower[longitude] = lowerLatitude;
      }

      intensityPathParts[intensity] = IntensityPathPart(upper, lower);
    }

    final intensityPaths = <IntensityPath>[];

    void addPaths(
      LightIntensity intensity,
      List<List<GeodeticCoordinate>> coords,
    ) {
      coords
          .map((e) => IntensityPath(intensity, e))
          .forEach(intensityPaths.add);
    }

    final intensityOrder = [
      LightIntensity.night,
      LightIntensity.astronomical,
      LightIntensity.nautical,
      LightIntensity.civil,
    ];

    if (sunCoord.latitude > 0) {
      // Sun is North of equator
      var lowest = <double, double>{};
      for (var intensity in intensityOrder) {
        var paths = intensityPathParts[intensity]!;
        lowest = _mergePaths(lowest, paths.lower, min);
        addPaths(intensity, _getPaths(paths.upper, lowest, map.longitudeStep));
      }
    } else {
      // Sun is on or South of equator
      var highest = <double, double>{};
      for (var intensity in intensityOrder) {
        var paths = intensityPathParts[intensity]!;
        highest = _mergePaths(highest, paths.upper, max);
        addPaths(intensity, _getPaths(highest, paths.lower, map.longitudeStep));
      }
    }

    return intensityPaths;
  }

  static Map<double, double> _mergePaths(
    Map<double, double> first,
    Map<double, double> second,
    double Function(double a, double b) cmp,
  ) {
    final keyUnion = {...first.keys, ...second.keys};

    final merged = <double, double>{};
    for (var key in keyUnion) {
      final firstValue = first[key];
      final secondValue = second[key];

      if (firstValue == null) {
        if (secondValue != null) {
          merged[key] = secondValue;
        }
      } else if (secondValue == null) {
        merged[key] = firstValue;
      } else {
        merged[key] = cmp(firstValue, secondValue);
      }
    }

    return merged;
  }

  static List<List<GeodeticCoordinate>> _getPaths(
    Map<double, double> upperCoords,
    Map<double, double> lowerCoords,
    double longitudeStep,
  ) {
    var upper = <GeodeticCoordinate>[];
    var lower = <GeodeticCoordinate>[];

    var paths = <List<GeodeticCoordinate>>[];

    void compileAndAddPath() {
      paths.add([...upper, ...lower.reversed]);
      upper = [];
      lower = [];
    }

    for (var lon = -180.0; lon <= 180.0; lon += longitudeStep) {
      final upperLatitude = upperCoords[lon];
      final lowerLatitude = lowerCoords[lon];
      if (upperLatitude == null || lowerLatitude == null) {
        if (upper.isNotEmpty) {
          compileAndAddPath();
        }
        continue;
      }

      upper.add(GeodeticCoordinate(upperLatitude, lon));
      lower.add(GeodeticCoordinate(lowerLatitude, lon));
    }

    if (upper.isNotEmpty) {
      compileAndAddPath();
    }

    return paths;
  }
}
