// Reads the notes of a MIDI file and turns them into keyframe values and note bursts.
//
// Notes are read with GStreamer's midiparse element, which emits one buffer per event with
// the event time as its timestamp. Each note has an on time, an off time, a channel, a pitch
// and a velocity. Keyframes are made from the notes the way om_midi makes After Effects
// keyframes (github.com/otomad/om_midi, Core.ts). om_midi is GPL, so only its rules are
// used, not its code.
#pragma once
#include <gst/gst.h>
#include <gst/app/gstappsink.h>
#include "media/gstreamer_file_source.h"
#include "community/quickjs/script.h"
#include <fstream>
#include <iterator>
#include <cmath>
#include <map>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

// A note-on or note-off event, in the order of the file. The MIDI status byte is 0x90 for on
// and 0x80 for off. A note-on with velocity 0 counts as an off. `at` is in seconds.
struct MidiEvent { double at = 0; bool on = false; int channel = 0, pitch = 0, velocity = 0; };

// Reads all note events of `file` with GStreamer. Returns an empty list if the file cannot be
// read.
static std::vector<MidiEvent> midi_events(const char* file) {
    static const bool started = (gst_init(nullptr, nullptr), true);
    (void)started;
    std::vector<MidiEvent> events;
    bool pulling = true;
    GstElement* reads = gst_parse_launch("filesrc name=in ! midiparse ! appsink name=out sync=false", nullptr);
    if (!reads) return events;
    gst_read_from(reads, file);
    GstElement* out = gst_bin_get_by_name(GST_BIN(reads), "out");
    // If the pipeline cannot start, for example because the file does not exist, no end of
    // stream would ever arrive, so do not pull.
    if (gst_element_set_state(reads, GST_STATE_PLAYING) == GST_STATE_CHANGE_FAILURE) pulling = false;
    while (GstSample* got = pulling ? gst_app_sink_pull_sample(GST_APP_SINK(out)) : nullptr) {
        GstBuffer* b = gst_sample_get_buffer(got);
        GstMapInfo map;
        if (b && GST_BUFFER_PTS_IS_VALID(b) && gst_buffer_map(b, &map, GST_MAP_READ)) {
            const int status = map.size >= 3 ? map.data[0] & 0xf0 : 0;
            if (status == 0x80 || status == 0x90)
                events.push_back({(double)GST_BUFFER_PTS(b) / (double)GST_SECOND, status == 0x90 && map.data[2] > 0, map.data[0] & 0x0f, map.data[1], map.data[2]});
            gst_buffer_unmap(b, &map);
        }
        gst_sample_unref(got);
    }
    gst_element_set_state(reads, GST_STATE_NULL);
    gst_object_unref(out), gst_object_unref(reads);
    return events;
}

// Returns keyframes (time in seconds to value) for one kind of value, made the way om_midi
// keys the sliders of its null object (Core.ts). Every keyframe is held. Chords are not keyed
// apart: a note that starts at the time of the previous one is skipped, unless it is an on
// directly after an off.
//
// `kind` is one of:
//   "velocity": 0 to 1. Set at each note-on, and set again 0.5 ms before each note-off.
//   "pitch":    the note number.
//   "count":    1, 2, 3, ... for each note.
//   "on":       1 while a note sounds, 0 where it goes off.
//   "bool":     1 for odd counts and 0 for even counts.
// "velocity", "on" and "count" also get the value 0 at time 0.
// `channel` selects one MIDI channel; -1 means any channel.
// Returns an empty map for an unknown kind or when the channel has no notes.
static std::map<double, double> midi_keys(const std::vector<MidiEvent>& events, const std::string& kind, int channel) {
    std::map<double, double> keys;
    if (kind != "velocity" && kind != "pitch" && kind != "count" && kind != "on" && kind != "bool") return keys;
    // om_midi's MIN_INTERVAL, in seconds.
    const double min_interval = 5e-4;
    int count = 0;
    double last = -1;
    bool last_off = true;
    for (const MidiEvent& e : events) {
        if (channel >= 0 && e.channel != channel) continue;
        if (e.at <= last && !(last_off && e.on)) continue;
        if (e.on) {
            ++count;
            const double is = kind == "velocity" ? e.velocity / 127.0 : kind == "pitch" ? e.pitch : kind == "count" ? count : kind == "on" ? 1 : count % 2;
            keys[e.at] = is;
        } else if (kind == "velocity") keys[std::max(0.0, e.at - min_interval)] = e.velocity / 127.0;
        else if (kind == "on") keys[e.at] = 0;
        last = e.at, last_off = !e.on;
    }
    if (keys.empty()) return keys;
    if ((kind == "velocity" || kind == "on" || kind == "count") && !keys.count(0.0)) keys[0.0] = 0;
    return keys;
}

