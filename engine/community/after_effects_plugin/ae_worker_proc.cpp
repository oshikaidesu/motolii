#include "community/after_effects_plugin/ae_worker_proc.h"

#include <algorithm>
#include <atomic>
#include <chrono>
#include <filesystem>
#include <system_error>

#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#else
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <sys/wait.h>
#include <unistd.h>
#endif

namespace motolii {

namespace {

using Clock = std::chrono::steady_clock;

int remaining_ms(Clock::time_point deadline) {
  const auto now = Clock::now();
  if (now >= deadline) return 0;
  return (int)std::chrono::duration_cast<std::chrono::milliseconds>(deadline -
                                                                    now)
      .count();
}

#ifdef _WIN32
std::wstring utf8_to_wide(const std::string& s) {
  if (s.empty()) return {};
  const int need = MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(),
                                       nullptr, 0);
  if (need <= 0) return {};
  std::wstring out((size_t)need, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), out.data(), need);
  return out;
}

// Quotes one argument per CommandLineToArgvW rules.
std::wstring quote_win_arg(const std::wstring& arg) {
  if (!arg.empty() && arg.find_first_of(L" \t\n\v\"") == std::wstring::npos)
    return arg;
  std::wstring out = L"\"";
  size_t slashes = 0;
  for (wchar_t c : arg) {
    if (c == L'\\') {
      ++slashes;
    } else if (c == L'"') {
      out.append(slashes * 2 + 1, L'\\');
      out.push_back(L'"');
      slashes = 0;
    } else {
      out.append(slashes, L'\\');
      out.push_back(c);
      slashes = 0;
    }
  }
  out.append(slashes * 2, L'\\');
  out.push_back(L'"');
  return out;
}

// Creates an overlapped named pipe pair: `parent` is non-inheritable and
// supports timed OVERLAPPED I/O; `child` is inheritable for STARTUPINFOW.
bool make_overlapped_pipe(bool parent_writes, HANDLE& parent, HANDLE& child) {
  static std::atomic<uint64_t> seq{0};
  const uint64_t id = ++seq;
  const std::wstring name = L"\\\\.\\pipe\\motolii_ae_" +
                            std::to_wstring(GetCurrentProcessId()) + L"_" +
                            std::to_wstring(id);
  const DWORD open_mode =
      (parent_writes ? PIPE_ACCESS_OUTBOUND : PIPE_ACCESS_INBOUND) |
      FILE_FLAG_OVERLAPPED | FILE_FLAG_FIRST_PIPE_INSTANCE;
  parent = CreateNamedPipeW(name.c_str(), open_mode,
                            PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT, 1,
                            65536, 65536, 0, nullptr);
  if (parent == INVALID_HANDLE_VALUE) {
    parent = nullptr;
    return false;
  }
  SECURITY_ATTRIBUTES sa{};
  sa.nLength = sizeof(sa);
  sa.bInheritHandle = TRUE;
  child = CreateFileW(name.c_str(),
                      parent_writes ? GENERIC_READ : GENERIC_WRITE, 0, &sa,
                      OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (child == INVALID_HANDLE_VALUE) {
    CloseHandle(parent);
    parent = nullptr;
    child = nullptr;
    return false;
  }
  return true;
}

bool overlapped_io(HANDLE h, bool is_write, uint8_t* buf, DWORD len,
                   int timeout_ms, DWORD& done, bool& eof) {
  done = 0;
  eof = false;
  HANDLE ev = CreateEventW(nullptr, TRUE, FALSE, nullptr);
  if (!ev) return false;
  OVERLAPPED ov{};
  ov.hEvent = ev;
  BOOL ok = is_write ? WriteFile(h, buf, len, &done, &ov)
                     : ReadFile(h, buf, len, &done, &ov);
  if (!ok) {
    const DWORD err = GetLastError();
    if (err == ERROR_IO_PENDING) {
      const DWORD w = WaitForSingleObject(ev, (DWORD)std::max(1, timeout_ms));
      if (w == WAIT_OBJECT_0) {
        ok = GetOverlappedResult(h, &ov, &done, FALSE);
        if (!ok) {
          const DWORD rerr = GetLastError();
          if (rerr == ERROR_BROKEN_PIPE || rerr == ERROR_PIPE_NOT_CONNECTED)
            eof = true;
        }
      } else {
        CancelIoEx(h, &ov);
        GetOverlappedResult(h, &ov, &done, TRUE);
        ok = FALSE;
      }
    } else if (err == ERROR_BROKEN_PIPE || err == ERROR_PIPE_NOT_CONNECTED) {
      eof = true;
    }
  }
  CloseHandle(ev);
  return ok != FALSE;
}
#endif

}  // namespace

