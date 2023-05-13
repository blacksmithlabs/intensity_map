#version 460 core

#define HP  1.5707963269
#define PI  3.1415926538
#define TOA 6.2831853076

#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 resolution;
uniform vec2 sun_rads;

out vec4 fragColor;

// longitude = x = -180->180 = -PI->PI
// latitude = y = -90->90 = -HP->HP

// vec2 sun_coord = vec2(-114.32, 22.44);
// vec2 sun_rads = radians(sun_coord);

vec3 geotosphere(in vec2 geo) {
    return vec3(
    	cos(-geo.y) * cos(geo.x), // X
    	cos(-geo.y) * sin(geo.x), // Y
    	sin(-geo.y) // Z
    );
}

void main() {
  vec2 range = vec2(TOA, -PI);
  vec2 hrange = range / 2.0;
  
  vec2 delta = range/resolution;
  vec2 latlon = FlutterFragCoord().xy * delta - hrange;

  vec3 sun_geo = geotosphere(sun_rads);
  vec3 geo = geotosphere(latlon);
  vec3 magnitude = sun_geo * geo;
  
  float intensity = magnitude.x + magnitude.y + magnitude.z;
  if (intensity > 0.0) { // daylight
    intensity = 1.0;
  } else if (intensity > -0.1) { // civil
    intensity = 0.85;
  } else if (intensity > -0.2) { // nautical twilight
    intensity = 0.65;
  } else if (intensity > -0.3) { // astronomical twilight
    intensity = 0.45;
  } else { // night
    intensity = 0.25;
  }
  
  fragColor = vec4(0.0, 0.0, 0.0, 1-intensity);

  // vec2 sun_pos = (sun_rads + hrange) / delta;
  // if (distance(sun_pos.xy, gl_FragCoord.xy) < 15.0) {
  //   fragColor = vec4(1.0);
  // } else {
  //   fragColor = vec4(0.0, 0.0, 0.0, 1-intensity);
  // }
}
