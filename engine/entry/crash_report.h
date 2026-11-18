// Writes a crash report to ~/Library/Caches/Motolii/crash_report.txt on panic or signal.
#ifndef MOTOLII_ENTRY_CRASH_REPORT_H_
#define MOTOLII_ENTRY_CRASH_REPORT_H_

namespace motolii {

// Installs the Filament panic handler, std::terminate handler, and signal
// handlers (SIGABRT, SIGSEGV, SIGBUS, SIGILL, SIGFPE). Safe to call more than
// once; only the first call installs.
void install_crash_handlers();

// Records what the engine is doing now. The crash report includes the last one.
void breadcrumb(const char* what);

// The last breadcrumb, or "" if none has been set.
const char* last_breadcrumb();

// The path the last crash report was written to, or nullptr if none.
const char* crash_report_path();

}  // namespace motolii

#endif  // MOTOLII_ENTRY_CRASH_REPORT_H_
