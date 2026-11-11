// Rise To Sound: each letter (or copy) takes its own part of a sound's pitch range, low on the left, and rises with how strong that part is
// --sound@sound:Sound,fft,512
// --track@start:Start Frequency,20,12000,20,1
// --track@end:End Frequency,20,12000,2000,1
// --track@height:Maximum Height,0,2000,480,1
// The three sliders are those of After Effects' Audio Spectrum, which draws bars; here what rises is whatever the layer holds.
// The sound is read as a Web page reads it, from an AnalyserNode as it comes on a 48,000 Hz page (W3C Web Audio API, section 1.8): pitches 23.4375 Hz apart, each 0 to 255. The lowest 512 of its 1024 are taken, up to 12,000 Hz.
const heard = new Uint8Array(512), apart = 12000 / 512;
function each(i, n, t, k) {
  if (!k.sound) return {};
  getByteFrequencyData(k.sound, heard, k.time);
  // The mean between two frequencies, both ends counted, as p5.sound's FFT.getEnergy takes it.
  const wide = (k.end - k.start) / n, low = Math.round((k.start + wide * i) / apart), high = Math.round((k.start + wide * (i + 1)) / apart);
  let all = 0;
  for (let pitch = low; pitch <= high; pitch++) all += heard[pitch] || 0;
  return { y: all / (high - low + 1) / 255 * k.height * k.px };
}
