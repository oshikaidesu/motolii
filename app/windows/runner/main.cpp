#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <filesystem>
#include <string>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // The app and the engine (loaded into this process) name their folders from HOME, as on the Mac.
  // shortcut: ~/Library/Caches/Motolii lands under %USERPROFILE%; move to %LOCALAPPDATA% when Windows ships.
  // _wputenv_s, not SetEnvironmentVariable: the engine's getenv reads the C runtime's copy of the environment.
  if (!_wgetenv(L"HOME") && _wgetenv(L"USERPROFILE"))
    _wputenv_s(L"HOME", _wgetenv(L"USERPROFILE"));
  // The engine's own DLLs are found on PATH, not beside it (engine/build.sh): engine/out, the nearest one above this
  // program (as the app's engine_paths.dart finds it), and GStreamer's.
  {
    std::wstring path = _wgetenv(L"PATH") ? _wgetenv(L"PATH") : L"";
    wchar_t self[MAX_PATH];
    ::GetModuleFileNameW(nullptr, self, MAX_PATH);
    std::filesystem::path exe_dir = std::filesystem::path(self).parent_path();
    // Standalone release bundle keeps engine DLLs beside Motolii.exe or under engine\out.
    if (std::filesystem::exists(exe_dir / L"engine" / L"out")) {
      path = (exe_dir / L"engine" / L"out").wstring() + L";" + exe_dir.wstring() + L";" + path;
    } else {
      for (std::filesystem::path d = exe_dir; d.has_relative_path(); d = d.parent_path())
        if (std::filesystem::exists(d / L"engine" / L"edit.sh")) {
          path = (d / L"engine" / L"out").wstring() + L";" + path;
          break;
        }
    }
    if (const wchar_t* gst = _wgetenv(L"GSTREAMER_1_0_ROOT_MSVC_X86_64"))
      path = (std::filesystem::path(gst) / L"bin").wstring() + L";" + path;
    _wputenv_s(L"PATH", path.c_str());
  }

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"motolii", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
