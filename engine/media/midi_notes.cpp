#include "media/midi_notes.h"

#include <gst/app/gstappsink.h>
#include <gst/gst.h>

#include <algorithm>
#include <cmath>
#include <fstream>
#include <iterator>
#include <map>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

#include "media/gstreamer_file_source.h"

std::vector<MidiEvent> midi_events(const char* file) {
  static const bool started = (gst_init(nullptr, nullptr), true);
  (void)started;
  std::vector<MidiEvent> events;
  bool pulling = true;
  GstElement* reads = gst_parse_launch(
      "filesrc name=in ! midiparse ! appsink name=out sync=false", nullptr);
  if (!reads) return events;
  gst_read_from(reads, file);
  GstElement* out = gst_bin_get_by_name(GST_BIN(reads), "out");
  // If the pipeline cannot start, for example because the file does not exist,
  // no end of stream would ever arrive, so do not pull.
  if (gst_element_set_state(reads, GST_STATE_PLAYING) ==
      GST_STATE_CHANGE_FAILURE)
    pulling = false;
  while (GstSample* got =
             pulling ? gst_app_sink_pull_sample(GST_APP_SINK(out)) : nullptr) {
    GstBuffer* b = gst_sample_get_buffer(got);
    GstMapInfo map;
    if (b && GST_BUFFER_PTS_IS_VALID(b) &&
        gst_buffer_map(b, &map, GST_MAP_READ)) {
      const int status = map.size >= 3 ? map.data[0] & 0xf0 : 0;
      if (status == 0x80 || status == 0x90)
        events.push_back({(double)GST_BUFFER_PTS(b) / (double)GST_SECOND,
                          status == 0x90 && map.data[2] > 0, map.data[0] & 0x0f,
                          map.data[1], map.data[2]});
      gst_buffer_unmap(b, &map);
    }
    gst_sample_unref(got);
  }
  gst_element_set_state(reads, GST_STATE_NULL);
  gst_object_unref(out), gst_object_unref(reads);
  return events;
}

std::map<double, double> midi_keys(const std::vector<MidiEvent>& events,
                                   const std::string& kind, int channel) {
  std::map<double, double> keys;
  if (kind != "velocity" && kind != "pitch" && kind != "count" &&
      kind != "on" && kind != "bool")
    return keys;
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
      const double is = kind == "velocity" ? e.velocity / 127.0
                        : kind == "pitch"  ? e.pitch
                        : kind == "count"  ? count
                        : kind == "on"     ? 1
                                           : count % 2;
      keys[e.at] = is;
    } else if (kind == "velocity")
      keys[std::max(0.0, e.at - min_interval)] = e.velocity / 127.0;
    else if (kind == "on")
      keys[e.at] = 0;
    last = e.at, last_off = !e.on;
  }
  if (keys.empty()) return keys;
  if ((kind == "velocity" || kind == "on" || kind == "count") &&
      !keys.count(0.0))
    keys[0.0] = 0;
  return keys;
}

double midi_bpm(const char* file) {
  std::ifstream in(file, std::ios::binary);
  const std::string b((std::istreambuf_iterator<char>(in)),
                      std::istreambuf_iterator<char>());
  const size_t at = b.find("\xff\x51\x03");
  if (at == std::string::npos || at + 6 > b.size()) return 120.0;
  const double us =
      (double)(((unsigned char)b[at + 3] << 16) |
               ((unsigned char)b[at + 4] << 8) | (unsigned char)b[at + 5]);
  return us > 0 ? 60e6 / us : 120.0;
}

double midi_spacing(const std::vector<MidiEvent>& events) {
  int low = 127, high = 0;
  for (const MidiEvent& e : events)
    if (e.on) low = std::min(low, e.pitch), high = std::max(high, e.pitch);
  return 688.0 / std::max(1, high - low);
}

const std::vector<MidiNote>& midi_of(const std::string& file) {
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
    if (auto was = sounding.find(key); was != sounding.end())
      notes[was->second].off = e.at, sounding.erase(was);
    if (e.on)
      sounding[key] = notes.size(),
      notes.push_back({e.at, -1, e.pitch, e.velocity});
  }
  for (MidiNote& n : notes)
    if (n.off < n.on) n.off = n.on + 0.1;
  return read.emplace(file, std::move(notes)).first->second;
}

std::vector<ScriptCopy> midi_copies(const std::vector<MidiNote>& notes, int n,
                                    double t, double unit, double roll) {
  std::vector<ScriptCopy> all((size_t)std::max(n, 0));
  for (ScriptCopy& c : all) c.opacity = 0.0;
  int low = 127, high = 0;
  for (const MidiNote& m : notes)
    low = std::min(low, m.pitch), high = std::max(high, m.pitch);
  // Same row height as midi_spacing for these notes. `top` places the middle of
  // the highest row at the middle of the roll's highest row.
  const double spacing = 688.0 / std::max(1, high - low),
               top = roll > 0 ? 0.5 * roll - 0.5 * spacing : 0.0;
  // Linear interpolation between keys, like a Godot animation track.
  const auto keys = [](const std::vector<std::pair<double, double>>& k,
                       double x) {
    if (x <= k.front().first) return k.front().second;
    for (size_t i = 1; i < k.size(); ++i)
      if (x <= k[i].first)
        return k[i - 1].second + (k[i].second - k[i - 1].second) *
                                     (x - k[i - 1].first) /
                                     (k[i].first - k[i - 1].first);
    return k.back().second;
  };
  for (int i = 0; i < (int)notes.size() && i < n; ++i) {
    const MidiNote& m = notes[(size_t)i];
    if (t < m.on) continue;
    ScriptCopy& burst = all[(size_t)i];
    // The burst ends when note_effect.gd's Timer fires.
    const double end = m.off - m.on > 0.09 ? m.off - 0.025 : m.on + 0.065;
    burst.y = (top + (m.pitch - high) * spacing) * unit;
    if (t < end)
      burst.size =
          keys({{0, 0.8}, {0.0268592, 1.16}, {0.0956246, 1.0}}, t - m.on),
      burst.opacity = 1.0;
    else
      burst.size = keys({{0, 1.0}, {0.166667, 0.0}}, t - end),
      burst.opacity = keys({{0.0833333, 1.0}, {0.145833, 0.0}}, t - end);
  }
  return all;
}
