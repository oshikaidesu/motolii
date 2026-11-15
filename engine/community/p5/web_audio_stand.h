#ifndef MOTOLII_COMMUNITY_P5_WEB_AUDIO_STAND_H_
#define MOTOLII_COMMUNITY_P5_WEB_AUDIO_STAND_H_

// Web Audio with no page and no loudspeaker, for a sketch that listens: what
// p5.sound (third_party/js/p5/addons, its file as it is released) and code
// written against the W3C Web Audio API ask of a browser in order to hear a
// sound and measure it. p5.sound itself runs on it unchanged.
//
// The stand-in JavaScript lives as third_party/js/p5/stand/web_audio_stand.js
// and is loaded by community/script_runner/script_natives.cpp (sketch_hears)
// before p5.sound, when a sketch uses loadSound, p5.SoundFile, p5.FFT,
// p5.Amplitude, p5.PeakDetect or AudioContext. See the file's own comments for
// what is real (the graph, AnalyserNode, AudioWorkletNode, time, loaded
// buffers) and what is not (sketch-made oscillators, output to speakers).

#endif  // MOTOLII_COMMUNITY_P5_WEB_AUDIO_STAND_H_
