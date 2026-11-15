// spectrum.glsl: a colour of light as a number (its wavelength in nm): what colour it shows as.
// Read by thick_glass.mat.
// From Saqoosha/Spectral-Glass `cieXyz`, `xyzToSrgb` (MIT, (c) 2026 Saqoosha).
float gLobe(float lambda, float mu, float s1, float s2) {
    float t = (lambda - mu) / (lambda < mu ? s1 : s2);
    return exp(-0.5 * t * t);
}
// Wyman-Sloan-Shirley (JCGT 2013) analytic CIE 1931 2-degree matching functions
vec3 cieXyz(float lambda) {
    float x = 0.362 * gLobe(lambda, 442.0, 16.0, 26.7) + 1.056 * gLobe(lambda, 599.8, 37.9, 31.0)
            - 0.065 * gLobe(lambda, 501.1, 20.4, 26.2);
    float y = 0.821 * gLobe(lambda, 568.8, 46.9, 40.5) + 0.286 * gLobe(lambda, 530.9, 16.3, 31.1);
    float z = 1.217 * gLobe(lambda, 437.0, 11.8, 36.0) + 0.681 * gLobe(lambda, 459.0, 26.0, 13.8);
    return vec3(x, y, z);
}
vec3 xyzToSrgb(vec3 c) {
    return mat3(3.2404542, -0.9692660, 0.0556434, -1.5371385, 1.8760108, -0.2040259,
                -0.4985314, 0.0415560, 1.0572252) * c;
}
