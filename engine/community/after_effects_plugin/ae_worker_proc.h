#ifndef MOTOLII_COMMUNITY_AFTER_EFFECTS_PLUGIN_AE_WORKER_PROC_H_
#define MOTOLII_COMMUNITY_AFTER_EFFECTS_PLUGIN_AE_WORKER_PROC_H_
// Cross-platform (POSIX + Windows) isolated subprocess with timed binary pipe
// I/O and hard-kill teardown for motolii_ae_worker.

#include <cstddef>
#include <cstdint>
#include <string>

namespace motolii {

class AeWorkerProc {
 public:
  AeWorkerProc() = default;
  ~AeWorkerProc();
  AeWorkerProc(const AeWorkerProc&) = delete;
  AeWorkerProc& operator=(const AeWorkerProc&) = delete;

  // Starts `<exe> <mode> <arg>` with binary stdin/stdout pipes and stderr
  // discarded.
  bool start(const std::string& exe, const std::string& mode,
             const std::string& arg);
  bool alive() const;

  // Writes/reads exactly `len` bytes within `timeout_ms`.
  bool write_all(const uint8_t* data, size_t len, int timeout_ms);
  bool read_all(uint8_t* data, size_t len, int timeout_ms);

  // Closes stdin, reads all stdout until EOF within `timeout_ms`, waits for
  // exit, and writes the process exit code into `exit_code`. Kills the child on
  // timeout and returns false.
  bool read_until_eof(std::string& out, int timeout_ms, int& exit_code);

  // Forcefully terminates the child (if running) and closes all handles.
  void stop();

 private:
#ifdef _WIN32
  void* proc_ = nullptr;
  void* to_child_ = nullptr;
  void* from_child_ = nullptr;
#else
  int pid_ = -1;
  int to_child_ = -1;
  int from_child_ = -1;
#endif
};

}  // namespace motolii

#endif  // MOTOLII_COMMUNITY_AFTER_EFFECTS_PLUGIN_AE_WORKER_PROC_H_
