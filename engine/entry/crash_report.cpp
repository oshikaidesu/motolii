// Crash report: writes a backtrace and the reason to a file on panic or signal.
#include "entry/crash_report.h"

#include <utils/Panic.h>

#include <csignal>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <execinfo.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

namespace motolii {

static char report_path[512] = {};
static bool installed = false;

static void make_dir() {
  const char* home = getenv("HOME");
  if (!home) home = "/tmp";
  char dir[480];
  snprintf(dir, sizeof dir, "%s/Library/Caches/Motolii", home);
  mkdir(dir, 0755);
  snprintf(report_path, sizeof report_path, "%s/crash_report.txt", dir);
}

// Signal-safe: only async-signal-safe functions (open, write, close, backtrace).
static void write_signal_report(int sig) {
  if (!report_path[0]) return;
  int fd = open(report_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
  if (fd < 0) return;

  const char* name = "unknown signal";
  switch (sig) {
    case SIGABRT: name = "SIGABRT"; break;
    case SIGSEGV: name = "SIGSEGV"; break;
    case SIGBUS:  name = "SIGBUS"; break;
    case SIGTRAP: name = "SIGTRAP"; break;
  }

  // Timestamp (signal-safe: raw seconds).
  time_t now = time(nullptr);
  char header[256];
  int n = snprintf(header, sizeof header, "signal: %s (%d)\ntime: %ld\n\n",
                   name, sig, (long)now);
  write(fd, header, (size_t)n);

  void* frames[64];
  int count = backtrace(frames, 64);
  // backtrace_symbols_fd is async-signal-safe on macOS.
  backtrace_symbols_fd(frames, count, fd);

  close(fd);
}

static void signal_handler(int sig) {
  write_signal_report(sig);
  // Re-raise so the default handler runs (core dump, termination).
  signal(sig, SIG_DFL);
  raise(sig);
}

static void panic_handler(void*, utils::Panic const& p) {
  fprintf(stderr, "Filament panic: %s\n", p.what());
  if (!report_path[0]) return;
  FILE* f = fopen(report_path, "w");
  if (!f) return;

  time_t now = time(nullptr);
  char timebuf[64];
  struct tm lt;
  localtime_r(&now, &lt);
  strftime(timebuf, sizeof timebuf, "%Y-%m-%d %H:%M:%S", &lt);

  fprintf(f, "Filament panic\ntime: %s\nreason: %s\n\n", timebuf, p.what());

  void* frames[64];
  int count = backtrace(frames, 64);
  char** symbols = backtrace_symbols(frames, count);
  if (symbols) {
    for (int i = 0; i < count; ++i) fprintf(f, "%s\n", symbols[i]);
    free(symbols);
  }
  fclose(f);
}

void install_crash_handlers() {
  if (installed) return;
  installed = true;
  make_dir();
  utils::Panic::setPanicHandler(panic_handler, nullptr);
  struct sigaction sa {};
  sa.sa_handler = signal_handler;
  sa.sa_flags = SA_RESETHAND;
  sigemptyset(&sa.sa_mask);
  sigaction(SIGABRT, &sa, nullptr);
  sigaction(SIGSEGV, &sa, nullptr);
  sigaction(SIGBUS, &sa, nullptr);
}

const char* crash_report_path() {
  if (!report_path[0]) make_dir();
  return report_path;
}

}  // namespace motolii
