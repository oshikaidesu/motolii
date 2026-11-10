// Plays the sound of layers while the canvas plays.
//
// Included after render.h, which defines Stage and Stage::Sound; not self-contained.
// The layers that have sound are listed in Stage::sounding, the same sounds that an exported
// video mixes. Each one gets a GStreamer playbin that plays only the audio of its file. The
// playbin is sought to the position that the current time gives inside the layer's cut and
// plays at the layer's speed. It is paused when the canvas is stopped or the layer is not on.
// It is sought again when it strays from the position it should have, because the cut looped,
// the playhead was moved, or the clocks drifted apart.
// If the environment variable MOTOLII_MUTE is set, everything runs as usual but at zero
// volume, so that checks can run on a desktop machine without noise.
#pragma once
#include <gst/gst.h>
#include <cmath>
#include <cstdlib>
#include <map>
#include <string>

// The player of one layer's sound.
struct Heard {
    GstElement* bin = nullptr;
    std::string file;
    // True while the player is playing.
    bool on = false;
    // The position in the file, in seconds, that the current time gives. It is -1 when the
    // sound is not to be heard.
    double wanted = -1.0;
};

// Computes the position in its file, in seconds, of a layer's sound at the time `now`, and
// stores it in `at`. The position follows the same rules as an exported video: the cut, the
// speed and the looping of the cut. Returns false if the sound is not heard at that time,
// before it comes on or after it ends.
static bool heard_where(const Stage::Sound& a, double now, double* at) {
    const double t = now - a.on;
    if (t < 0.0 || (a.lasts >= 0.0 && t > a.lasts)) return false;
    // `into` is the seconds of the file that have gone by since the start of the cut.
    const double fast = std::max(1e-3, std::fabs(a.speed)), into = (a.into + t) * fast;
    const double cut = a.to - a.from;
    *at = a.from + (cut > 0.0 ? std::fmod(into, cut) : into);
    return true;
}

// Returns the volume of a layer's sound at the time `now`. If the layer has volume keyframes
// (Stage::Sound::loud, sampled 30 times per second), the value is interpolated between the two
// nearest samples. Otherwise the layer's constant gain is returned.
static double heard_loud(const Stage::Sound& a, double now) {
    if (a.loud.empty()) return a.gain;
    const double i = std::clamp((now - a.on) * 30.0, 0.0, (double)a.loud.size() - 1.0);
    const size_t k = (size_t)i, k1 = std::min(k + 1, a.loud.size() - 1);
    return a.loud[k] + (a.loud[k1] - a.loud[k]) * (i - (double)k);
}

// Stops and releases the player of `h`, if it has one.
static void heard_off(Heard& h) {
    if (!h.bin) return;
    gst_element_set_state(h.bin, GST_STATE_NULL);
    gst_object_unref(h.bin);
    h.bin = nullptr;
}

// Reads from the document how every layer with sound should sound now. The document is held
// only while it is read.
static std::map<const void*, Stage::Sound> heard_told(Stage& s) {
    std::map<const void*, Stage::Sound> told;
    for (const auto& [who, tells] : s.sounding) told[who] = tells();
    return told;
}

// Updates the players once for each frame of the live canvas. Every layer with sound is
// played at the position that the current time `now` gives, or not at all. `told` is the
// result of heard_told and `all` holds the players. `playing` is false when the canvas is
// stopped. The players are sought and played without holding the document, which heard_told
// has already read.
static void heard(const std::map<const void*, Stage::Sound>& told, std::map<const void*, Heard>& all, double now, bool playing) {
    static const bool mute = std::getenv("MOTOLII_MUTE") != nullptr;
    // A layer that is gone, or no longer has sound, loses its player too.
    for (auto it = all.begin(); it != all.end();)
        if (!told.count(it->first)) heard_off(it->second), it = all.erase(it);
        else ++it;
    for (const auto& [who, a] : told) {
        Heard& h = all[who];
        if (h.bin && h.file != a.file) heard_off(h);
        // Create the player once per layer. It starts paused and plays only the sound.
        if (!h.bin) {
            h.bin = gst_element_factory_make("playbin", nullptr);
            if (!h.bin) continue;
            gchar* uri = gst_filename_to_uri(a.file.c_str(), nullptr);
            g_object_set(h.bin, "uri", uri, "flags", 0x2 /* GST_PLAY_FLAG_AUDIO: no picture */, nullptr);
            // When muted, send the sound to a fakesink that is synced to the clock. It runs as fast as
            // with the speakers but nobody hears it. The sink on the Mac takes no volume from playbin,
            // so the sink has to be replaced.
            if (mute) {
                GstElement* none = gst_element_factory_make("fakesink", nullptr);
                g_object_set(none, "sync", TRUE, nullptr);
                g_object_set(h.bin, "audio-sink", none, nullptr);
            }
            g_free(uri);
            gst_element_set_state(h.bin, GST_STATE_PAUSED);
            // Set flushing after the pipeline has left the NULL state, because leaving that state
            // stops the bus from flushing. Nobody reads the bus, so messages are dropped as they
            // arrive instead of being kept.
            GstBus* bus = gst_element_get_bus(h.bin);
            gst_bus_set_flushing(bus, TRUE);
            gst_object_unref(bus);
            h.file = a.file, h.on = false;
        }
        double at = 0.0;
        const bool on = playing && heard_where(a, now, &at);
        h.wanted = on ? at : -1.0;
        if (!on) {
            if (h.on) gst_element_set_state(h.bin, GST_STATE_PAUSED), h.on = false;
            continue;
        }
        gint64 is = -1;
        const bool where = gst_element_query_position(h.bin, GST_FORMAT_TIME, &is);
        // Seek when playback has just begun or has strayed more than 0.1 s from the wanted position.
        if (!h.on || !where || std::fabs((double)is / GST_SECOND - at) > 0.1) {
            // The first time, wait up to 200 ms for the player to become ready to be sought.
            if (!h.on) gst_element_get_state(h.bin, nullptr, nullptr, 200 * GST_MSECOND);
            gst_element_seek(h.bin, std::max(1e-3, std::fabs(a.speed)), GST_FORMAT_TIME, (GstSeekFlags)(GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_ACCURATE),
                             GST_SEEK_TYPE_SET, (gint64)(at * GST_SECOND), GST_SEEK_TYPE_NONE, -1);
        }
        // playbin's own volume, where 1 is unchanged. It follows the layer's volume.
        g_object_set(h.bin, "volume", std::clamp(heard_loud(a, now), 0.0, 10.0), nullptr);
        if (!h.on) gst_element_set_state(h.bin, GST_STATE_PLAYING), h.on = true;
    }
}
