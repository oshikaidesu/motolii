#ifndef MOTOLII_BASE_POSIX_H_
#define MOTOLII_BASE_POSIX_H_
// The few POSIX calls the engine makes, under their POSIX names on Windows too (the C runtime's own under another
// name), so the code that calls them stays one. Elsewhere the system's own headers.
#include <cstdio>
#include <cstdlib>
#include <string>

#ifdef _WIN32
#include <direct.h>
#include <process.h>

#include <thread>

inline int setenv(const char* name, const char* value, int overwrite) {
  return !overwrite && std::getenv(name) ? 0 : _putenv_s(name, value);
}
inline int unsetenv(const char* name) { return _putenv_s(name, ""); }
// cmd /c drops the first and the last quote of a line that starts with one: one more pair keeps the line as written.
inline std::string shell_line(const std::string& line) { return "\"" + line + "\""; }
inline FILE* popen(const char* command, const char* mode) {
  // Binary, as on POSIX: a text pipe would turn the frames' bytes 0x0a into 0x0d 0x0a.
  return _popen(shell_line(command).c_str(), mode[0] == 'w' ? "wb" : "rb");
}
inline int pclose(FILE* f) { return _pclose(f); }
inline int chdir(const char* folder) { return _chdir(folder); }
inline int getpid() { return _getpid(); }
#include <ctime>
inline std::tm* localtime_r(const std::time_t* at, std::tm* out) { return localtime_s(out, at) ? nullptr : out; }
// The thread that loaded the library: the app's main thread, as pthread_main_np names the Mac's.
inline const std::thread::id loaded_on = std::this_thread::get_id();
inline int pthread_main_np() { return std::this_thread::get_id() == loaded_on; }
// The separator of PATH's entries, and where a shell sends what it throws away.
constexpr char path_separator = ';';
constexpr const char* null_device = "NUL";
// A file name as one word of cmd's line: Windows names cannot hold a double quote.
inline std::string shell_quoted(const std::string& name) { return "\"" + name + "\""; }
#else
#include <pthread.h>
#include <unistd.h>
inline std::string shell_line(const std::string& line) { return line; }
constexpr char path_separator = ':';
constexpr const char* null_device = "/dev/null";
// A file name as one word of the shell's line.
inline std::string shell_quoted(std::string name) {
  for (size_t at = 0; (at = name.find('\'', at)) != std::string::npos; at += 4) name.replace(at, 1, "'\\''");
  return "'" + name + "'";
}
#endif

// Runs a line in the system's shell (sh, or cmd on Windows), as std::system does.
inline int shell(const std::string& line) { return std::system(shell_line(line).c_str()); }

#endif  // MOTOLII_BASE_POSIX_H_
