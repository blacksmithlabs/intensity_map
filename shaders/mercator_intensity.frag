#version 460 core

#include <flutter/runtime_effect.glsl>
#include "util.glsl"

precision mediump float;

uniform vec2 resolution;
uniform vec2 sun_rads;

out vec4 fragColor;

// longitude(x) = -180..180 = -PI..PI
// latitude(y) = -90..90 = -HP..HP

// vec2 sun_coord = vec2(-114.32, 22.44);
// vec2 sun_rads = radians(sun_coord);

void main() {
  vec2 range = vec2(TOA, -PI);
  vec2 hrange = range / 2.0;
  
  vec2 delta = range/resolution;
  vec2 latlon = FlutterFragCoord().xy * delta - hrange;

  float intensity = calcitensity(sun_rads, latlon);
  fragColor = vec4(0.0, 0.0, 0.0, 1-intensity);

  // vec2 sun_pos = (sun_rads + hrange) / delta;
  // if (distance(sun_pos.xy, gl_FragCoord.xy) < 15.0) {
  //   fragColor = vec4(1.0);
  // } else {
  //   fragColor = vec4(0.0, 0.0, 0.0, 1-intensity);
  // }
}
