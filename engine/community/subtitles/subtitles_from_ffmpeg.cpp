// subtitles_format and subtitles_as_ass: FFmpeg's own probe, demuxers,
// decoders, ASS encoder and ASS muxer, in the steps fftools takes for
// `ffmpeg -i in.srt out.ass` (do_subtitle_out and enc_open in
// fftools/ffmpeg_enc.c of FFmpeg 8).
#include <algorithm>
#include <cstring>
#include <vector>

#include "community/subtitles/subtitles.h"

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
}

namespace motolii {
namespace {

// The text as a file FFmpeg reads from memory.
struct Reading {
  const std::string& text;
  size_t at = 0;
};
int read_more(void* opaque, uint8_t* to, int most) {
  Reading& r = *(Reading*)opaque;
  const int n = (int)std::min<size_t>(most, r.text.size() - r.at);
  if (n <= 0) return AVERROR_EOF;
  std::memcpy(to, r.text.data() + r.at, n), r.at += n;
  return n;
}

// The demuxer FFmpeg's probe names for `text`, when it is sure enough
// (AVPROBE_SCORE_MAX / 4: LRC is told at 40 of 100 by lrc_probe in
// libavformat/lrcdec.c; JavaScript never above 2).
const AVInputFormat* probed(const std::string& text) {
  std::vector<uint8_t> head(
      text.begin(), text.begin() + std::min<size_t>(text.size(), 1 << 16));
  head.resize(head.size() + AVPROBE_PADDING_SIZE, 0);
  AVProbeData pd{};
  pd.buf = head.data(), pd.buf_size = (int)(head.size() - AVPROBE_PADDING_SIZE),
  pd.filename = "";
  int score = 0;
  const AVInputFormat* f = av_probe_input_format3(&pd, 1, &score);
  return score >= AVPROBE_SCORE_MAX / 4 ? f : nullptr;
}

// The text opened by FFmpeg with its first subtitle stream, or nullptr.
struct Opened {
  Reading reading;
  AVIOContext* io = nullptr;
  AVFormatContext* in = nullptr;
  int stream = -1;
  Opened(const std::string& text) : reading{text} {
    const AVInputFormat* f = probed(text);
    if (!f) return;
    io = avio_alloc_context((uint8_t*)av_malloc(4096), 4096, 0, &reading,
                            read_more, nullptr, nullptr);
    in = avformat_alloc_context(), in->pb = io;
    if (avformat_open_input(&in, "", f, nullptr) < 0) return;
    for (unsigned i = 0; i < in->nb_streams; ++i)
      if (in->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_SUBTITLE) {
        stream = (int)i;
        break;
      }
  }
  ~Opened() {
    avformat_close_input(&in);
    if (io) av_freep(&io->buffer), avio_context_free(&io);
  }
};

}  // namespace

std::string subtitles_format(const std::string& text) {
  Opened o(text);
  return o.stream < 0 ? "" : o.in->iformat->name;
}

std::string subtitles_as_ass(const std::string& text) {
  Opened o(text);
  if (o.stream < 0) return "";
  const AVStream* from = o.in->streams[o.stream];
  if (from->codecpar->codec_id == AV_CODEC_ID_ASS &&
      !std::strcmp(o.in->iformat->name, "ass"))
    return text;
  const AVCodec* decoder = avcodec_find_decoder(from->codecpar->codec_id);
  const AVCodec* encoder = avcodec_find_encoder(AV_CODEC_ID_ASS);
  AVCodecContext* dec = decoder ? avcodec_alloc_context3(decoder) : nullptr;
  AVCodecContext* enc = encoder ? avcodec_alloc_context3(encoder) : nullptr;
  AVFormatContext* out = nullptr;
  std::string ass;
  uint8_t* written = nullptr;
  if (!dec || !enc || avcodec_parameters_to_context(dec, from->codecpar) < 0 ||
      (dec->pkt_timebase = from->time_base,
       avcodec_open2(dec, decoder, nullptr)) < 0)
    goto done;
  // The decoder's [Script Info] and [V4+ Styles] become the encoder's
  // (enc_open), and subtitles are encoded in AV_TIME_BASE units.
  if (dec->subtitle_header) {
    enc->subtitle_header = (uint8_t*)av_mallocz(dec->subtitle_header_size + 1);
    std::memcpy(enc->subtitle_header, dec->subtitle_header,
                dec->subtitle_header_size);
    enc->subtitle_header_size = dec->subtitle_header_size;
  }
  enc->time_base = AV_TIME_BASE_Q;
  if (avcodec_open2(enc, encoder, nullptr) < 0 ||
      avformat_alloc_output_context2(&out, nullptr, "ass", nullptr) < 0)
    goto done;
  {
    AVStream* to = avformat_new_stream(out, nullptr);
    avcodec_parameters_from_context(to->codecpar, enc);
    to->time_base = AV_TIME_BASE_Q;
    if (avio_open_dyn_buf(&out->pb) < 0 ||
        avformat_write_header(out, nullptr) < 0)
      goto done;
    AVPacket* pkt = av_packet_alloc();
    std::vector<uint8_t> said(1 << 16);
    while (av_read_frame(o.in, pkt) >= 0) {
      AVSubtitle sub{};
      int got = 0;
      if (pkt->stream_index == o.stream &&
          avcodec_decode_subtitle2(dec, &sub, &got, pkt) >= 0 && got &&
          sub.pts != AV_NOPTS_VALUE) {
        // start_display_time is required to be 0 (do_subtitle_out).
        const int64_t pts = sub.pts;
        sub.pts +=
            av_rescale_q(sub.start_display_time, {1, 1000}, AV_TIME_BASE_Q);
        sub.end_display_time -= sub.start_display_time,
            sub.start_display_time = 0;
        const int n =
            avcodec_encode_subtitle(enc, said.data(), (int)said.size(), &sub);
        if (n > 0) {
          AVPacket* one = av_packet_alloc();
          av_new_packet(one, n), std::memcpy(one->data, said.data(), n);
          one->pts = one->dts =
              av_rescale_q(pts, AV_TIME_BASE_Q, to->time_base);
          one->duration =
              av_rescale_q(sub.end_display_time, {1, 1000}, to->time_base);
          av_interleaved_write_frame(out, one), av_packet_free(&one);
        }
      }
      if (got) avsubtitle_free(&sub);
      av_packet_unref(pkt);
    }
    av_packet_free(&pkt);
    av_write_trailer(out);
    const int size = avio_close_dyn_buf(out->pb, &written);
    out->pb = nullptr;
    ass.assign((const char*)written, size), av_free(written);
  }
done:
  if (out) avformat_free_context(out);
  avcodec_free_context(&enc), avcodec_free_context(&dec);
  return ass;
}

}  // namespace motolii
