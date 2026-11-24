/*{
  "DESCRIPTION": "Physically-based 5-octave Bloom using 13-tap Karis-weighted downsampling and 9-tap tent upsampling (SIGGRAPH 2014, Jorge Jimenez).",
  "CREDIT": "Jorge Jimenez (SIGGRAPH 2014 Next Generation Post Processing)",
  "CATEGORIES": ["Blur", "Stylize"],
  "ISFVSN": "2",
  "PAD": "radius*3+16:192",
  "BYPASS": "intensity",
  "INPUTS": [
    { "NAME": "inputImage", "TYPE": "image" },
    { "NAME": "threshold", "LABEL": "Threshold", "TYPE": "float", "MIN": 0.0, "MAX": 1.5, "DEFAULT": 0.55 },
    { "NAME": "knee", "LABEL": "Soft Knee", "TYPE": "float", "MIN": 0.0, "MAX": 1.0, "DEFAULT": 0.35 },
    { "NAME": "intensity", "LABEL": "Intensity", "TYPE": "float", "MIN": 0.0, "MAX": 4.0, "DEFAULT": 0.85 },
    { "NAME": "radius", "LABEL": "Radius", "TYPE": "float", "MIN": 0.5, "MAX": 64.0, "DEFAULT": 16.0 },
    { "NAME": "tint", "LABEL": "Tint", "TYPE": "color", "DEFAULT": [1.0, 1.0, 1.0, 1.0] }
  ],
  "PASSES": [
    { "TARGET": "mip1", "FLOAT": true, "WIDTH": "max(1.0, floor($WIDTH / 2.0))",  "HEIGHT": "max(1.0, floor($HEIGHT / 2.0))" },
    { "TARGET": "mip2", "FLOAT": true, "WIDTH": "max(1.0, floor($WIDTH / 4.0))",  "HEIGHT": "max(1.0, floor($HEIGHT / 4.0))" },
    { "TARGET": "mip3", "FLOAT": true, "WIDTH": "max(1.0, floor($WIDTH / 8.0))",  "HEIGHT": "max(1.0, floor($HEIGHT / 8.0))" },
    { "TARGET": "mip4", "FLOAT": true, "WIDTH": "max(1.0, floor($WIDTH / 16.0))", "HEIGHT": "max(1.0, floor($HEIGHT / 16.0))" },
    { "TARGET": "mip5", "FLOAT": true, "WIDTH": "max(1.0, floor($WIDTH / 32.0))", "HEIGHT": "max(1.0, floor($HEIGHT / 32.0))" },
    { "TARGET": "up4",  "FLOAT": true, "WIDTH": "max(1.0, floor($WIDTH / 16.0))", "HEIGHT": "max(1.0, floor($HEIGHT / 16.0))" },
    { "TARGET": "up3",  "FLOAT": true, "WIDTH": "max(1.0, floor($WIDTH / 8.0))",  "HEIGHT": "max(1.0, floor($HEIGHT / 8.0))" },
    { "TARGET": "up2",  "FLOAT": true, "WIDTH": "max(1.0, floor($WIDTH / 4.0))",  "HEIGHT": "max(1.0, floor($HEIGHT / 4.0))" },
    {}
  ]
}*/

vec4 readSrc(vec2 uv) {
  if (PASSINDEX == 0) return IMG_NORM_PIXEL(inputImage, uv);
  if (PASSINDEX == 1) return IMG_NORM_PIXEL(mip1, uv);
  if (PASSINDEX == 2) return IMG_NORM_PIXEL(mip2, uv);
  if (PASSINDEX == 3) return IMG_NORM_PIXEL(mip3, uv);
  if (PASSINDEX == 4) return IMG_NORM_PIXEL(mip4, uv);
  if (PASSINDEX == 5) return IMG_NORM_PIXEL(mip5, uv);
  if (PASSINDEX == 6) return IMG_NORM_PIXEL(up4, uv);
  if (PASSINDEX == 7) return IMG_NORM_PIXEL(up3, uv);
  return IMG_NORM_PIXEL(up2, uv);
}

vec4 prefilter(vec4 c) {
  float luma = max(c.r, max(c.g, c.b));
  float k = max(threshold * knee, 0.0001);
  float soft = clamp(luma - threshold + k, 0.0, 2.0 * k);
  soft = (soft * soft) / (4.0 * k);
  float contrib = max(soft, luma - threshold) / max(luma, 0.0001);
  return vec4(c.rgb * contrib, c.a * contrib);
}

float karisWeight(vec4 c) {
  float luma = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
  return 1.0 / (1.0 + max(luma, 0.0));
}

