// Tests for h264_encoder() and h264_quality() in base/video_encoder.h.
//
// The expected values come from the contract written above those functions:
// a listing line is six flag characters, a name and a description; the first
// flag is V for video; the answer is the first of the eight listed names that
// is a video encoder in the listing, or "".

#include "base/video_encoder.h"

#include <gtest/gtest.h>

#include <string>

namespace motolii {
namespace {

// The lines ffmpeg prints before the first encoder.
const std::string kBanner =
    "Encoders:\n V..... = Video\n A..... = Audio\n S..... = Subtitle\n"
    " .F.... = Frame-level multithreading\n ------\n";

std::string video(const std::string& n) { return " V....D " + n + "   " + n + " H.264\n"; }
std::string audio(const std::string& n) { return " A....D " + n + "   " + n + " audio\n"; }

TEST(VideoEncoder, MacListingPrefersVideoToolboxOverLibx264) {
  std::string listing = kBanner + video("libx264") + audio("aac") +
                        video("h264_videotoolbox") + video("libopenh264");
  EXPECT_EQ(h264_encoder(listing), "h264_videotoolbox");
}

TEST(VideoEncoder, OnlyLibx264) {
  EXPECT_EQ(h264_encoder(kBanner + video("mpeg4") + video("libx264")),
            "libx264");
}

TEST(VideoEncoder, OnlyLibopenh264) {
  EXPECT_EQ(h264_encoder(kBanner + video("libopenh264") + audio("aac")),
            "libopenh264");
}

TEST(VideoEncoder, HardwareEncodersFollowTheListedOrder) {
  // Later names come first in each listing, so the contract's order decides.
  std::string rest = video("libx264") + video("libopenh264");
  std::string vaapi = video("h264_vaapi") + rest;
  std::string mf = video("h264_mf") + vaapi;
  std::string amf = video("h264_amf") + mf;
  std::string qsv = video("h264_qsv") + amf;
  std::string nvenc = video("h264_nvenc") + qsv;
  EXPECT_EQ(h264_encoder(vaapi), "h264_vaapi");
  EXPECT_EQ(h264_encoder(mf), "h264_mf");
  EXPECT_EQ(h264_encoder(amf), "h264_amf");
  EXPECT_EQ(h264_encoder(qsv), "h264_qsv");
  EXPECT_EQ(h264_encoder(nvenc), "h264_nvenc");
}

TEST(VideoEncoder, NameOnlyInADescriptionDoesNotCount) {
  std::string listing = kBanner + " V....D mpeg4   like h264_nvenc, not it\n" +
                        video("libx264");
  EXPECT_EQ(h264_encoder(listing), "libx264");
}

TEST(VideoEncoder, NameOnAnAudioLineDoesNotCount) {
  EXPECT_EQ(h264_encoder(kBanner + audio("h264_nvenc") + video("libx264")),
            "libx264");
  EXPECT_EQ(h264_encoder(kBanner + audio("libx264")), "");
}

TEST(VideoEncoder, LongerNameContainingTheWantedOneDoesNotCount) {
  std::string listing = kBanner + video("h264_videotoolbox_extra") +
                        video("xlibx264") + video("libx264_rgb");
  EXPECT_EQ(h264_encoder(listing), "");
  EXPECT_EQ(h264_encoder(listing + video("libx264")), "libx264");
}

TEST(VideoEncoder, EmptyListingGivesNothing) {
  EXPECT_EQ(h264_encoder(""), "");
  EXPECT_EQ(h264_encoder(kBanner), "");
}
TEST(VideoEncoder, BannerAndLegendLinesAreSkipped) {
  EXPECT_EQ(h264_encoder("\n\n  \nsurprise\n" + kBanner +
                         video("h264_nvenc")),
            "h264_nvenc");
}

TEST(VideoEncoder, CrlfLineEndings) {
  std::string listing =
      "Encoders:\r\n V..... = Video\r\n ------\r\n"
      " V....D libx264              libx264 H.264\r\n"
      " V....D h264_videotoolbox    VideoToolbox H.264 Encoder\r\n";
  EXPECT_EQ(h264_encoder(listing), "h264_videotoolbox");
  EXPECT_EQ(h264_encoder(" V....D libx264\r\n"), "libx264");
}

TEST(VideoEncoder, QualityOfVideoToolbox) {
  EXPECT_EQ(h264_quality("h264_videotoolbox", 0.0), " -q:v 68 ");
  EXPECT_EQ(h264_quality("h264_videotoolbox", -1.0), " -q:v 68 ");
  std::string m = std::to_string(0.5);
  EXPECT_EQ(h264_quality("h264_videotoolbox", 0.5), " -b:v " + m + "M -maxrate " + m + "M ");
}

TEST(VideoEncoder, QualityOfLibx264) {
  EXPECT_EQ(h264_quality("libx264", 0.0), " -crf 17 ");
  std::string m = std::to_string(12.5);
  EXPECT_EQ(h264_quality("libx264", 12.5),
            " -b:v " + m + "M -maxrate " + m + "M ");
}

TEST(VideoEncoder, QualityOfAnyOtherNameIsOnlyABitrate) {
  auto rate = [](double m) { return " -b:v " + std::to_string(m) + "M "; };
  EXPECT_EQ(h264_quality("h264_nvenc", 0.0), rate(8.0));
  EXPECT_EQ(h264_quality("libopenh264", -3.0), rate(8.0));
  EXPECT_EQ(h264_quality("whatever", 0.5), rate(0.5));
  EXPECT_EQ(h264_quality("", 20.0), rate(20.0));
}

}  // namespace
}  // namespace motolii
