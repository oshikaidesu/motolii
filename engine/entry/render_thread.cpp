#include "entry/render_thread.h"

#include <filament/Engine.h>
#include <filament/Options.h>
#include <filament/View.h>
#include <math/vec2.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <utility>

#include "document/kinds.h"
#include "stage/live.h"
#include "stage/render/render_layers.h"
#include "stage/render/render_stage.h"

using namespace filament;

namespace motolii {

thread_local std::string why_asked;

void broke_one(Motolii* m, const char* why) {
  const auto now = std::chrono::system_clock::now();
  const std::time_t at = std::chrono::system_clock::to_time_t(now);
  std::tm tm{};
  localtime_r(&at, &tm);
  char line[240];
  std::snprintf(line, sizeof line, "%02d:%02d:%02d.%03d %s", tm.tm_hour,
                tm.tm_min, tm.tm_sec,
                (int)(std::chrono::duration_cast<std::chrono::milliseconds>(
                          now.time_since_epoch())
                          .count() %
                      1000),
                why);
  m->broke.push_back(line);
  if (m->broke.size() > 200) m->broke.pop_front();
  m->broken++;
}
void live_camera(Motolii* m) {
  Stage& s = *m->s;
  Doc& d = *m->d;
  if (!m->second) return live_draw(s, m->live);
  const bool desk = m->live->desk && s.desk.w, camera = d.working;
  if (desk) {
    live_draw(s, m->live);
    // The stage's own frame is already the camera's.
    if (!camera && (s.over || !s.before.empty())) return;
    s.engine->destroy(m->live->pending), m->live->pending = nullptr;
  }
  std::lock_guard<std::recursive_timed_mutex> holding(d.lock);
  const uint32_t w = s.desk.w;
  if (camera) d.viewCameraAsked = false, time_is(s, m->now);
  s.desk.w = 0;
  live_draw(s, m->live);
  s.desk.w = w;
  if (camera) d.viewCameraAsked = true, time_is(s, m->now);
}
void stage_scale(Motolii* m) {
  static const double fixed = std::getenv("MOTOLII_SCALE")
                                  ? std::atof(std::getenv("MOTOLII_SCALE"))
                                  : 0.0;
  double want = 1.0;
  if (fixed > 0.0) want = fixed;
  // GPU time is proportional to the number of pixels drawn, so the pixel count
  // is cut by the factor by which the budget is exceeded. The linear scale is
  // the square root of that.
  else if (m->playing && m->gpu_ms > 0.0)
    want = std::clamp(m->scale * std::sqrt(m->budget / m->gpu_ms), 0.5, 1.0);
  if (std::fabs(want - m->scale) < 0.05 && !(want == 1.0 && m->scale != 1.0))
    return;
  m->scale = want;
  View::DynamicResolutionOptions o;
  o.enabled = want < 1.0, o.minScale = o.maxScale = math::float2{(float)want},
  o.quality = QualityLevel::MEDIUM;
  m->s->view->setDynamicResolutionOptions(o);
}
int posted(Motolii* m, const std::string& kind, std::function<void()> does) {
  {
    std::lock_guard<std::mutex> hold(m->asked_lock);
    auto& waiting = m->latest[kind];
    if (waiting && m->lastPosted == kind)
      *waiting = std::move(does);
    else {
      auto mine = std::make_shared<std::function<void()>>(std::move(does));
      waiting = mine;
      m->asked.push_back([m, kind, mine] {
        std::function<void()> now;
        {
          std::lock_guard<std::mutex> hold(m->asked_lock);
          now = std::move(*mine);
          if (m->latest[kind] == mine) m->latest.erase(kind);
        }
        now();
        m->changed = true;
      });
      m->lastPosted = kind;
    }
  }
  m->asked_now.notify_one();
  return 1;
}

}  // namespace motolii
