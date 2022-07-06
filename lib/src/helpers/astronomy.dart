import 'dart:math';

import 'package:flat_map/src/helpers/coordinate.dart';
import 'package:vector_math/vector_math.dart';

/// Get the GeodeticCoordinate of the Sub Solar point
/// see: https://python.plainenglish.io/find-the-suns-subsolar-point-42e9d4935b1c
GeodeticCoordinate getSubSolarPoint(DateTime time) {
  final utc = time.toUtc();
  final ye = utc.year;
  final mo = utc.month;
  final da = utc.day;
  final ho = utc.hour;
  final mi = utc.minute;
  final se = utc.second;

  final ut = ho + mi / 60 + se / 3600;
  final t1 = 367 * ye - 7 * (ye + (mo + 9) ~/ 12) ~/ 4;
  final dn = t1 + 275 * mo ~/ 9 + da - 730531.5 + ut / 24;
  final sl = dn * 0.01720279239 + 4.894967873;
  final sa = dn * 0.01720197034 + 6.240040768;
  final t2 = sl + 0.03342305518 * sin(sa);
  final ec = t2 + 0.0003490658504 * sin(2 * sa);
  final ob = 0.4090877234 - 0.000000006981317008 * dn;
  final st = 4.894961213 + 6.300388099 * dn;
  final ra = atan2(cos(ob) * sin(ec), cos(ec));
  final lat = degrees(asin(sin(ob) * sin(ec)));
  final lo = degrees(ra - st) % 360;
  final lon = lo > 180 ? lo - 360 : lo;

  return GeodeticCoordinate(lat, lon);
}

/// Get the GeodeticCoordinate of the Sub Lunar point
/// see: https://www.aa.quae.nl/en/reken/hemelpositie.html
GeodeticCoordinate getSubLunarPoint(DateTime time) {
  final utc = time.toUtc();
  final y2k = DateTime.utc(2000, 1, 1, 12);
  final dd = utc.difference(y2k).inHours / 24; // Partial days
  final l = (218.316 + 13.176396 * dd) % 360;
  final m = (134.963 + 13.064993 * dd) % 360;
  final f = (93.272 + 13.229350 * dd) % 360;
  final lat = 5.128 * sin(radians(f));
  final lo = l + 6.289 * sin(radians(m));
  final lon = lo > 180 ? lo - 360 : lo;

  return GeodeticCoordinate(lat, lon);
}
