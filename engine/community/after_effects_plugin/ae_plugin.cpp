#include "community/after_effects_plugin/ae_plugin.h"

#include <algorithm>
#include <cctype>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <map>
#include <mutex>
#include <set>
#include <sstream>
#include <system_error>

#include "base/cache_folder.h"
#include "base/hash.h"
#include "community/after_effects_plugin/ae_worker_proc.h"
#include "shelf/shelf_folders.h"

namespace motolii {

namespace {

std::string lower_ext(const std::string& path) {
  std::string ext =
      std::filesystem::path(fx_entry_path(path)).extension().generic_string();
  for (char& c : ext) c = (char)std::tolower((unsigned char)c);
  return ext;
}

std::string sanitize_id(const std::string& raw, uint32_t index) {
  std::string out;
  bool sep = false;
  for (unsigned char c : raw) {
    if (std::isalnum(c)) {
      out += (char)std::tolower(c);
      sep = false;
    } else if (!out.empty() && !sep) {
      out += '_';
      sep = true;
    }
  }
  while (!out.empty() && out.back() == '_') out.pop_back();
  if (out.empty() || std::isdigit((unsigned char)out[0]))
    out = "p" + std::to_string(index) + (out.empty() ? "" : "_" + out);
  return out;
}

std::vector<std::string> split_tab(const std::string& line) {
  std::vector<std::string> out;
  size_t pos = 0;
  while (true) {
    const size_t tab = line.find('\t', pos);
    if (tab == std::string::npos) {
      out.push_back(line.substr(pos));
      break;
    }
    out.push_back(line.substr(pos, tab - pos));
    pos = tab + 1;
  }
  return out;
}

AePluginInfo parse_probe(const std::string& text) {
  AePluginInfo info;
  if (text.empty()) return info;
  std::istringstream in(text);
  std::vector<std::string> group_stack;
  std::set<std::string> used_names;
  const auto unique_name = [&](const std::string& base, uint32_t idx) {
    std::string n = sanitize_id(base, idx);
    if (!used_names.insert(n).second) {
      n += "_" + std::to_string(idx);
      used_names.insert(n);
    }
    return n;
  };
  bool saw_caps = false;
  for (std::string line; std::getline(in, line);) {
    if (!line.empty() && line.back() == '\r') line.pop_back();
    const auto f = split_tab(line);
    if (f.empty()) continue;
    if (f[0] == "ABOUT" && f.size() >= 2) {
      info.about = f[1];
    } else if (f[0] == "CAPS" && f.size() >= 6) {
      saw_caps = true;
      info.gpu = f[1] == "1";
      info.smart = f[2] == "1";
      info.d8 = f[3] == "1";
      info.d16 = f[4] == "1";
      info.d32 = f[5] == "1";
    } else if (f[0] == "GROUP_START" && f.size() >= 3) {
      group_stack.push_back(f[2]);
    } else if (f[0] == "GROUP_END") {
      if (!group_stack.empty()) group_stack.pop_back();
    } else if (f[0] == "PARAM" && f.size() >= 4) {
      AePluginParam p;
      p.index = (uint32_t)std::strtoul(f[1].c_str(), nullptr, 10);
      p.kind = f[2];
      p.label = f[3].empty() ? ("Param " + f[1]) : f[3];
      p.name = unique_name(p.label, p.index);
      p.group = group_stack.empty() ? "" : group_stack.back();
      if ((p.kind == "float" || p.kind == "fixed" || p.kind == "slider" ||
           p.kind == "angle") &&
          f.size() >= 7) {
        p.low = std::atof(f[4].c_str());
        p.high = std::atof(f[5].c_str());
        p.usual = std::atof(f[6].c_str());
        if (!(p.high > p.low)) p.low = 0, p.high = 100;
        ScriptParameter sp;
        sp.name = p.name;
        sp.label = p.label;
        sp.kind = "track";
        sp.low = p.low;
        sp.high = p.high;
        sp.usual = p.usual;
        sp.step = p.kind == "slider" ? 1.0 : 0.01;
        sp.group = p.group;
        info.script_params.push_back(std::move(sp));
      } else if (p.kind == "check" && f.size() >= 7) {
        p.low = 0, p.high = 1, p.usual = std::atof(f[6].c_str()) != 0 ? 1 : 0;
        ScriptParameter sp;
        sp.name = p.name;
        sp.label = p.label;
        sp.kind = "check";
        sp.low = 0, sp.high = 1, sp.usual = p.usual, sp.step = 1;
        sp.group = p.group;
        info.script_params.push_back(std::move(sp));
      } else if (p.kind == "popup" && f.size() >= 7) {
        p.low = 1;
        p.high = std::max(1.0, std::atof(f[5].c_str()));
        p.usual = std::clamp(std::atof(f[6].c_str()), 1.0, p.high);
        if (f.size() >= 8 && !f[7].empty()) {
          std::istringstream cs(f[7]);
          for (std::string c; std::getline(cs, c, '|');) p.choices.push_back(c);
        }
        ScriptParameter sp;
        sp.name = p.name;
        sp.label = p.label;
        sp.kind = "track";
        sp.low = p.low;
        sp.high = p.high;
        sp.usual = p.usual;
        sp.step = 1.0;
        sp.group = p.group;
        info.script_params.push_back(std::move(sp));
      } else if (p.kind == "point" && f.size() >= 6) {
        p.x = std::atof(f[4].c_str());
        p.y = std::atof(f[5].c_str());
        const std::string grp = p.group.empty() ? p.label : p.group;
        info.script_params.push_back(
            {p.name + "_x", p.label + " X", "track", 0, 1, p.x, 0.01, "", grp});
        info.script_params.push_back(
            {p.name + "_y", p.label + " Y", "track", 0, 1, p.y, 0.01, "", grp});
      } else if (p.kind == "point3d" && f.size() >= 7) {
        p.x = std::atof(f[4].c_str());
        p.y = std::atof(f[5].c_str());
        p.z = std::atof(f[6].c_str());
        const std::string grp = p.group.empty() ? p.label : p.group;
        info.script_params.push_back(
            {p.name + "_x", p.label + " X", "track", 0, 1, p.x, 0.01, "", grp});
        info.script_params.push_back(
            {p.name + "_y", p.label + " Y", "track", 0, 1, p.y, 0.01, "", grp});
        info.script_params.push_back(
            {p.name + "_z", p.label + " Z", "track", -4096, 4096, p.z, 1, "",
             grp});
      } else if (p.kind == "color" && f.size() >= 8) {
        for (int c = 0; c < 4; ++c)
          p.rgba[c] = (uint8_t)std::clamp(
              std::atoi(f[(size_t)(4 + c)].c_str()), 0, 255);
        const std::string grp = p.group.empty() ? p.label : p.group;
        for (int c = 0; c < 3; ++c)
          info.script_params.push_back(
              {p.name + "_" + "rgb"[c], p.label + " " + "RGB"[c], "track", 0,
               255, (double)p.rgba[c], 1, "", grp});
      } else if (p.kind == "layer") {
        info.has_layer = true;
        ScriptParameter sp;
        sp.name = p.name;
        sp.label = p.label;
        sp.kind = "picture";
        sp.low = 0, sp.high = 1e9, sp.usual = 0, sp.step = 1;
        sp.group = p.group;
        info.script_params.push_back(std::move(sp));
      } else {
        continue;
      }
      info.params.push_back(std::move(p));
    }
  }
  info.ok = saw_caps;
  if (info.ok) {
    info.tags = std::string("ae ") + (info.gpu ? "gpu" : "cpu");
    if (info.has_layer) info.tags += " image";
  }
  return info;
}

// Runs the worker with `--probe` and returns stdout, or empty on failure/timeout.
std::string run_probe_worker(const std::string& plugin_path, int timeout_ms) {
  AeWorkerProc proc;
  if (!proc.start(ae_plugin_worker(), "--probe", plugin_path)) return "";
  std::string out;
  int exit_code = -1;
  if (!proc.read_until_eof(out, timeout_ms, exit_code) || exit_code != 0)
    return "";
  return out;
}

long long plugin_stamp(const std::string& path) {
  std::error_code ec;
  auto t = std::filesystem::last_write_time(path, ec);
  if (ec) return -1;
  return (long long)t.time_since_epoch().count();
}

}  // namespace

bool ae_plugin_is(const std::string& path) {
  const std::string ext = lower_ext(path);
  return ext == ".plugin" || ext == ".aex";
}

std::string ae_plugin_worker() {
#ifdef _WIN32
  return doc_engine("out/motolii_ae_worker.exe").generic_string();
#else
  return doc_engine("out/motolii_ae_worker").generic_string();
#endif
}

std::string ae_plugin_title(const std::string& path) {
  std::string t =
      std::filesystem::path(fx_entry_path(path)).stem().generic_string();
  for (char& c : t)
    if (c == '_') c = ' ';
  if (!t.empty()) t[0] = (char)std::toupper((unsigned char)t[0]);
  return t;
}

AePluginInfo ae_plugin_probe(const std::string& path) {
  const std::string clean = fx_entry_path(path);
  const long long stamp = plugin_stamp(clean);
  if (stamp < 0) return {};

  static std::mutex lock;
  static std::map<std::string, std::pair<long long, AePluginInfo>> mem;
  {
    std::lock_guard<std::mutex> hold(lock);
    if (auto it = mem.find(clean); it != mem.end() && it->second.first == stamp)
      return it->second.second;
  }

  // Disk cache keyed by path + mtime + worker mtime so shelf rescans do not
  // spawn worker processes for already-inspected plugins.
  const long long worker_stamp = plugin_stamp(ae_plugin_worker());
  const std::string key = clean + "|" + std::to_string(stamp) + "|" +
                          std::to_string(worker_stamp) + "|aeprobe2";
  char name[32];
  std::snprintf(name, sizeof name, "%016llx.probe",
                (unsigned long long)fnv1a64(key));
  const std::filesystem::path cache_file = cache_folder("ae_plugins") / name;

  std::string raw;
  bool cached = false;
  if (std::ifstream in(cache_file); in) {
    std::ostringstream ss;
    ss << in.rdbuf();
    raw = ss.str();
    cached = true;
  } else {
    raw = run_probe_worker(clean, 4000);
    std::error_code ec;
    std::filesystem::create_directories(cache_file.parent_path(), ec);
    if (std::ofstream out(cache_file); out) out << raw;
  }
  (void)cached;

  AePluginInfo info = parse_probe(raw);
  {
    std::lock_guard<std::mutex> hold(lock);
    mem[clean] = {stamp, info};
  }
  return info;
}

std::vector<ScriptParameter> ae_plugin_parameters(const std::string& path) {
  return ae_plugin_probe(path).script_params;
}

}  // namespace motolii
