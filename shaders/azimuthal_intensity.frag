#version 460 core

#include <flutter/runtime_effect.glsl>
#include "util.glsl"

precision mediump float;

uniform vec2 resolution;
uniform vec2 sun_rads;

out vec4 fragColor;

// longitude(x) = -180..180 = -PI..PI
// latitude(y) = -90..90 = -HP..HP

void main() {
  vec2 center = resolution / 2.0;
  float dlat = center.y / 180.0; // -90 to 90 for radius, use as radians

  vec2 coords = FlutterFragCoord().xy;

  // Skip pixels that are outside the valid map radius
  float dr = distance(center, coords);
  if (dr > center.y) {
    fragColor = vec4(0.0);
    return;
  }

  // Distance from center to current coord is latitude
  // Scale distance to our coordinate system
  // Map so it is -90..90 instead of 0..180
  // This is off for some reason?
  float lat = dr * dlat - 90.0;
  if (lat > 90) {
    fragColor = vec4(0.5);
    return;
  }

  vec2 range = vec2(TOA, -PI);
  vec2 hrange = range / 2.0;
  
  vec2 delta = range/resolution;

  vec2 latlon = coords * delta - hrange;

  /*
  center.x + cos(long_rads) * lat
  center.y + sin(long_rads) * lat
  */

  float intensity = calcitensity(sun_rads, latlon);
  fragColor = vec4(0.0, 0.0, 0.0, 1-intensity);
}
