#include "media/video_datamosh.h"

#include <sys/stat.h>

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

std::atomic<bool> mosh_done{false};

namespace {

// Returns `name` quoted for a shell.
std::string mosh_quoted(std::string name) {
  for (size_t at = 0; (at = name.find('\'', at)) != std::string::npos; at += 4)
    name.replace(at, 1, "'\\''");
  return "'" + name + "'";
}

}  // namespace

std::string mosh_file(const std::string& film, double at,
                      const std::string& with) {
  static std::mutex lock;
  // State by output path: 1 is being made, 2 is made, 3 could not be made.
  static std::map<std::string, int> asked;
  std::string key = film + "|" + with + "|" + std::to_string(at);
  for (const std::string& f : {film, with}) {
    struct stat st{};
    if (stat(f.c_str(), &st) == 0)
      key += "|" + std::to_string(st.st_mtimespec.tv_sec) + "." +
             std::to_string(st.st_size);
  }
  uint64_t hash = 1469598103934665603ull;
  for (unsigned char c : key) hash = (hash ^ c) * 1099511628211ull;
  const char* home = std::getenv("HOME");
  const std::filesystem::path dir =
      std::filesystem::path(home ? home : "/tmp") /
      "Library/Caches/Motolii/mosh";
  char name[40];
  std::snprintf(name, sizeof name, "%016llx.mp4", (unsigned long long)hash);
  const std::string out = (dir / name).string();
  std::error_code e;
  if (std::filesystem::exists(out, e)) return out;
  std::lock_guard<std::mutex> hold(lock);
  if (asked[out]) return "";
  asked[out] = 1;
  std::filesystem::create_directories(dir, e);
  std::thread([film, with, at, out,
               work = (dir / (std::string(name) + ".d")).string()] {
    std::error_code e;
    std::filesystem::create_directories(work, e);
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
        "ffmpeg -nostdin -hide_banner -loglevel error -y -i moshed.avi -c:v "
        "libx264 -pix_fmt yuv420p -crf 16 out.mp4; "
        "mv out.mp4 " +
        mosh_quoted(out);
    const bool ok =
        std::system(("/bin/zsh -c " + mosh_quoted(cmd)).c_str()) == 0;
    std::filesystem::remove_all(work, e);
    if (!ok)
      std::fprintf(stderr, "the datamosh of %s could not be built\n",
                   film.c_str());
    mosh_done = true;
  }).detach();
  return "";
}
