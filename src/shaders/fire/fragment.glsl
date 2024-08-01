precision highp float;
precision highp sampler3D;

in vec3 vPosition;
in vec3 vOrigin;
in vec3 vDirection;

vec4 color;

uniform sampler3D map;
uniform sampler3D noise;
uniform float time;

float timeScalingFactor = 1.0;
float up = 0.8;
float cut = 0.5;
float steps = 200.0;
vec3 darkColor = vec3(0.7991027380100881, 0.10224173307914941, 0.04518620437910499);
vec3 lightColor = vec3(0.8713671191959567, 0.34191442489801843, 0.04091519690055698);
float horizontalFalloff = 1.5;
float verticalFalloff = 0.5;
float bloomIntensity = 2.0;

// This link has a good explanation: https://gamedev.stackexchange.com/questions/18436/most-efficient-aabb-vs-ray-collision-algorithms
vec2 hitBox(vec3 orig, vec3 dir) {
  // min and max corners of AABB
  // this is a unit cube centered at the origin
  const vec3 box_min = vec3(-.5);
  const vec3 box_max = vec3(.5);

  vec3 inv_dir = 1.0 / dir;

  // tmin_tmp and tmax_tmp are the distances along the ray
  // to the near and far planes of the bounding box for each axis
  vec3 tmin_tmp = (box_min - orig) * inv_dir;
  vec3 tmax_tmp = (box_max - orig) * inv_dir;

  // tmin and tmax are the minimum and maximum distances along the ray
  // to the intersection points with the bounding box
  // this ensures that tmin contains the distances to the near planes and
  // tmax contains the distances to the far planes
  vec3 tmin = min(tmin_tmp, tmax_tmp);
  vec3 tmax = max(tmin_tmp, tmax_tmp);

  // t0 is the maximum of the minimum distances,
  // representing the entry point of the ray into the bounding box
  // t0 is the largest of the minimum distances,
  // ensuring that the ray has entered the bounding box on all three axes
  float t0 = max(tmin.x, max(tmin.y, tmin.z));

  // t1 is the minimum of the maximum distances,
  // representing the exit point of the ray from the bounding box
  // t1 is the smallest of the maximum distances,
  // ensuring that the ray has exited the bounding box on all three axes
  float t1 = min(tmax.x, min(tmax.y, tmax.z));

  return vec2(t0, t1);
}

mat4 rotationMatrix(vec3 axis, float angle) {
  axis = normalize(axis);
  float s = sin(angle);
  float c = cos(angle);
  float oc = 1.0 - c;

  return mat4(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s, 0.0, oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s, 0.0, oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c, 0.0, 0.0, 0.0, 0.0, 1.0);
}

vec3 rotate(vec3 v, vec3 axis, float angle) {
  mat4 m = rotationMatrix(axis, angle);
  return (m * vec4(v, 1.0)).xyz;
}

vec2 rotate(vec2 v, float a) {
  float s = sin(a);
  float c = cos(a);
  mat2 m = mat2(c, -s, s, c);
  return m * v;
}

float sample1(vec3 p) {
  // p is in the [0, 1] range
  // here it's converted to the [-0.5, 0.5] range so we can rotate it
  vec3 pr = p - .5;
  // now we rotate pr around the X axis
  pr = rotate(pr, vec3(1., 0., 0.), time * timeScalingFactor);
  // now we bring it back to the [0, 1] range so we can use it to sample a texture
  pr += .5;

  // here we distort pr using the noise texture
  // this offset makes fire move downwards
  float prVerticalOffset = time * timeScalingFactor * .05 + pr.y * .1;
  vec3 prOffset = vec3(0., prVerticalOffset, 0.);
  vec3 normalizedPR = mod(pr + prOffset, vec3(1.));
  float distort = texture(noise, normalizedPR).r;
  p += vec3(.1 * distort);

  // here we convert pr back to the [-0.5, 0.5] range so we can rotate it
  pr = p - .5;
  // now we rotate pr around the Y axis
  pr = rotate(pr, vec3(0., 1., 0.), 2. * pr.y);
  // now we bring it back to the [0, 1] range
  pr += .5;

  // here we get the final noise sample using pr
  // this offset makes the fire more upwards
  prVerticalOffset = -time * timeScalingFactor * up;
  prOffset = vec3(0., prVerticalOffset, 0.);
  normalizedPR = mod(pr + prOffset, vec3(1.));
  return texture(map, normalizedPR).r;
}

void main() {
  vec3 rayDir = normalize(vDirection);
  vec2 bounds = hitBox(vOrigin, rayDir);

  // If bounds.x (entry point) is greater than bounds.y (exit point),
  // it means the ray does not intersect the bounding box,
  // so the fragment is discarded
  if(bounds.x > bounds.y)
    discard;

  bounds.x = max(bounds.x, 0.);

  // entry point in local space
  // this is the starting point for ray marching
  vec3 p = vOrigin + bounds.x * rayDir;

  // inc represents the distance to move along the ray direction to
  // step one unit in each axis (x, y, z)
  // here we prioritize the axis that the ray is most aligned with,
  // since that axis will have the smallest inc value
  vec3 inc = 1.0 / abs(rayDir);

  // min(inc.x, min(inc.y, inc.z)) finds the smallest
  // component of the inc vector
  // this ensures that the step size is small enough to sample
  // the volume accurately along the axis with the smallest step size
  // delta is the step size for ray marching
  // it represents the distance to move along the ray direction for each step
  float delta = min(inc.x, min(inc.y, inc.z));
  delta /= steps;

  // accumulated color
  vec4 ac = vec4(0., 0., 0., 0.);

  float total = 0.;

  // Loop from entry distance to exit distance with steps of size delta
  for(float t = bounds.x; t < bounds.y; t += delta) {
    // p is the entry point of the ray into the bounding box
    // (not 100% accurate because we are updating p every iteration, but you get the point)
    // the bounding box goes from -0.5 to 0.5 on all axes
    // so p is guaranteed to be in that range
    // adding 0.5 converts it from to -0.5 -> 0.5 range to the 0.0 -> 1.0 range
    // that's the range we need to sample 3D textures (uvw)
    float d = sample1(p + .5);

    // this is the distance from the origin to the entry point
    // (not 100% accurate because we are updating p every iteration, but you get the point)
    float radius = length(p.xz);

    // g is largest at the origin as diminishes as we move out
    // it drives a radial falloff effect
    float g = (.5 - horizontalFalloff * radius);

    // cc is a cutoff value
    // the cutoff is smallest at the origin and grows as we move out
    float cc = cut - g;
    // the cutoff is smallest at the bottom and grows as we move up
    cc += .75 * (p.y + verticalFalloff);
    // I think cc is partly responsible for the creation of a cone
    if(d > cc) {
      float f = cc;

      vec3 c = vec3(.1) * f;
      color.rgb += c;
      color.a += .1;
      total += f;
    }
    p += rayDir * delta;
  }
  color.rgb += 1. - (p.y - .5);
  color.rgb /= total;

  float l = color.r * color.a;
  color.rgb = mix(darkColor, lightColor, l) * bloomIntensity;

  gl_FragColor = color;
}