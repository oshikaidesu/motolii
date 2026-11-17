#include "media/video_datamosh.h"

#include "base/cache_folder.h"
#include "base/hash.h"
#include "base/video_encoder.h"

#ifdef _WIN32
#include <fstream>

#include "base/posix.h"
#else
#include <sys/stat.h>
#endif

#include <atomic>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <map>
#include <mutex>
#include <string>
#include <system_error>
#include <thread>

namespace motolii {

std::atomic<bool> mosh_done{false};

namespace {

#ifndef _WIN32
// Returns `name` quoted for a shell.
std::string mosh_quoted(std::string name) {
  for (size_t at = 0; (at = name.find('\'', at)) != std::string::npos; at += 4)
    name.replace(at, 1, "'\\''");
  return "'" + name + "'";
}
#endif

#ifdef _WIN32
// What ffprobe says of the first video stream of `film` for `entries`, its last line break dropped.
std::string mosh_probe(const std::string& film, const char* entries, const char* format) {
  std::string said;
  if (FILE* from = popen(("ffprobe -v error -select_streams v:0 -show_entries " + std::string(entries) + " -of " +
                          format + " " + shell_quoted(film))
                             .c_str(),
                         "r")) {
    char block[256];
    for (size_t n; (n = std::fread(block, 1, sizeof block, from)) > 0;) said.append(block, n);
    pclose(from);
  }
  while (!said.empty() && (said.back() == '\n' || said.back() == '\r')) said.pop_back();
  return said;
}

// The steps of mosh_file's zsh line, for Windows, which has no zsh: one ffmpeg at a time, each its own cmd line.
// True if out.mp4 was made in `work`.
bool mosh_steps(const std::string& film, const std::string& with, double at, const std::filesystem::path& work) {
  const auto in = [&](const char* file) { return shell_quoted((work / file).generic_string()); };
  const std::string like = mosh_probe(film, "stream=width,height", "csv=s=x:p=0"),
                    rate = mosh_probe(film, "stream=r_frame_rate", "csv=p=0");
  const size_t x = like.find('x');
  const std::string w = like.substr(0, x), h = x == std::string::npos ? "" : like.substr(x + 1);
  const std::string ffmpeg = "ffmpeg -nostdin -hide_banner -loglevel error -y ",
                    enc = " -an -c:v mpeg4 -bf 0 -g 100000 -q:v 3 ";
  std::ofstream(work / "list.txt") << "file 'a.avi'\nfile 'b.avi'\n";
  bool ok = !w.empty() && !h.empty() && !rate.empty();
  for (const std::string& step :
       {ffmpeg + "-i " + shell_quoted(film) + " -t " + std::to_string(at) + " -vf fps=" + rate + enc + in("a.avi"),
        ffmpeg + "-i " + shell_quoted(with) + " -vf \"fps=" + rate + ",scale=" + w + ":" + h +
            ":force_original_aspect_ratio=decrease,pad=" + w + ":" + h + ":(ow-iw)/2:(oh-ih)/2\"" + enc + in("b.avi"),
        ffmpeg + "-f concat -safe 0 -i " + in("list.txt") + " -c copy " + in("both.avi"),
        ffmpeg + "-i " + in("both.avi") + " -c copy -bsf:v \"noise=drop='key*gt(n\\,0)'\" " + in("moshed.avi"),
        ffmpeg + "-i " + in("moshed.avi") + " -c:v " + h264_encoder_here() + h264_quality(h264_encoder_here(), 0.0) +
            "-pix_fmt yuv420p " + in("out.mp4")})
    ok = ok && shell(step) == 0;
  return ok;
}
#endif

}  // namespace

std::string mosh_file(const std::string& film, double at,
                      const std::string& with) {
  static std::mutex lock;
  // State by output path: 1 is being made, 2 is made, 3 could not be made.
  static std::map<std::string, int> asked;
  std::string key = film + "|" + with + "|" + std::to_string(at);
  for (const std::string& f : {film, with}) {
#ifdef _WIN32  // (no st_mtimespec: the file's time in 100 ns steps)
    std::error_code e;
    const auto when = std::filesystem::last_write_time(f, e);
    const auto size = std::filesystem::file_size(f, e);
    if (!e)
      key += "|" + std::to_string((long long)when.time_since_epoch().count()) + "." + std::to_string(size);
#else
    struct stat st{};
    if (stat(f.c_str(), &st) == 0)
      key += "|" + std::to_string(st.st_mtimespec.tv_sec) + "." +
             std::to_string(st.st_size);
#endif
  }
  const uint64_t hash = fnv1a64(key);
  const std::filesystem::path dir = cache_folder("mosh");
  char name[40];
  std::snprintf(name, sizeof name, "%016llx.mp4", (unsigned long long)hash);
  const std::string out = (dir / name).generic_string();
  std::error_code e;
  if (std::filesystem::exists(out, e)) return out;
  std::lock_guard<std::mutex> hold(lock);
  if (asked[out]) return "";
  asked[out] = 1;
  std::filesystem::create_directories(dir, e);
  std::thread([film, with, at, out,
               work = (dir / (std::string(name) + ".d")).generic_string()] {
    std::error_code e;
    std::filesystem::create_directories(work, e);
#ifdef _WIN32
    bool ok = mosh_steps(film, with, at, work);
    if (ok) std::filesystem::rename(std::filesystem::path(work) / "out.mp4", out, e), ok = !e;
#else
    const std::string w = mosh_quoted(work);
    // Encode both videos as MPEG-4 part 2 in AVI with a single keyframe each,
    // no B-frames, and the size and frame rate of the first. Then join them
    // without re-encoding, drop every keyframe except the first, and decode
    // once more into a video that any player can play.
    const std::string like =
        "$(ffprobe -v error -select_streams v:0 -show_entries "
        "stream=width,height -of csv=s=x:p=0 " +
        mosh_quoted(film) + ")";
    const std::string rate =
        "$(ffprobe -v error -select_streams v:0 -show_entries "
        "stream=r_frame_rate -of csv=p=0 " +
        mosh_quoted(film) + ")";
    const std::string enc = " -an -c:v mpeg4 -bf 0 -g 100000 -q:v 3 ";
    const std::string cmd =
        "set -e; cd " + w + "; S=" + like +
        "; W=${S%x*}; H=${S#*x}; R=" + rate +
        "; "
        "ffmpeg -nostdin -hide_banner -loglevel error -y -i " +
        mosh_quoted(film) + " -t " + std::to_string(at) + " -vf fps=$R" + enc +
        "a.avi; "
        "ffmpeg -nostdin -hide_banner -loglevel error -y -i " +
        mosh_quoted(with) +
        " -vf "
        "\"fps=$R,scale=$W:$H:force_original_aspect_ratio=decrease,pad=$W:$H:("
        "ow-iw)/2:(oh-ih)/2\"" +
        enc +
        "b.avi; "
        "printf \"file 'a.avi'\\nfile 'b.avi'\\n\" > list.txt; "
        "ffmpeg -nostdin -hide_banner -loglevel error -y -f concat -safe 0 -i "
        "list.txt -c copy both.avi; "
        "ffmpeg -nostdin -hide_banner -loglevel error -y -i both.avi -c copy "
        "-bsf:v \"noise=drop='key*gt(n\\,0)'\" moshed.avi; "
        "ffmpeg -nostdin -hide_banner -loglevel error -y -i moshed.avi -c:v " +
        h264_encoder_here() + h264_quality(h264_encoder_here(), 0.0) +
        "-pix_fmt yuv420p out.mp4; "
        "mv out.mp4 " +
        mosh_quoted(out);
    const bool ok =
        std::system(("/bin/zsh -c " + mosh_quoted(cmd)).c_str()) == 0;
#endif
    std::filesystem::remove_all(work, e);
    if (!ok)
      std::fprintf(stderr, "the datamosh of %s could not be built\n",
                   film.c_str());
    mosh_done = true;
  }).detach();
  return "";
}

}  // namespace motolii
