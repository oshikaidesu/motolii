// Measures the sound of an audio or video file.
//
// Provides the loudness over the length of the file, measured with GStreamer's level element.
// The file is decoded as fast as possible, not played. Also provides the strikes, the times
// where the sound gets suddenly louder, such as a drum or a clap. After Effects' Convert Audio
// to Keyframes reads the same loudness, and the strikes are where its curve jumps. Finally
// provides the sound as ISF audio inputs take it.
#pragma once
#include <gst/gst.h>
#include <gst/app/gstappsink.h>
#include "media/gstreamer_file_source.h"

#include <algorithm>
#include <map>
#include <memory>
#include <mutex>
#include <cmath>
#include <future>
#include <string>
#include <vector>

// Returns the loudness of the loudest channel of `file` in dB, where 0 is full scale, sampled
// every 1/rate seconds of the file's own time. Returns an empty list if no sound could be read.
static std::vector<float> sound_loudness(const char* file, double rate) {
    static const bool started = (gst_init(nullptr, nullptr), true);
    (void)started;
    std::vector<float> db;
    const std::string said = std::string("filesrc name=in ! decodebin ! audioconvert ! audio/x-raw ! level name=level post-messages=true interval=") +
                             std::to_string((guint64)(1e9 / rate)) + " ! fakesink sync=false";
    GError* wrong = nullptr;
    GstElement* reads = gst_parse_launch(said.c_str(), &wrong);
    if (wrong) g_error_free(wrong);
    if (!reads) return db;
    gst_read_from(reads, file);
    GstBus* bus = gst_element_get_bus(reads);
    gst_element_set_state(reads, GST_STATE_PLAYING);
    for (bool going = true; going;) {
        GstMessage* heard = gst_bus_timed_pop_filtered(bus, 10 * GST_SECOND, (GstMessageType)(GST_MESSAGE_ELEMENT | GST_MESSAGE_EOS | GST_MESSAGE_ERROR));
        if (!heard) break;
        if (GST_MESSAGE_TYPE(heard) != GST_MESSAGE_ELEMENT) going = false;
        else if (const GstStructure* s = gst_message_get_structure(heard); s && gst_structure_has_name(s, "level")) {
            const GValue* rms = gst_structure_get_value(s, "rms");
            float loudest = -100.f;
            G_GNUC_BEGIN_IGNORE_DEPRECATIONS
            if (rms && G_VALUE_HOLDS(rms, G_TYPE_VALUE_ARRAY)) {
                const GValueArray* each = (const GValueArray*)g_value_get_boxed(rms);
                for (guint c = 0; c < each->n_values; ++c) loudest = std::max(loudest, (float)g_value_get_double(g_value_array_get_nth((GValueArray*)each, c)));
            }
            G_GNUC_END_IGNORE_DEPRECATIONS
            db.push_back(std::max(loudest, -100.f));
        }
        gst_message_unref(heard);
    }
    gst_element_set_state(reads, GST_STATE_NULL);
    gst_object_unref(bus);
    gst_object_unref(reads);
    return db;
}

// Returns the strike times, in seconds of the file, found in the loudness list `db` that was
// sampled at `rate` per second. A strike is a point where the loudness grows by at least `rise`
// dB within 30 ms and is above -40 dB, so that it can be heard. After a strike, no other strike
// is reported for 120 ms.
static std::vector<double> sound_strikes(const std::vector<float>& db, double rate, double rise) {
    std::vector<double> at;
    const int near = std::max(1, (int)std::lround(0.03 * rate)), apart = std::max(1, (int)std::lround(0.12 * rate));
    int last = -apart;
    for (int i = 0; i < (int)db.size(); ++i) {
        if (i - last < apart || db[(size_t)i] < -40.f) continue;
        // Before the file begins there is silence.
        float low = i < near ? -100.f : db[(size_t)i];
        for (int j = std::max(0, i - near); j < i; ++j) low = std::min(low, db[(size_t)j]);
        if (db[(size_t)i] - low >= rise) at.push_back(i / rate), last = i;
    }
    return at;
}

