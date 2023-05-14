#define HP  1.5707963269
#define PI  3.1415926538
#define TOA 6.2831853076

vec3 geotosphere(vec2 geo) {
    return vec3(
    	cos(-geo.y) * cos(geo.x), // X
    	cos(-geo.y) * sin(geo.x), // Y
    	sin(-geo.y) // Z
    );
}

float calcitensity(vec2 sun_rads, vec2 latlon) {
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

  return intensity;
}
