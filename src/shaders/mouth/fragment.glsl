varying vec2 vUv;

uniform float time;

float smileFactor = 0.25;
float cornerRaise = 0.15;
vec3 mouthColor = vec3(0.4969329950515914, 0.0060488330203860696, 0);
vec3 tongueColor = vec3(0.9911020971136257, 0.46778379610254284, 0.002428215868235294);

vec3 colorRampColor0 = vec3(0.651405637412793, 0.04666508633021928, 0.028426039499072558);
vec3 colorRampColor1 = vec3(0.9559733532482866, 0.17144110072255403, 0.023153366173251366);
vec3 colorRampColor2 = vec3(0.8962693533719567, 0.37626212298046485, 0.054480276435339814);
float colorRampColor1Pos = 0.5;
float colorRampColor2Pos = 1.0;
float mouthNoiseScale = 1.0;
float mouthNoiseSpeed = 10.0;
vec3 tongueColorRampColor0 = vec3(0.9046611743890203, 0.6938717612856897, 0.07618538147321911);
vec3 tongueColorRampColor1 = vec3(0.8796223968851662, 0.3231432091022285, 0.030713443727452196);
vec3 tongueColorRampColor2 = vec3(0.9301108583738498, 0.5394794890033748, 0.057805430183792694);
float tongueColorRampColor1Pos = 0.5;
float tongueColorRampColor2Pos = 1.0;
float tongueNoiseScale = 1.0;
float tongueNoiseSpeed = 2.0;

struct ColorStop {
  vec3 color;
  float position;
};

vec3 linearColorRamp(ColorStop[3] colors, float factor) {
  int index = 0;
  for(int i = 0; i < colors.length() - 1; i++) {
    ColorStop currentColor = colors[i];
    bool isInBetween = currentColor.position <= factor;
    index = int(mix(float(index), float(i), float(isInBetween)));
  }

  ColorStop currentColor = colors[index];
  ColorStop nextColor = colors[index + 1];

  float range = nextColor.position - currentColor.position;
  float lerpFactor = (factor - currentColor.position) / range;
  return mix(currentColor.color, nextColor.color, lerpFactor);
}

vec4 permute(vec4 i) {
  vec4 im = mod(i, 289.0);
  return mod(((im * 34.0) + 10.0) * im, 289.0);
}

