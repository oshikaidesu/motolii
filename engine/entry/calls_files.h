// calls_files.h: part of motolii.mm. Read only through motolii.mm. Files read with no document: a film's small pictures, what a media file is (GStreamer's discoverer), a font's kinds (CoreText).
// A film's first picture as a small .png: GStreamer's own line for it (decode, scale, into a .png), held at its first
// picture, which is taken and written. It asks nothing of a stage, so a shell may call it from another thread.
// (fraction: where in the film, 0 to 1; a picture there, not the first: a hand moving over a tile looks along the film;
//  or, seconds given (0 or more), so many seconds in: a bar on the timeline shows the pictures it plays)
static int thumbnail_at(const char* video, const char* png, int wide, double fraction, double seconds = -1.0) {
    gst_init(nullptr, nullptr);
    gchar* uri = gst_filename_to_uri(video, nullptr);
    if (!uri) return 0;
    gchar* line = g_strdup_printf("uridecodebin uri=\"%s\" ! videoconvert ! videoscale ! video/x-raw,width=%d,pixel-aspect-ratio=1/1 ! pngenc ! appsink name=out", uri, wide);
    GstElement* pipeline = gst_parse_launch(line, nullptr);
    g_free(line), g_free(uri);
    if (!pipeline) return 0;
    GstElement* out = gst_bin_get_by_name(GST_BIN(pipeline), "out");
    gst_element_set_state(pipeline, GST_STATE_PAUSED);
    GstSample* first = gst_app_sink_try_pull_preroll(GST_APP_SINK(out), 4 * GST_SECOND);
    if (first && seconds > 0.0) {
        gst_sample_unref(first);
        gst_element_seek_simple(pipeline, GST_FORMAT_TIME, (GstSeekFlags)(GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_ACCURATE), (gint64)(seconds * (double)GST_SECOND));
        first = gst_app_sink_try_pull_preroll(GST_APP_SINK(out), 4 * GST_SECOND);
    } else if (first && fraction > 0.0) {
        gint64 length = 0;
        if (gst_element_query_duration(pipeline, GST_FORMAT_TIME, &length) && length > 0) {
            gst_sample_unref(first);
            gst_element_seek_simple(pipeline, GST_FORMAT_TIME, (GstSeekFlags)(GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_ACCURATE), (gint64)(std::min(fraction, 0.98) * (double)length));
            first = gst_app_sink_try_pull_preroll(GST_APP_SINK(out), 4 * GST_SECOND);
        }
    }
    bool done = false;
    GstMapInfo bytes;
    if (first && gst_buffer_map(gst_sample_get_buffer(first), &bytes, GST_MAP_READ)) {
        done = g_file_set_contents(png, (const gchar*)bytes.data, (gssize)bytes.size, nullptr);
        gst_buffer_unmap(gst_sample_get_buffer(first), &bytes);
    }
    if (first) gst_sample_unref(first);
    gst_element_set_state(pipeline, GST_STATE_NULL);
    gst_object_unref(out);
    gst_object_unref(pipeline);
    return done;
}
int motolii_thumbnail_at(const char* video, const char* png, int wide, double fraction) { return thumbnail_at(video, png, wide, fraction); }
int motolii_thumbnail_seconds(const char* video, const char* png, int wide, double seconds) { return thumbnail_at(video, png, wide, 0.0, seconds); }
// What a media file is, as GStreamer's discoverer tells it (gst-discoverer-1.0's own): "wide high rate seconds format",
// its first picture's size, pictures a second (0: a still), how long (0: a still), its container or kind as GStreamer
// names it; "" when it cannot be read. Asks nothing of a document.
const char* motolii_media_info(const char* file) {
    static thread_local std::string out;
    out.clear();
    gst_init(nullptr, nullptr);
    GstDiscoverer* discoverer = gst_discoverer_new(20 * GST_SECOND, nullptr);   // (gst-discoverer-1.0's own is 10; a busy CI Mac passed 5, here on an isolate of its own)
    // A picture is read by a decoder of software (jpegdec, pngdec): VideoToolbox's vtdec_hw is ranked above jpegdec, and
    // to tell a JPEG's size it opened a GL context and asked for the hardware scaler, which a CI Mac's VM has not
    // ("IOServiceMatchingfailed for: AppleM2ScalerParavirtDriver", where the Media test has waited since 8bc43caa6). A
    // film keeps VideoToolbox: there is no software HEVC here. uridecodebin's autoplug-select and GStreamer 1.18's
    // HARDWARE factory type; the discoverer's uridecodebin is its source's parent at source-setup.
    if (discoverer) g_signal_connect(discoverer, "source-setup", G_CALLBACK(+[](GstDiscoverer*, GstElement* source, gpointer) {
        if (GstObject* bin = gst_object_get_parent(GST_OBJECT(source))) {
            g_signal_connect(bin, "autoplug-select", G_CALLBACK(+[](GstElement*, GstPad*, GstCaps* caps, GstElementFactory* f, gpointer) -> gint {
                const bool still = gst_caps_get_size(caps) > 0 && g_str_has_prefix(gst_structure_get_name(gst_caps_get_structure(caps, 0)), "image/");
                return still && gst_element_factory_list_is_type(f, GST_ELEMENT_FACTORY_TYPE_HARDWARE) ? 2 : 0;   // (GST_AUTOPLUG_SELECT_SKIP, TRY: decodebin's enum)
            }), nullptr);
            gst_object_unref(bin);
        }
    }), nullptr);
    gchar* uri = gst_filename_to_uri(file, nullptr);
    GstDiscovererInfo* info = discoverer && uri ? gst_discoverer_discover_uri(discoverer, uri, nullptr) : nullptr;
    if (info && gst_discoverer_info_get_result(info) != GST_DISCOVERER_OK) g_object_unref(info), info = nullptr;   // (not there, or not media: nothing said)
    if (info) {
        unsigned wide = 0, high = 0, num = 0, den = 1;
        GList* streams = gst_discoverer_info_get_video_streams(info);
        if (streams) {
            GstDiscovererVideoInfo* v = (GstDiscovererVideoInfo*)streams->data;
            wide = gst_discoverer_video_info_get_width(v), high = gst_discoverer_video_info_get_height(v);
            if (!gst_discoverer_video_info_is_image(v)) num = gst_discoverer_video_info_get_framerate_num(v), den = std::max(1u, gst_discoverer_video_info_get_framerate_denom(v));
        }
        std::string kind;
        if (GstDiscovererStreamInfo* top = gst_discoverer_info_get_stream_info(info)) {
            if (GstCaps* caps = gst_discoverer_stream_info_get_caps(top)) {
                gchar* said = gst_pb_utils_get_codec_description(caps);
                if (said) kind = said, g_free(said);
                gst_caps_unref(caps);
            }
            gst_discoverer_stream_info_unref(top);
        }
        char line[512];
        std::snprintf(line, sizeof line, "%u %u %g %g %s", wide, high, (double)num / den, (double)gst_discoverer_info_get_duration(info) / GST_SECOND, kind.c_str());
        out = line;
        gst_discoverer_stream_info_list_free(streams), g_object_unref(info);
    }
    g_free(uri);
    if (discoverer) g_object_unref(discoverer);
    return out.c_str();
}
// A font file's kinds, as CoreText reads them (its own: the file's family class and traits): serif, sans, script,
// mono, bold, light, italic, symbols, ornaments, space separated; "" for none.
const char* motolii_font_tags(const char* path) {
    static thread_local std::string out;
    out.clear();
    CFURLRef url = CFURLCreateFromFileSystemRepresentation(nullptr, (const UInt8*)path, (CFIndex)std::strlen(path), false);
    CFArrayRef all = url ? CTFontManagerCreateFontDescriptorsFromURL(url) : nullptr;
    if (all && CFArrayGetCount(all) > 0) {
        CTFontDescriptorRef one = (CTFontDescriptorRef)CFArrayGetValueAtIndex(all, 0);
        CFDictionaryRef traits = (CFDictionaryRef)CTFontDescriptorCopyAttribute(one, kCTFontTraitsAttribute);
        if (traits) {
            SInt32 symbolic = 0;
            float weight = 0.f;
            if (CFNumberRef n = (CFNumberRef)CFDictionaryGetValue(traits, kCTFontSymbolicTrait)) CFNumberGetValue(n, kCFNumberSInt32Type, &symbolic);
            if (CFNumberRef n = (CFNumberRef)CFDictionaryGetValue(traits, kCTFontWeightTrait)) CFNumberGetValue(n, kCFNumberFloatType, &weight);
            const uint32_t kind = ((uint32_t)symbolic & kCTFontClassMaskTrait) >> kCTFontClassMaskShift;
            if (kind >= 1 && kind <= 7) out += "serif ";
            else if (kind == 8) out += "sans ";
            else if (kind == 9) out += "ornaments ";
            else if (kind == 10) out += "script ";
            else if (kind == 12) out += "symbols ";
            if ((uint32_t)symbolic & kCTFontMonoSpaceTrait) out += "mono ";
            if ((uint32_t)symbolic & kCTFontBoldTrait || weight > 0.3f) out += "bold ";
            if (weight < -0.3f) out += "light ";
            if ((uint32_t)symbolic & kCTFontItalicTrait) out += "italic ";
            CFRelease(traits);
        }
        // (the letters beyond Latin it has, as CoreText says its languages; each named as the Mac names it in English)
        if (CFArrayRef langs = (CFArrayRef)CTFontDescriptorCopyAttribute(one, kCTFontLanguagesAttribute)) {
            CFLocaleRef english = CFLocaleCreate(nullptr, CFSTR("en"));
            for (const char* code : {"ja", "ko", "zh", "ru", "el", "ar", "he", "th", "hi"}) {
                CFStringRef c = CFStringCreateWithCString(nullptr, code, kCFStringEncodingUTF8);
                bool has = false;
                for (CFIndex i = 0; i < CFArrayGetCount(langs) && !has; ++i) {   // (the language itself, or one of its scripts: "zh-Hans", not another that begins so, "arn")
                    CFStringRef l = (CFStringRef)CFArrayGetValueAtIndex(langs, i);
                    has = CFStringCompare(l, c, 0) == kCFCompareEqualTo || (CFStringHasPrefix(l, c) && CFStringGetLength(l) > CFStringGetLength(c) && CFStringGetCharacterAtIndex(l, CFStringGetLength(c)) == '-');
                }
                if (has) if (CFStringRef name = CFLocaleCopyDisplayNameForPropertyValue(english, kCFLocaleLanguageCode, c)) {
                    char said[64] = "";
                    CFStringGetCString(name, said, sizeof said, kCFStringEncodingUTF8);
                    for (char* ch = said; *ch; ++ch) *ch = (char)std::tolower((unsigned char)*ch);
                    out += std::string(said) + " ";
                    CFRelease(name);
                }
                CFRelease(c);
            }
            CFRelease(english);
            CFRelease(langs);
        }
    }
    if (all) CFRelease(all);
    if (url) CFRelease(url);
    if (!out.empty()) out.pop_back();
    return out.c_str();
}