AeWorkerProc::~AeWorkerProc() { stop(); }

bool AeWorkerProc::alive() const {
#ifdef _WIN32
  return proc_ != nullptr && to_child_ != nullptr && from_child_ != nullptr;
#else
  return pid_ > 0 && to_child_ >= 0 && from_child_ >= 0;
#endif
}

bool AeWorkerProc::start(const std::string& exe, const std::string& mode,
                         const std::string& arg) {
  stop();
  std::error_code ec;
  if (!std::filesystem::exists(exe, ec)) return false;

#ifdef _WIN32
  HANDLE p_in = nullptr, c_in = nullptr;
  HANDLE p_out = nullptr, c_out = nullptr;
  if (!make_overlapped_pipe(true, p_in, c_in)) return false;
  if (!make_overlapped_pipe(false, p_out, c_out)) {
    CloseHandle(p_in);
    CloseHandle(c_in);
    return false;
  }
  SECURITY_ATTRIBUTES sa{};
  sa.nLength = sizeof(sa);
  sa.bInheritHandle = TRUE;
  HANDLE c_err = CreateFileW(L"NUL", GENERIC_WRITE,
                             FILE_SHARE_READ | FILE_SHARE_WRITE, &sa,
                             OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);

  STARTUPINFOW si{};
  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESTDHANDLES;
  si.hStdInput = c_in;
  si.hStdOutput = c_out;
  si.hStdError = c_err != INVALID_HANDLE_VALUE ? c_err : c_out;

  std::wstring cmd = quote_win_arg(utf8_to_wide(exe)) + L" " +
                     quote_win_arg(utf8_to_wide(mode)) + L" " +
                     quote_win_arg(utf8_to_wide(arg));
  PROCESS_INFORMATION pi{};
  const BOOL ok =
      CreateProcessW(nullptr, cmd.data(), nullptr, nullptr, TRUE,
                     CREATE_NO_WINDOW, nullptr, nullptr, &si, &pi);
  CloseHandle(c_in);
  CloseHandle(c_out);
  if (c_err != INVALID_HANDLE_VALUE) CloseHandle(c_err);
  if (!ok) {
    CloseHandle(p_in);
    CloseHandle(p_out);
    return false;
  }
  CloseHandle(pi.hThread);
  proc_ = pi.hProcess;
  to_child_ = p_in;
  from_child_ = p_out;
  return true;
#else
  int in_pipe[2], out_pipe[2];
  if (pipe(in_pipe) != 0) return false;
  if (pipe(out_pipe) != 0) {
    close(in_pipe[0]), close(in_pipe[1]);
    return false;
  }
  pid_t pid = fork();
  if (pid < 0) {
    close(in_pipe[0]), close(in_pipe[1]), close(out_pipe[0]),
        close(out_pipe[1]);
    return false;
  }
  if (pid == 0) {
    dup2(in_pipe[0], STDIN_FILENO);
    dup2(out_pipe[1], STDOUT_FILENO);
    int devnull = open("/dev/null", O_WRONLY);
    if (devnull >= 0) {
      dup2(devnull, STDERR_FILENO);
      close(devnull);
    }
    close(in_pipe[0]), close(in_pipe[1]), close(out_pipe[0]),
        close(out_pipe[1]);
    execl(exe.c_str(), exe.c_str(), mode.c_str(), arg.c_str(), (char*)nullptr);
    _exit(127);
  }
  close(in_pipe[0]), close(out_pipe[1]);
  fcntl(in_pipe[1], F_SETFL, O_NONBLOCK);
#ifdef F_SETNOSIGPIPE
  fcntl(in_pipe[1], F_SETNOSIGPIPE, 1);
#endif
  fcntl(out_pipe[0], F_SETFL, O_NONBLOCK);
  pid_ = (int)pid;
  to_child_ = in_pipe[1];
  from_child_ = out_pipe[0];
  return true;
#endif
}

bool AeWorkerProc::write_all(const uint8_t* data, size_t len, int timeout_ms) {
  if (!alive()) return false;
  const auto deadline = Clock::now() + std::chrono::milliseconds(timeout_ms);
  size_t off = 0;
  while (off < len) {
    const int rem = remaining_ms(deadline);
    if (rem <= 0) return false;
#ifdef _WIN32
    DWORD chunk = (DWORD)std::min<size_t>(len - off, 1 << 20);
    DWORD wrote = 0;
    bool eof = false;
    if (!overlapped_io((HANDLE)to_child_, true,
                       const_cast<uint8_t*>(data + off), chunk, rem, wrote,
                       eof) ||
        wrote == 0)
      return false;
    off += wrote;
#else
    struct pollfd pfd{to_child_, POLLOUT, 0};
    const int pr = poll(&pfd, 1, rem);
    if (pr <= 0) return false;
    const ssize_t n = write(to_child_, data + off, len - off);
    if (n > 0)
      off += (size_t)n;
    else if (n < 0 && (errno == EINTR || errno == EAGAIN))
      continue;
    else
      return false;
#endif
  }
  return true;
}