float psrddnoise(vec3 x, float alpha) {
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

bool isUVInEllipse(float radiusX, float radiusY, vec2 center, float squeeze) {
  // Find which side of the squeeze this fragment is on
  float squeezeDirection = (vUv.y < center.y) ? -squeeze : squeeze;

  // Multiply by radiusY to keep the squeeze relative in size
  squeezeDirection *= radiusY;

  // Calculate the distance to the ellipse boundary
  vec2 ellipseUV = (vUv + vec2(0.0, squeezeDirection) - center) / vec2(radiusX, radiusY);
  float dist = length(ellipseUV);

  return dist <= 1.0;
}

vec4 drawEllipse(float radiusX, float radiusY, vec2 center, vec4 color, float squeeze, bool drawingRim) {
  // Find which side of the squeeze this fragment is on
  float squeezeDirection = (vUv.y < center.y) ? -squeeze : squeeze;

  // Multiply by radiusY to keep the squeeze relative in size
  squeezeDirection *= radiusY;

  // Calculate the distance to the ellipse boundary
  vec2 ellipseUV = (vUv + vec2(0.0, squeezeDirection) - center) / vec2(radiusX, radiusY);
  float dist = length(ellipseUV);

  if(dist <= 1.0) {
    // Lerp between the two colors if this fragment is within the soften boundary
    float soften = 0.01;
    float lerp = clamp((1.0 - dist) / soften, 0.0, 1.0);
    if(drawingRim) {
      return mix(color, gl_FragColor, 1.0 - lerp);
    } else {
      ColorStop[3] tongueBackgroundColors = ColorStop[](ColorStop(tongueColorRampColor0, 0.0), ColorStop(tongueColorRampColor1, tongueColorRampColor1Pos), ColorStop(tongueColorRampColor2, tongueColorRampColor2Pos));
      float tongueNoise = psrddnoise(vec3(vUv * tongueNoiseScale, 0.0), time * tongueNoiseSpeed);
      //float tongueNoiseUpperLimit = 0.5;
      float tongueNoiseUpperLimit = 1.0;
      tongueNoise = ((tongueNoise / 0.5) + 0.5) * tongueNoiseUpperLimit;
      vec4 coloRampColor = vec4(linearColorRamp(tongueBackgroundColors, tongueNoise), 1.0);
      return mix(coloRampColor, gl_FragColor, 1.0 - lerp);
    }
  }

  return gl_FragColor;
}

vec4 drawSmile(float radiusX, float radiusY, vec2 center, vec4 color, float squeeze, float angle, bool invert, bool drawTongue, float noise, bool useNoise) {
  vec2 adjustedUV = vUv - center;
  vec2 rotatedUV;
  rotatedUV.x = adjustedUV.x * cos(angle) - adjustedUV.y * sin(angle);
  rotatedUV.y = adjustedUV.x * sin(angle) + adjustedUV.y * cos(angle);
  rotatedUV += center;

  // Find which side of the squeeze this fragment is on
  float squeezeDirection = (rotatedUV.y < center.y) ? -squeeze : squeeze;

  // Multiply by radiusY to keep the squeeze relative in size
  squeezeDirection *= radiusY;

  // Adjust the UV coordinates to create a smile shape
  vec2 smileUV = rotatedUV - center;

  // Apply concave and convex adjustments
  smileUV.y -= smileFactor * pow(smileUV.x / radiusX, 2.0);

  // Raise the corners of the mouth
  smileUV.y += cornerRaise * pow(abs(smileUV.x / radiusX), 3.0);

  // Calculate the distance to the ellipse boundary
  vec2 ellipseUV = (smileUV + vec2(0.0, squeezeDirection)) / vec2(radiusX, radiusY);
  float dist = length(ellipseUV);

  if(dist <= 1.0) {
    if(drawTongue) {
      float tongueRadiusX = 0.2;
      float tongueRadiusY = 0.1;
      float tongueRimWidth = 0.015;
      float tongueRimRadiusX = tongueRadiusX + tongueRimWidth;
      float tongueRimRadiusY = tongueRadiusY + tongueRimWidth;
      vec2 tongueCenter = vec2(0.5, 0.4 - noise);
      vec4 tongueRimColor = vec4(0.0, 0.0, 0.0, 1.0);
      float tongueSqueeze = 0.0;

      if(isUVInEllipse(tongueRadiusX, tongueRadiusY, tongueCenter, tongueSqueeze)) {
        // Tongue
        return drawEllipse(tongueRadiusX, tongueRadiusY, tongueCenter, vec4(tongueColor, 1.0), tongueSqueeze, false);
      } else if(isUVInEllipse(tongueRimRadiusX, tongueRimRadiusY, tongueCenter, tongueSqueeze)) {
        // Tongue rim
        return drawEllipse(tongueRimRadiusX, tongueRimRadiusY, tongueCenter, tongueRimColor, tongueSqueeze, true);
      }
    }

    // Lerp between the two colors if this fragment is within the soften boundary
    float soften = 0.01;
    float lerp = clamp((1.0 - dist) / soften, 0.0, 1.0);
    if(invert) {
      return mix(gl_FragColor, color, 1.0 - lerp);
    } else {
      // if(useNoise) {
      ColorStop[3] mouthBackgroundColors = ColorStop[](ColorStop(colorRampColor0, 0.0), ColorStop(colorRampColor1, colorRampColor1Pos), ColorStop(colorRampColor2, colorRampColor2Pos));
      float mouthNoise = psrddnoise(vec3(vUv * mouthNoiseScale, 0.0), time * mouthNoiseSpeed);
      float mouthNoiseUpperLimit = 0.5;
      mouthNoise = ((mouthNoise / 0.5) + 0.5) * mouthNoiseUpperLimit;
      vec4 coloRampColor = vec4(linearColorRamp(mouthBackgroundColors, mouthNoise), 1.0);
      return mix(coloRampColor, gl_FragColor, 1.0 - lerp);
      // } else {
      return mix(color, gl_FragColor, 1.0 - lerp);
      // }
    }
  }

  return invert ? color : gl_FragColor;
}

void main() {
  float noiseStrength = 0.05;
  float noise = psrddnoise(vec3(vUv, 0.0), time) * noiseStrength;

  vec2 mouthCenter = vec2(0.5, 0.5);
  float mouthSqueeze = 0.0;
  float mouthAngle = 0.0;

  float mouthRadiusX = 0.45 + noise;
  float mouthRadiusY = 0.125 + noise;

  float rimWidth = 0.015;
  float rimRadiusX = mouthRadiusX + rimWidth;
  float rimRadiusY = mouthRadiusY + rimWidth;
  vec4 rimColor = vec4(0.0, 0.0, 0.0, 1.0);

  vec4 clearColor = vec4(0.0, 0.0, 0.0, 0.0);

  // Draw the rim
  gl_FragColor = drawSmile(rimRadiusX, rimRadiusY, mouthCenter, rimColor, mouthSqueeze, mouthAngle, false, false, noise, false);

  // Draw the mouth
  gl_FragColor = drawSmile(mouthRadiusX, mouthRadiusY, mouthCenter, vec4(mouthColor, 1.0), mouthSqueeze, mouthAngle, false, true, noise, true);

  // Clear the rest
  gl_FragColor = drawSmile(rimRadiusX, rimRadiusY, mouthCenter, clearColor, mouthSqueeze, mouthAngle, true, false, noise, false);
}