// Probe: letter i stands as high as one pitch of the sound is strong; the last letter as the wave's peak
// --sound@sound:Sound,fft,512
const heard = new Uint8Array(512), wave = new Float32Array(1024), bins = [0, 5, 20, 38, 41, 43, 45, 48, 60, 85, 128, 256, 500];
function each(i, n, t, k) {
  getByteFrequencyData(k.sound, heard, k.time);
  getFloatTimeDomainData(k.sound, wave, k.time);
  let peak = 0; for (const s of wave) peak = Math.max(peak, Math.abs(s));
  return { y: (i < bins.length ? heard[bins[i]] / 255 : peak) - 0.5 };
}