vec4 downsample13(vec2 uv, vec2 px, bool firstPass) {
  vec4 a = readSrc(uv + vec2(-2.0,  2.0) * px);
  vec4 b = readSrc(uv + vec2( 0.0,  2.0) * px);
  vec4 c = readSrc(uv + vec2( 2.0,  2.0) * px);
  vec4 d = readSrc(uv + vec2(-2.0,  0.0) * px);
  vec4 e = readSrc(uv);
  vec4 f = readSrc(uv + vec2( 2.0,  0.0) * px);
  vec4 g = readSrc(uv + vec2(-2.0, -2.0) * px);
  vec4 h = readSrc(uv + vec2( 0.0, -2.0) * px);
  vec4 i = readSrc(uv + vec2( 2.0, -2.0) * px);
  vec4 j = readSrc(uv + vec2(-1.0,  1.0) * px);
  vec4 k = readSrc(uv + vec2( 1.0,  1.0) * px);
  vec4 l = readSrc(uv + vec2(-1.0, -1.0) * px);
  vec4 m = readSrc(uv + vec2( 1.0, -1.0) * px);

  if (firstPass) {
    a = prefilter(a); b = prefilter(b); c = prefilter(c);
    d = prefilter(d); e = prefilter(e); f = prefilter(f);
    g = prefilter(g); h = prefilter(h); i = prefilter(i);
    j = prefilter(j); k = prefilter(k); l = prefilter(l); m = prefilter(m);
    vec4 g0 = (j + k + l + m) * 0.25;
    vec4 g1 = (a + b + d + e) * 0.25;
    vec4 g2 = (b + c + e + f) * 0.25;
    vec4 g3 = (d + e + g + h) * 0.25;
    vec4 g4 = (e + f + h + i) * 0.25;
    float w0 = karisWeight(g0) * 0.5;
    float w1 = karisWeight(g1) * 0.125;
    float w2 = karisWeight(g2) * 0.125;
    float w3 = karisWeight(g3) * 0.125;
    float w4 = karisWeight(g4) * 0.125;
    return (g0 * w0 + g1 * w1 + g2 * w2 + g3 * w3 + g4 * w4) / max(w0 + w1 + w2 + w3 + w4, 0.0001);
  }
  vec4 outc = e * 0.125;
  outc += (a + c + g + i) * 0.03125;
  outc += (b + d + f + h) * 0.0625;
  outc += (j + k + l + m) * 0.125;
  return outc;
}

vec4 upsample9(vec2 uv, vec2 px) {
  vec4 s = readSrc(uv + vec2(-1.0,  1.0) * px);
  s += readSrc(uv + vec2( 0.0,  1.0) * px) * 2.0;
  s += readSrc(uv + vec2( 1.0,  1.0) * px);
  s += readSrc(uv + vec2(-1.0,  0.0) * px) * 2.0;
  s += readSrc(uv) * 4.0;
  s += readSrc(uv + vec2( 1.0,  0.0) * px) * 2.0;
  s += readSrc(uv + vec2(-1.0, -1.0) * px);
  s += readSrc(uv + vec2( 0.0, -1.0) * px) * 2.0;
  s += readSrc(uv + vec2( 1.0, -1.0) * px);
  return s / 16.0;
}

void main() {
  vec2 uv = isf_FragNormCoord;
  vec2 px = 1.0 / max(RENDERSIZE, vec2(1.0));
  float filterScale = clamp(radius / 16.0, 0.25, 3.0);

  if (PASSINDEX == 0) {
    gl_FragColor = downsample13(uv, px * 0.5, true);
  } else if (PASSINDEX <= 4) {
    gl_FragColor = downsample13(uv, px * 0.5, false);
  } else if (PASSINDEX == 5) {
    gl_FragColor = IMG_NORM_PIXEL(mip4, uv) + upsample9(uv, px * filterScale);
  } else if (PASSINDEX == 6) {
    gl_FragColor = IMG_NORM_PIXEL(mip3, uv) + upsample9(uv, px * filterScale);
  } else if (PASSINDEX == 7) {
    gl_FragColor = IMG_NORM_PIXEL(mip2, uv) + upsample9(uv, px * filterScale);
  } else {
    vec4 base = IMG_NORM_PIXEL(inputImage, uv);
    vec4 halo = (IMG_NORM_PIXEL(mip1, uv) + upsample9(uv, px * filterScale)) * 0.2;
    vec3 glow = halo.rgb * tint.rgb * intensity;
    float alpha = clamp(base.a + halo.a * intensity, 0.0, 1.0);
    gl_FragColor = vec4(clamp(base.rgb + glow, 0.0, 1.0), alpha);
  }
}
