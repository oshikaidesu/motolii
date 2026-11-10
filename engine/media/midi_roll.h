// Renders a MIDI file as a piano roll in SVG text. The implementation in midi_roll.cpp runs
// bladeSk's PianoRollSvg.js in QuickJS and follows the look of ALMaMPlayer.
#pragma once
#include <string>
#include <utility>
#include <vector>

// Returns the piano roll of `file` as SVG text.
// `bpm` is the tempo to play the file's beats at; 0 uses the tempo stored in the file.
// On failure returns "" and sets `why` to the reason.
// If `notes` is not null, it receives one line per note with its pitch, velocity, time and
// duration, as bladeSk's script reports them.
std::string midi_roll(const std::string& file, double bpm, std::string& why, std::string* notes = nullptr);
// Same as midi_roll, but caches the SVG in ~/Library/Caches/Motolii/midi and returns the path
// of the cached file. The cache name is built from the file name, its last-modified time and
// the bpm.
std::string midi_roll_file(const std::string& file, double bpm, std::string& why);
// Measures a roll as ThorVG sees it and stores the width and height in `w` and `h`, in points.
// A roll is 300 points per second wide and each note is 18 points high.
// Returns false if the size cannot be read.
bool midi_roll_box(const std::string& svg, double& w, double& h);
// One note of a roll. Times are in seconds of the roll. x, y and high give the note's
// rectangle: left edge, top edge and height, in points of the roll. pitch and velocity are
// bladeSk's note.note and velOn.
struct MidiRollNote { double on = 0, off = 0, x = 0, y = 0, high = 0; int pitch = 0, velocity = 0; };
// Returns the notes of the roll stored at the path `svg`, in the order they are drawn. The
// element ids are "note<i>". Positions are read from the SVG and pitch, velocity and timing
// from the .notes file stored beside it by midi_roll_file.
std::vector<MidiRollNote> midi_roll_notes(const std::string& svg);
