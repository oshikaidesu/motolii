#!/bin/zsh
# The window with Flutter's own hot reload: a .dart under lib/ saved shows in the open window in a moment, its state
# kept (flutter attach reloads when sent SIGUSR1, restarts on SIGUSR2). The inside's own files reload by themselves
# (effects .wgsl, scripts .js). A rebuilt engine (../engine/build.sh lib) is a hot restart: the window stays open and
# the project is opened again in the new engine. Ends when the window is closed.
#   tool/live.sh                   (opens ~/Movies/Motolii/Untitled.motolii; MOTOLII_DOC=/path/to.motolii for another document)
# Opening takes about 3 s: Xcode builds the app only when the native side changed (macos/, pubspec.yaml, pubspec.lock)
# other than the Swift of macos/Runner, or there is none yet; that Swift alone is built again by Xcode's own commands,
# kept from its last log (swift_only). Dart alone is compiled by Flutter's own compiler (dart_only); with assets, by
# the step Xcode itself runs (flutter assemble, with the settings flutter build last wrote to Flutter-Generated.xcconfig),
# put into the app the way Flutter's xcode_backend.dart embeds it (rsync App.framework, then codesign). The app is
# started directly and flutter attach joins it for the reloads.
cd "$(dirname "$0")/.."   # (app/: lib/, build/ and ../engine are read from there)
source ../engine/tools/build_lock.sh; build_lock "$@"   # (the machine's one build lock, held till the window is open, not while it runs)
FLUTTER="${FLUTTER:-flutter}"
pid="build/live.pid" seen="build/live.seen" engine="build/live.engine" said="build/live.app.log"
products="build/macos/Build/Products/Debug" xcconfig="macos/Flutter/ephemeral/Flutter-Generated.xcconfig"
app="$products/Motolii.app" defines=(--dart-define=MOTOLII_DIR="${MOTOLII_DIR:-${PWD:h}/engine}")
export MOTOLII_DOC="${MOTOLII_DOC:-$HOME/Movies/Motolii/Untitled.motolii}"   # (read by the app at launch: the document, and beside it what Render writes and File › New makes)
mkdir -p "${MOTOLII_DOC:h}" build && rm -f "$pid" && touch "$seen" "$engine"

setting() { sed -n "s/^$1=//p" "$xcconfig"; }
# Only Dart changed: the compiler Flutter itself runs (frontend_server, with the arguments flutter assemble gives it,
# from the last app.dill) writes the program, and it replaces the app's kernel_blob.bin. Assets and plugins untouched.
dart_only() {
    local root=$(setting FLUTTER_ROOT) dill=$(ls -t .dart_tool/flutter_build/*/app.dill 2> /dev/null | head -1) d defs=()
    local blob="$app/Contents/Frameworks/App.framework/Resources/flutter_assets/kernel_blob.bin"
    local registrant="$PWD/.dart_tool/flutter_build/dart_plugin_registrant.dart"
    [ -f "$dill" ] && [ -f "$blob" ] && [ -f "$registrant" ] && [ -z "$(find assets pubspec.yaml -newer "$blob" -print -quit)" ] || return 1
    [ -z "$(find lib .dart_tool/package_config.json -newer "$blob" -print -quit)" ] && return 0   # (no Dart newer than the app's)
    for d in ${(s:,:)$(setting DART_DEFINES)}; do defs+=(-D"$(print -r -- $d | base64 -d)"); done
    "$root/bin/cache/dart-sdk/bin/dartaotruntime" "$root/bin/cache/dart-sdk/bin/snapshots/frontend_server_aot.dart.snapshot" \
        --sdk-root "$root/bin/cache/artifacts/engine/common/flutter_patched_sdk/" --target=flutter --no-print-incremental-dependencies \
        $defs -Ddart.vm.profile=false -Ddart.vm.product=false --enable-asserts --track-widget-creation \
        --packages .dart_tool/package_config.json --output-dill "$dill.next" --incremental --initialize-from-dill "$dill" \
        --source "file://$registrant" --source package:flutter/src/dart_plugin_registrant.dart \
        -Dflutter.dart_plugin_registrant="file://$registrant" --verbosity=error package:motolii/main.dart < /dev/null | tail -1 | grep -q "app.dill.next 0$" &&
        mv "$dill.next" "$dill" && cp -c "$dill" "$blob"
}

# The native side through Xcode. Its own commands for the Swift of macos/Runner (compile, link Motolii.debug.dylib,
# sign) are kept from its log in build/live.swift.sh, and swift_only runs them again when only that Swift changed:
# the build log replayed, as InjectionIII does. A build that compiled no Swift keeps the ones kept before.
xcode() {
    "$FLUTTER" build macos --debug -v $defines > build/live.xcode.log 2>&1 || { tail -40 build/live.xcode.log; return 1; }
    local step=(grep -A2 -E) at=(sed -E 's/^\[ *\] +//')
    { echo 'cd macos'
      $step '\] SwiftDriver Runner normal' build/live.xcode.log | tail -1 | $at | sed 's/^builtin-SwiftDriver -- //'
      $step '\] Ld .*/Motolii\.debug\.dylib normal' build/live.xcode.log | tail -1 | $at
      grep -E '/usr/bin/codesign .*(Motolii\.debug\.dylib|Motolii\.app)$' build/live.xcode.log | $at
    } > build/live.swift.next
    [ $(grep -c . build/live.swift.next) -ge 4 ] && mv build/live.swift.next build/live.swift.sh
    touch "$native"
}
swift_only() { [ -f build/live.swift.sh ] && zsh -e build/live.swift.sh > /dev/null 2>&1 && touch "$native"; }