// The sound of a file as ISF audio inputs take it, one channel for the whole length of the file.
// In the ISF specification an audio input is an image with one row per channel. In an "audio"
// input each column is one sample of the wave, centered on 0.5. In an "audioFFT" input each
// column is one value of the FFT. At each time the amount of data matches what VIDVOX's own ISF
// Editor gives an ISF (VVISF-GL, AudioController: fftQuality 512, and the wave is twice that).
struct SoundRead {
    // Samples of the wave, sound_rate per second, from -1 to 1.
    std::vector<float> wave;
    // Spectrum rows of sound_bands values, sound_rows rows per second. Values go from 0 at
    // minDecibels to 1 at maxDecibels.
    std::vector<float> fft;
};
static constexpr int sound_rate = 24000, sound_bands = 512, sound_rows = 60;
// Reads the sound of `file` once, decoding it at full speed.
//
// The spectrum comes from GStreamer's spectrum element, which posts "magnitude" with one value
// per band in dB, with values below the threshold set to the threshold. It is converted to what
// the Web's AnalyserNode returns (W3C Web Audio API 1.8.6, which Shadertoy's sound also uses):
// smoothed over time with smoothingTimeConstant 0.8, then scaled from minDecibels -100 and
// maxDecibels -30 to the range 0 to 1. The wave is taken from appsink, whose
// gst_app_sink_pull_sample returns NULL at the end of the stream.
static SoundRead sound_read(const std::string& file) {
    static const bool started = (gst_init(nullptr, nullptr), true);
    (void)started;
    SoundRead r;
    const std::string from = std::string("filesrc name=in ! decodebin ! audioconvert ! audioresample ! audio/x-raw,format=F32LE,channels=1,rate=") + std::to_string(sound_rate);
    // The defaults of AnalyserOptions: minDecibels, maxDecibels and smoothingTimeConstant.
    const double low = -100.0, high = -30.0, tau = 0.8;
    {
        GstElement* reads = gst_parse_launch((from + " ! spectrum name=s bands=" + std::to_string(sound_bands) + " threshold=" + std::to_string((int)low) + " interval=" + std::to_string((guint64)(1e9 / sound_rows)) + " post-messages=true message-magnitude=true ! fakesink sync=false").c_str(), nullptr);
        if (!reads) return r;
        gst_read_from(reads, file.c_str());
        GstBus* bus = gst_element_get_bus(reads);
        gst_element_set_state(reads, GST_STATE_PLAYING);
        // The smoothed values of the previous block, zero at first.
        std::vector<double> smooth((size_t)sound_bands, 0.0);
        for (bool going = true; going;) {
            GstMessage* heard = gst_bus_timed_pop_filtered(bus, 10 * GST_SECOND, (GstMessageType)(GST_MESSAGE_ELEMENT | GST_MESSAGE_EOS | GST_MESSAGE_ERROR));
            if (!heard) break;
            if (GST_MESSAGE_TYPE(heard) != GST_MESSAGE_ELEMENT) going = false;
            else if (const GstStructure* st = gst_message_get_structure(heard); st && gst_structure_has_name(st, "spectrum"))
                if (const GValue* mags = gst_structure_get_value(st, "magnitude"))
                    for (int i = 0; i < sound_bands; ++i) {
                        double& x = smooth[(size_t)i];
                        x = tau * x + (1.0 - tau) * std::pow(10.0, g_value_get_float(gst_value_list_get_value(mags, (guint)i)) / 20.0);
                        if (!std::isfinite(x)) x = 0.0;
                        r.fft.push_back((float)std::clamp((20.0 * std::log10(std::max(x, 1e-12)) - low) / (high - low), 0.0, 1.0));
                    }
            gst_message_unref(heard);
        }
        gst_element_set_state(reads, GST_STATE_NULL);
        gst_object_unref(bus), gst_object_unref(reads);
    }
    GstElement* reads = gst_parse_launch((from + " ! appsink name=out sync=false").c_str(), nullptr);
    if (!reads) return r;
    gst_read_from(reads, file.c_str());
    GstElement* out = gst_bin_get_by_name(GST_BIN(reads), "out");
    // If the pipeline cannot start, for example because the file does not exist, no end of
    // stream would ever arrive, so do not pull.
    const bool pulling = gst_element_set_state(reads, GST_STATE_PLAYING) != GST_STATE_CHANGE_FAILURE;
    while (GstSample* got = pulling ? gst_app_sink_pull_sample(GST_APP_SINK(out)) : nullptr) {
        GstMapInfo map;
        if (GstBuffer* b = gst_sample_get_buffer(got); b && gst_buffer_map(b, &map, GST_MAP_READ)) {
            const float* f = (const float*)map.data;
            r.wave.insert(r.wave.end(), f, f + map.size / sizeof(float));
            gst_buffer_unmap(b, &map);
        }
        gst_sample_unref(got);
    }
    gst_element_set_state(reads, GST_STATE_NULL);
    gst_object_unref(out), gst_object_unref(reads);
    return r;
}
// Returns the sound of `file`, read once in the background because reading takes as long as
// decoding the file. Returns null until the read has finished; the caller should treat that as
// silence. Each read runs under std::async and its future is kept. When the futures are
// destroyed at exit, each destructor waits for its read to finish ([futures.async]).
static const SoundRead* sound_of(const std::string& file) {
    static std::map<std::string, std::shared_future<SoundRead>> read;
    static std::mutex one;
    std::lock_guard<std::mutex> hold(one);
    auto found = read.find(file);
    if (found == read.end()) found = read.emplace(file, std::async(std::launch::async, sound_read, file).share()).first;
    return found->second.wait_for(std::chrono::seconds(0)) == std::future_status::ready ? &found->second.get() : nullptr;
}
// Returns what an ISF audio input reads at time `at`, in seconds of the file. `r` may be null.
// `fft` selects the spectrum; otherwise the wave is returned. `wide` is the number of values
// wanted, which is the MAX of the input; 0 means all of them. Follows VVISF-GL's
// AudioController. Each value is the mean of the neighboring values it covers (valsPerAvg),
// with the last group kept inside the range. The wave is the 1024 samples up to `at`, and each
// sample is mapped by (sample * 4 + 4) / 8. Returns silence when there is no data.
static std::vector<float> sound_at(const SoundRead* r, bool fft, int wide, double at) {
    const int raw = fft ? sound_bands : 2 * sound_bands;
    std::vector<float> v((size_t)std::clamp(wide > 0 ? wide : raw, 1, raw), fft ? 0.f : 0.5f);
    if (!r || at < 0) return v;
    std::vector<float> all((size_t)raw, fft ? 0.f : 0.5f);
    if (fft) {
        const long row = std::lround(at * sound_rows);
        if ((row + 1) * sound_bands > (long)r->fft.size()) return v;
        std::copy_n(r->fft.begin() + row * sound_bands, sound_bands, all.begin());
    } else {
        const long last = std::lround(at * sound_rate);
        for (int i = 0; i < raw; ++i)
            if (const long k = last - raw + 1 + i; k >= 0 && k < (long)r->wave.size()) all[(size_t)i] = (r->wave[(size_t)k] * 4.f + 4.f) / 8.f;
    }
    const int per = std::max(1, (int)std::lround((float)raw / (float)v.size()));
    for (int c = 0; c < (int)v.size(); ++c) {
        const int first = (c + 1) * per >= raw ? raw - per : c * per;
        double sum = 0;
        for (int i = 0; i < per; ++i) sum += all[(size_t)(first + i)];
        v[(size_t)c] = (float)(sum / per);
    }
    return v;
}
