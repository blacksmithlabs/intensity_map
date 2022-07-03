import 'dart:math';

import "package:vector_math/vector_math.dart";
import "dart:_internal" show SystemHash;

class GeodeticCoordinate {
  final double latitude;
  final double longitude;

  const GeodeticCoordinate(this.latitude, this.longitude);

  SphericalCoordinate toSpherical({double radius = 1.0}) {
    final lat = radians(latitude);
    final lon = radians(longitude);
    return SphericalCoordinate(
      radius * cos(lat) * cos(lon), // X
      radius * cos(lat) * sin(lon), // Y
      radius * sin(lat), // Z
    );
  }

  @override
  bool operator ==(dynamic other) => equals(other);

  @override
  int get hashCode => SystemHash.hash2(latitude.hashCode, longitude.hashCode);

  bool equals(dynamic other) =>
      other is GeodeticCoordinate &&
      other.latitude == latitude &&
      other.longitude == longitude;
}

class SphericalCoordinate {
  final double x;
  final double y;
  final double z;

  const SphericalCoordinate(this.x, this.y, this.z);

  SphericalCoordinate operator *(SphericalCoordinate other) {
    return SphericalCoordinate(x * other.x, y * other.y, z * other.z);
  }

  double get magnitude => x + y + z;

  @override
  bool operator ==(dynamic other) => equals(other);

  @override
  int get hashCode => SystemHash.hash3(x.hashCode, y.hashCode, z.hashCode);

  bool equals(dynamic other) =>
      other is SphericalCoordinate &&
      other.x == x &&
      other.y == y &&
      other.z == z;
}