native="build/live.native" changed=()
[ -f "$native" ] && changed=(${(f)"$(find macos pubspec.yaml pubspec.lock -path macos/Flutter -prune -o -type f -newer "$native" -print)"})
if [ ! -x "$app/Contents/MacOS/Motolii" ] || [ ! -f "$xcconfig" ] || [ ! -f "$native" ] ||
   [ -n "${changed:#macos/Runner/*.swift}" ] || { (( $#changed )) && ! swift_only }; then
    xcode || exit 1
elif ! dart_only; then
    "$FLUTTER" assemble --no-version-check --output="$PWD/$products/" -dTargetPlatform=darwin -dTargetFile="$(setting FLUTTER_TARGET)" \
        -dBuildMode=debug -dConfiguration=Debug -dDarwinArchs="$(uname -m)" -dSdkRoot="$(xcrun --sdk macosx --show-sdk-path)" \
        -dTreeShakeIcons="$(setting TREE_SHAKE_ICONS)" -dTrackWidgetCreation="$(setting TRACK_WIDGET_CREATION)" \
        -dDartObfuscation="$(setting DART_OBFUSCATION)" -dAction=build --DartDefines="$(setting DART_DEFINES)" \
        -dSrcRoot="$PWD/macos" debug_macos_bundle_flutter_assets > /dev/null || exit 1
    rsync -a --delete "$products/App.framework" "$app/Contents/Frameworks/"
    codesign --force --sign - --timestamp=none "$app/Contents/Frameworks/App.framework/App" 2> /dev/null
fi

"$app/Contents/MacOS/Motolii" > "$said" 2>&1 &
window=$!
trap 'kill $window $run 2>/dev/null' EXIT INT TERM
until url=$(grep -o 'http://127.0.0.1:[0-9]*/[^ ]*/' "$said" | head -1); [ -n "$url" ]; do
    kill -0 $window 2>/dev/null || { cat "$said"; exit 1; }
    sleep 0.1
done
build_unlock   # (the window is open: what it builds from here is its own)
"$FLUTTER" attach -d macos --debug-url "$url" --pid-file "$pid" $defines < /dev/null &
run=$!
while kill -0 $window 2>/dev/null; do   # (once a second: a .dart newer than the last reload, then reload)
    sleep 1
    if [ -f "$pid" ] && [ ../engine/out/libmotolii.dylib -nt "$engine" ]; then   # (the engine rebuilt: a hot restart opens the new one, see Motolii._liveCopy)
        touch "$seen" "$engine"
        kill -USR2 "$(cat "$pid")" 2>/dev/null && echo "live.sh: engine rebuilt, restarted"
    elif [ -f "$pid" ] && [ -n "$(find lib -name '*.dart' -newer "$seen" | head -1)" ]; then
        touch "$seen"
        kill -USR1 "$(cat "$pid")" 2>/dev/null && echo "live.sh: reloaded"
    fi
done
