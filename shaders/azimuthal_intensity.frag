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
  float dlat = 180.0 / center.y; // -90 to 90 for radius, use as radians

  vec2 coords = FlutterFragCoord().xy;

  // Skip pixels that are outside the valid map radius
  float dr = distance(center, coords);
  if (dr > center.y) {
    fragColor = vec4(0.0);
    return;
  }

  float tr = distance(center, coords);
  float lat = -radians(90 - (tr * dlat));
  float lon = HP - asin((coords.y - center.y) / tr);
  if (coords.x < center.x) {
    lon = -lon;
  }

  float intensity = calcitensity(sun_rads, vec2(lon, lat));
  fragColor = vec4(0.0, 0.0, 0.0, 1-intensity);
}
