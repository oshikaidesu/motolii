#ifndef MOTOLII_MEDIA_MIDI_NOTES_H_
#define MOTOLII_MEDIA_MIDI_NOTES_H_

// Reads the notes of a MIDI file and turns them into keyframe values and note
// bursts.
//
// Notes are read with GStreamer's midiparse element, which emits one buffer per
// event with the event time as its timestamp. Each note has an on time, an off
// time, a channel, a pitch and a velocity. Keyframes are made from the notes
// the way om_midi makes After Effects keyframes (github.com/otomad/om_midi,
// Core.ts). om_midi is GPL, so only its rules are used, not its code.

#include <map>
#include <string>
#include <vector>

#include "community/quickjs/script.h"

namespace motolii {

// A note-on or note-off event, in the order of the file. The MIDI status byte
// is 0x90 for on and 0x80 for off. A note-on with velocity 0 counts as an off.
// `at` is in seconds.
struct MidiEvent {
  double at = 0;
  bool on = false;
  int channel = 0, pitch = 0, velocity = 0;
};

// Reads all note events of `file` with GStreamer. Returns an empty list if the
// file cannot be read.
std::vector<MidiEvent> midi_events(const char* file);

// Returns keyframes (time in seconds to value) for one kind of value, made the
// way om_midi keys the sliders of its null object (Core.ts). Every keyframe is
// held. Chords are not keyed apart: a note that starts at the time of the
// previous one is skipped, unless it is an on directly after an off.
//
// `kind` is one of:
//   "velocity": 0 to 1. Set at each note-on, and set again 0.5 ms before each
//   note-off. "pitch":    the note number. "count":    1, 2, 3, ... for each
//   note. "on":       1 while a note sounds, 0 where it goes off. "bool":     1
//   for odd counts and 0 for even counts.
// "velocity", "on" and "count" also get the value 0 at time 0.
// `channel` selects one MIDI channel; -1 means any channel.
// Returns an empty map for an unknown kind or when the channel has no notes.
std::map<double, double> midi_keys(const std::vector<MidiEvent>& events,
                                   const std::string& kind, int channel);

// Returns the first tempo stored in a MIDI file, in beats per minute. The tempo
// is the meta event FF 51 03 of Standard MIDI File 1.0, which holds the
// microseconds per quarter note. A file without a tempo gets 120, the default
// of the same specification and of om_midi's Midi.ts (DEFAULT_BPM).
double midi_bpm(const char* file);

// Returns the row height in points per semitone, laid out as ALMaMPlayer does
// in main_interface.gd: note_spacing = (vertical_offset + top_margin) /
// note_range, where -192 + 880 = 688 on its 1920 x 1080 screen.
double midi_spacing(const std::vector<MidiEvent>& events);

// One note. A note-on without a matching off is given an off 0.1 s after its
// on.
struct MidiNote {
  double on = 0, off = 0;
  int pitch = 0, velocity = 0;
};

// Returns the notes of `file` in the order they come on. Each file is read once
// and the result is cached, so later changes to the file are not seen.
// Thread-safe.
const std::vector<MidiNote>& midi_of(const std::string& file);

// Returns one copy of a layer per note, animated as the burst ALMaMPlayer plays
// where a note is struck (github.com/almam72/ALMAMPlayer, note_effect.gd and
// .tscn). The project is GPL-3, so only its numbers are used, not its code.
//
// Copy i belongs to note i and is placed on the layer, which is the line the
// notes are struck on. The highest note sits at the layer and each lower note
// is one row lower, using the row height of midi_spacing, as in the matching
// roll from midi_roll.cpp. `unit` is the size of one pixel of ALMaMPlayer's
// 1920 x 1080 screen in canvas lengths. `roll` is the height of that roll in
// points, with its highest row at the top. It is 0 when there is no roll.
//
// Timeline of a burst, with t0 the time the note comes on:
//   size is 0.8 at t0, 1.16 at t0 + 0.027 s and 1 at t0 + 0.096 s.
//   Starting 0.025 s before the note goes off, size falls to 0 over 0.167 s,
//   and opacity falls from 1 to 0 between 0.083 s and 0.146 s.
// A note that has not yet started is invisible.
std::vector<ScriptCopy> midi_copies(const std::vector<MidiNote>& notes, int n,
                                    double t, double unit, double roll = 0);

}  // namespace motolii

#endif  // MOTOLII_MEDIA_MIDI_NOTES_H_
