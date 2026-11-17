// A sketch made for measuring, not a posted one: p5.sound's own p5.Amplitude, its level drawn as one magenta bar the
// width of the canvas, so that chrome_p5.py and measure_p5_against_chrome.py can read it as they read the bars of a
// spectrum. The level is times five so that the bar is tall enough to read (the sound is played at 0.2).
let sound, amplitude;
function preload() { sound = loadSound('assets/any.mp3'); }
function setup() {
  let cnv = createCanvas(100, 100);
  cnv.mouseClicked(() => { if (!sound.isPlaying()) sound.loop(); });
  amplitude = new p5.Amplitude();
  sound.amp(0.2);
}
function draw() {
  background(220);
  noStroke();
  fill(255, 0, 255);
  rect(0, height, width, -height * 5 * amplitude.getLevel());
  stroke(20);
  line(0, height / 2, width, height / 2);
}