// Returns the first tempo stored in a MIDI file, in beats per minute. The tempo is the meta
// event FF 51 03 of Standard MIDI File 1.0, which holds the microseconds per quarter note.
// A file without a tempo gets 120, the default of the same specification and of om_midi's
// Midi.ts (DEFAULT_BPM).
static double midi_bpm(const char* file) {
    std::ifstream in(file, std::ios::binary);
    const std::string b((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    const size_t at = b.find("\xff\x51\x03");
    if (at == std::string::npos || at + 6 > b.size()) return 120.0;
    const double us = (double)(((unsigned char)b[at + 3] << 16) | ((unsigned char)b[at + 4] << 8) | (unsigned char)b[at + 5]);
    return us > 0 ? 60e6 / us : 120.0;
}

// Returns the row height in points per semitone, laid out as ALMaMPlayer does in
// main_interface.gd: note_spacing = (vertical_offset + top_margin) / note_range, where
// -192 + 880 = 688 on its 1920 x 1080 screen.
static double midi_spacing(const std::vector<MidiEvent>& events) {
    int low = 127, high = 0;
    for (const MidiEvent& e : events) if (e.on) low = std::min(low, e.pitch), high = std::max(high, e.pitch);
    return 688.0 / std::max(1, high - low);
}

// One note. A note-on without a matching off is given an off 0.1 s after its on.
struct MidiNote { double on = 0, off = 0; int pitch = 0, velocity = 0; };

// Returns the notes of `file` in the order they come on. Each file is read once and the
// result is cached, so later changes to the file are not seen. Thread-safe.
static const std::vector<MidiNote>& midi_of(const std::string& file) {
    static std::map<std::string, std::vector<MidiNote>> read;
    static std::mutex one;
    std::lock_guard<std::mutex> hold(one);
    auto found = read.find(file);
    if (found != read.end()) return found->second;
    std::vector<MidiNote> notes;
    // Index into `notes` of the note that is currently on, by channel and pitch.
    std::map<std::pair<int, int>, size_t> sounding;
    for (const MidiEvent& e : midi_events(file.c_str())) {
        const auto key = std::make_pair(e.channel, e.pitch);
        if (auto was = sounding.find(key); was != sounding.end()) notes[was->second].off = e.at, sounding.erase(was);
        if (e.on) sounding[key] = notes.size(), notes.push_back({e.at, -1, e.pitch, e.velocity});
    }
    for (MidiNote& n : notes) if (n.off < n.on) n.off = n.on + 0.1;
    return read.emplace(file, std::move(notes)).first->second;
}

// Returns one copy of a layer per note, animated as the burst ALMaMPlayer plays where a note
// is struck (github.com/almam72/ALMAMPlayer, note_effect.gd and .tscn). The project is GPL-3,
// so only its numbers are used, not its code.
//
// Copy i belongs to note i and is placed on the layer, which is the line the notes are struck
// on. The highest note sits at the layer and each lower note is one row lower, using the row
// height of midi_spacing, as in the matching roll from midi_roll.cpp.
// `unit` is the size of one pixel of ALMaMPlayer's 1920 x 1080 screen in canvas lengths.
// `roll` is the height of that roll in points, with its highest row at the top. It is 0 when
// there is no roll.
//
// Timeline of a burst, with t0 the time the note comes on:
//   size is 0.8 at t0, 1.16 at t0 + 0.027 s and 1 at t0 + 0.096 s.
//   Starting 0.025 s before the note goes off, size falls to 0 over 0.167 s, and opacity
//   falls from 1 to 0 between 0.083 s and 0.146 s.
// A note that has not yet started is invisible.
static std::vector<ScriptCopy> midi_copies(const std::vector<MidiNote>& notes, int n, double t, double unit, double roll = 0) {
    std::vector<ScriptCopy> all((size_t)std::max(n, 0));
    for (ScriptCopy& c : all) c.opacity = 0.0;
    int low = 127, high = 0;
    for (const MidiNote& m : notes) low = std::min(low, m.pitch), high = std::max(high, m.pitch);
    // Same row height as midi_spacing for these notes. `top` places the middle of the highest row
    // at the middle of the roll's highest row.
    const double spacing = 688.0 / std::max(1, high - low), top = roll > 0 ? 0.5 * roll - 0.5 * spacing : 0.0;
    // Linear interpolation between keys, like a Godot animation track.
    const auto keys = [](const std::vector<std::pair<double, double>>& k, double x) {
        if (x <= k.front().first) return k.front().second;
        for (size_t i = 1; i < k.size(); ++i)
            if (x <= k[i].first) return k[i - 1].second + (k[i].second - k[i - 1].second) * (x - k[i - 1].first) / (k[i].first - k[i - 1].first);
        return k.back().second;
    };
    for (int i = 0; i < (int)notes.size() && i < n; ++i) {
        const MidiNote& m = notes[(size_t)i];
        if (t < m.on) continue;
        ScriptCopy& burst = all[(size_t)i];
        // The burst ends when note_effect.gd's Timer fires.
        const double end = m.off - m.on > 0.09 ? m.off - 0.025 : m.on + 0.065;
        burst.y = (top + (m.pitch - high) * spacing) * unit;
        if (t < end) burst.size = keys({{0, 0.8}, {0.0268592, 1.16}, {0.0956246, 1.0}}, t - m.on), burst.opacity = 1.0;
        else burst.size = keys({{0, 1.0}, {0.166667, 0.0}}, t - end), burst.opacity = keys({{0.0833333, 1.0}, {0.145833, 0.0}}, t - end);
    }
    return all;
}
