varying vec2 vUv;

uniform float time;

vec4 permute(vec4 i) {
  vec4 im = mod(i, 289.0);
  return mod(((im * 34.0) + 10.0) * im, 289.0);
}

float psrddnoise(
  vec3 x,
  float alpha
) {
  // Transformation matrices for the axis-aligned simplex grid
  const mat3 M = mat3(0.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0);

  const mat3 Mi = mat3(-0.5, 0.5, 0.5, 0.5, -0.5, 0.5, 0.5, 0.5, -0.5);

  vec3 uvw;

  // Transform to simplex space (tetrahedral grid)
  // Use matrix multiplication, let the compiler optimise
  uvw = M * x;

  // Determine which simplex we're in, i0 is the "base corner"
  vec3 i0 = floor(uvw);
  vec3 f0 = fract(uvw); // coords within "skewed cube"

  // To determine which simplex corners are closest, rank order the
  // magnitudes of u,v,w, resolving ties in priority order u,v,w,
  // and traverse the four corners from largest to smallest magnitude.
  // o1, o2 are offsets in simplex space to the 2nd and 3rd corners.
  vec3 g_ = step(f0.xyx, f0.yzz); // Makes comparison "less-than"
  vec3 l_ = 1.0 - g_;             // complement is "greater-or-equal"
  vec3 g = vec3(l_.z, g_.xy);
  vec3 l = vec3(l_.xy, g_.z);
  vec3 o1 = min(g, l);
  vec3 o2 = max(g, l);

  // Enumerate the remaining simplex corners
  vec3 i1 = i0 + o1;
  vec3 i2 = i0 + o2;
  vec3 i3 = i0 + vec3(1.0);

  vec3 v0, v1, v2, v3;

  // Transform the corners back to texture space
  v0 = Mi * i0;
  v1 = Mi * i1;
  v2 = Mi * i2;
  v3 = Mi * i3;

  // Compute vectors to each of the simplex corners
  vec3 x0 = x - v0;
  vec3 x1 = x - v1;
  vec3 x2 = x - v2;
  vec3 x3 = x - v3;

  // Compute one pseudo-random hash value for each corner
  vec4 hash = permute(permute(permute(vec4(i0.z, i1.z, i2.z, i3.z)) + vec4(i0.y, i1.y, i2.y, i3.y)) + vec4(i0.x, i1.x, i2.x, i3.x));

  // Compute generating gradients from a Fibonacci spiral on the unit sphere
  vec4 theta = hash * 3.883222077;  // 2*pi/golden ratio
  vec4 sz = hash * -0.006920415 + 0.996539792; // 1-(hash+0.5)*2/289
  vec4 psi = hash * 0.108705628; // 10*pi/289, chosen to avoid correlation

  vec4 Ct = cos(theta);
  vec4 St = sin(theta);
  vec4 sz_prime = sqrt(1.0 - sz * sz); // s is a point on a unit fib-sphere

  vec4 gx, gy, gz;

  // Rotate gradients by angle alpha around a pseudo-random ortogonal axis
  vec4 qx = St;         // q' = norm ( cross(s, n) )  on the equator
  vec4 qy = -Ct;
  vec4 qz = vec4(0.0);

  vec4 px = sz * qy;   // p' = cross(q, s)
  vec4 py = -sz * qx;
  vec4 pz = sz_prime;

  psi += alpha;         // psi and alpha in the same plane
  vec4 Sa = sin(psi);
  vec4 Ca = cos(psi);

  gx = Ca * px + Sa * qx;
  gy = Ca * py + Sa * qy;
  gz = Ca * pz + Sa * qz;

  // Reorganize for dot products below
  vec3 g0 = vec3(gx.x, gy.x, gz.x);
  vec3 g1 = vec3(gx.y, gy.y, gz.y);
  vec3 g2 = vec3(gx.z, gy.z, gz.z);
  vec3 g3 = vec3(gx.w, gy.w, gz.w);

  // Radial decay with distance from each simplex corner
  vec4 w = 0.5 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3));
  w = max(w, 0.0);
  vec4 w2 = w * w;
  vec4 w3 = w2 * w;

  // The value of the linear ramp from each of the corners
  vec4 gdotx = vec4(dot(g0, x0), dot(g1, x1), dot(g2, x2), dot(g3, x3));

  // Multiply by the radial decay and sum up the noise value
  float n = dot(w3, gdotx);

  // Scale the return value to fit nicely into the range [-1,1]
  return 39.5 * n;
}

float heart(vec2 p) {
  p.y += .6;
  const float offset = .3;
  float k = 1.2 * p.y - sqrt(abs(p.x) + offset);
  return p.x * p.x + k * k - 1.;
}

vec4 drawHeart(vec2 uv, float scale, vec4 color, bool invert) {
  float dist = heart(uv / scale);

  if(dist <= 0.0) {
    return (invert ? gl_FragColor : color);
  }

  return invert ? color : gl_FragColor;
}

void main() {
  float noiseScale = 0.5;
  float noiseStrength = 0.1;
  float noise = psrddnoise(vec3(vUv * noiseScale, 0.0), time) * noiseStrength;

  float heartScale = 0.75 + noise;
  float heartRimWidth = 0.1;
  vec4 heartColor = vec4(0.6, 0.0, 0.0, 1.0);
  vec4 heartRimColor = vec4(0.0, 0.0, 0.0, 1.0);
  vec4 clearColor = vec4(0.0, 0.0, 0.0, 0.0);

  vec2 uv = (vUv - 0.5) * 2.0;

  gl_FragColor = drawHeart(uv, heartScale + heartRimWidth, heartRimColor, false);
  gl_FragColor = drawHeart(uv, heartScale, heartColor, false);
  gl_FragColor = drawHeart(uv, heartScale + heartRimWidth, clearColor, true);
}
