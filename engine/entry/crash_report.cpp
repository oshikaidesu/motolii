// Crash report: writes a backtrace and the reason to a file on panic or signal.
#include "entry/crash_report.h"

#include <utils/Panic.h>

#include <atomic>
#include <csignal>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <exception>
#include <filesystem>
#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#else
#include <execinfo.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#endif

namespace motolii {

static char report_path[512] = {};
static char crumb_path[512] = {};
static bool installed = false;

static void make_dir() {
  const char* home = getenv("HOME");
#ifdef _WIN32
  if (!home) home = getenv("USERPROFILE");
  if (!home) home = ".";
#else
  if (!home) home = "/tmp";
#endif
  char dir[480];
  snprintf(dir, sizeof dir, "%s/Library/Caches/Motolii", home);
  std::error_code ec;
  std::filesystem::create_directories(dir, ec);
  snprintf(report_path, sizeof report_path, "%s/crash_report.txt", dir);
  snprintf(crumb_path, sizeof crumb_path, "%s/breadcrumb.txt", dir);
}

static void format_local_time(time_t now, char* buf, size_t len) {
  struct tm lt {};
#ifdef _WIN32
  localtime_s(&lt, &now);
#else
  localtime_r(&now, &lt);
#endif
  strftime(buf, len, "%Y-%m-%d %H:%M:%S", &lt);
}

static void write_backtrace(FILE* f) {
  void* frames[64];
#ifdef _WIN32
  const USHORT count = CaptureStackBackTrace(0, 64, frames, nullptr);
  for (USHORT i = 0; i < count; ++i) fprintf(f, "0x%p\n", frames[i]);
#else
  int count = backtrace(frames, 64);
  char** symbols = backtrace_symbols(frames, count);
  if (symbols) {
    for (int i = 0; i < count; ++i) fprintf(f, "%s\n", symbols[i]);
    free(symbols);
  }
#endif
}

// Signal-safe on POSIX (only async-signal-safe functions: open, write, close, backtrace).
static void write_signal_report(int sig) {
  if (!report_path[0]) return;

  const char* name = "unknown signal";
  switch (sig) {
    case SIGABRT: name = "SIGABRT"; break;
    case SIGSEGV: name = "SIGSEGV"; break;
#ifdef SIGBUS
    case SIGBUS:  name = "SIGBUS"; break;
#endif
#ifdef SIGTRAP
    case SIGTRAP: name = "SIGTRAP"; break;
#endif
    case SIGILL:  name = "SIGILL"; break;
    case SIGFPE:  name = "SIGFPE"; break;
  }

  time_t now = time(nullptr);
#ifdef _WIN32
  FILE* f = fopen(report_path, "w");
  if (!f) return;
  fprintf(f, "signal: %s (%d)\ntime: %lld\nbreadcrumb: %s\n\n",
          name, sig, (long long)now, last_breadcrumb());
  write_backtrace(f);
  fclose(f);
#else
  int fd = open(report_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
  if (fd < 0) return;

  char header[512];
  int n = snprintf(header, sizeof header,
                   "signal: %s (%d)\ntime: %ld\nbreadcrumb: %s\n\n",
                   name, sig, (long)now, last_breadcrumb());
  write(fd, header, (size_t)n);

  void* frames[64];
  int count = backtrace(frames, 64);
  backtrace_symbols_fd(frames, count, fd);

  close(fd);
#endif
}

static void signal_handler(int sig) {
  write_signal_report(sig);
  signal(sig, SIG_DFL);
  raise(sig);
}

static void panic_handler(void*, utils::Panic const& p) {
  fprintf(stderr, "Filament panic: %s\n", p.what());
  if (!report_path[0]) return;
  FILE* f = fopen(report_path, "w");
  if (!f) return;

  char timebuf[64];
  format_local_time(time(nullptr), timebuf, sizeof timebuf);

  fprintf(f, "Filament panic\ntime: %s\nreason: %s\nbreadcrumb: %s\n\n",
          timebuf, p.what(), last_breadcrumb());

  write_backtrace(f);
  fclose(f);
}

static void terminate_handler() {
  // Catch unhandled C++ exceptions that bypass Filament's panic.
  if (!report_path[0]) { std::abort(); return; }
  FILE* f = fopen(report_path, "w");
  if (f) {
    char timebuf[64];
    format_local_time(time(nullptr), timebuf, sizeof timebuf);

    const char* what = "unknown";
    if (auto ep = std::current_exception()) {
      try { std::rethrow_exception(ep); } catch (const std::exception& e) { what = e.what(); } catch (...) {}
    }

    fprintf(f, "std::terminate\ntime: %s\nreason: %s\nbreadcrumb: %s\n\n",
            timebuf, what, last_breadcrumb());

    write_backtrace(f);
    fclose(f);
  }
  std::abort();
}

// The breadcrumb: a short string describing what the engine is doing now.
// Written by the render thread and read by signal handlers, so it uses a lock-
// free ring of two buffers.
static char crumb_buf[2][256] = {};
static std::atomic<int> crumb_idx{0};

void install_crash_handlers() {
  if (installed) return;
  installed = true;
  make_dir();
  utils::Panic::setPanicHandler(panic_handler, nullptr);
  std::set_terminate(terminate_handler);
#ifdef _WIN32
  std::signal(SIGABRT, signal_handler);
  std::signal(SIGSEGV, signal_handler);
  std::signal(SIGILL, signal_handler);
  std::signal(SIGFPE, signal_handler);
#else
  struct sigaction sa {};
  sa.sa_handler = signal_handler;
  sa.sa_flags = SA_RESETHAND;
  sigemptyset(&sa.sa_mask);
  sigaction(SIGABRT, &sa, nullptr);
  sigaction(SIGSEGV, &sa, nullptr);
  sigaction(SIGBUS, &sa, nullptr);
  sigaction(SIGILL, &sa, nullptr);
  sigaction(SIGFPE, &sa, nullptr);
#endif
}

void breadcrumb(const char* what) {
  int next = 1 - crumb_idx.load(std::memory_order_relaxed);
  snprintf(crumb_buf[next], sizeof crumb_buf[0], "%s", what);
  crumb_idx.store(next, std::memory_order_release);
}

const char* last_breadcrumb() {
  return crumb_buf[crumb_idx.load(std::memory_order_acquire)];
}

const char* crash_report_path() {
  if (!report_path[0]) make_dir();
  return report_path;
}

}  // namespace motolii