bool AeWorkerProc::read_all(uint8_t* data, size_t len, int timeout_ms) {
  if (!alive()) return false;
  const auto deadline = Clock::now() + std::chrono::milliseconds(timeout_ms);
  size_t off = 0;
  while (off < len) {
    const int rem = remaining_ms(deadline);
    if (rem <= 0) return false;
#ifdef _WIN32
    DWORD chunk = (DWORD)std::min<size_t>(len - off, 1 << 20);
    DWORD got = 0;
    bool eof = false;
    if (!overlapped_io((HANDLE)from_child_, false, data + off, chunk, rem, got,
                       eof) ||
        got == 0)
      return false;
    off += got;
#else
    struct pollfd pfd{from_child_, POLLIN, 0};
    const int pr = poll(&pfd, 1, rem);
    if (pr <= 0) return false;
    const ssize_t n = read(from_child_, data + off, len - off);
    if (n > 0)
      off += (size_t)n;
    else if (n < 0 && (errno == EINTR || errno == EAGAIN))
      continue;
    else
      return false;
#endif
  }
  return true;
}

bool AeWorkerProc::read_until_eof(std::string& out, int timeout_ms,
                                  int& exit_code) {
  exit_code = -1;
  out.clear();
  const auto deadline = Clock::now() + std::chrono::milliseconds(timeout_ms);

#ifdef _WIN32
  if (to_child_) CloseHandle((HANDLE)to_child_), to_child_ = nullptr;
  uint8_t buf[4096];
  while (true) {
    const int rem = remaining_ms(deadline);
    if (rem <= 0) {
      stop();
      return false;
    }
    DWORD got = 0;
    bool eof = false;
    const bool ok = overlapped_io((HANDLE)from_child_, false, buf, sizeof buf,
                                  rem, got, eof);
    if (ok && got > 0) {
      out.append(reinterpret_cast<const char*>(buf), got);
    } else if (eof || (ok && got == 0)) {
      break;
    } else {
      stop();
      return false;
    }
  }
  const int rem = std::max(1, remaining_ms(deadline));
  if (WaitForSingleObject((HANDLE)proc_, (DWORD)rem) != WAIT_OBJECT_0) {
    stop();
    return false;
  }
  DWORD code = 1;
  GetExitCodeProcess((HANDLE)proc_, &code);
  exit_code = (int)code;
  CloseHandle((HANDLE)from_child_), from_child_ = nullptr;
  CloseHandle((HANDLE)proc_), proc_ = nullptr;
  return true;
#else
  if (to_child_ >= 0) close(to_child_), to_child_ = -1;
  char buf[4096];
  while (true) {
    const int rem = remaining_ms(deadline);
    if (rem <= 0) {
      stop();
      return false;
    }
    struct pollfd pfd{from_child_, POLLIN, 0};
    const int pr = poll(&pfd, 1, rem);
    if (pr > 0) {
      const ssize_t n = read(from_child_, buf, sizeof buf);
      if (n > 0) {
        out.append(buf, (size_t)n);
      } else if (n == 0) {
        break;
      } else if (errno != EINTR && errno != EAGAIN) {
        break;
      }
    } else {
      stop();
      return false;
    }
  }
  close(from_child_), from_child_ = -1;
  int status = 0;
  waitpid((pid_t)pid_, &status, 0);
  pid_ = -1;
  exit_code = WIFEXITED(status) ? WEXITSTATUS(status) : -1;
  return true;
#endif
}

void AeWorkerProc::stop() {
#ifdef _WIN32
  if (to_child_) CloseHandle((HANDLE)to_child_), to_child_ = nullptr;
  if (from_child_) CloseHandle((HANDLE)from_child_), from_child_ = nullptr;
  if (proc_) {
    TerminateProcess((HANDLE)proc_, 1);
    WaitForSingleObject((HANDLE)proc_, 1000);
    CloseHandle((HANDLE)proc_);
    proc_ = nullptr;
  }
#else
  if (to_child_ >= 0) close(to_child_), to_child_ = -1;
  if (from_child_ >= 0) close(from_child_), from_child_ = -1;
  if (pid_ > 0) {
    kill((pid_t)pid_, SIGKILL);
    waitpid((pid_t)pid_, nullptr, 0);
    pid_ = -1;
  }
#endif
}

}  // namespace motolii
