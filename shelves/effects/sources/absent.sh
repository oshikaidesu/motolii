#!/bin/zsh
# AbsentMotion's effects (Apache-2.0, the free Alight Motion alternative: github.com/Comett1225/AbsentMotion) on the Effects
# shelf: its repository at the commit taken, fetched once into engine/third_party/AbsentMotion; Skia's skslc built once
# from engine/third_party/skia_src (deps/skia.sh's checkout, a build of its own: out/sksl); each of its SkSL effects made
# an effect file am_<id>.wgsl (or am_<id>.am, its knobs alone) by from_absent.py beside this. Each goes back into the
# folder its last one was in; a new one into effects/ itself, printed, to be sorted by hand as f8925af9c sorted them.
# Prints how many were made and why the rest were not. Run by hand; nothing builds it. (engine/absent.sh until 416fced3a.)
#   shelves/effects/sources/absent.sh   (ninja from Homebrew: Tint's build asks ninja for -t inputs)
cd "$(dirname "$0")/../../../engine"
A=third_party/AbsentMotion K=third_party/skia_src E=${PWD:h}/shelves/effects W=$(mktemp -d)   # (W: its steps on the way)
[ -d $A/app ] || { mkdir -p $A && git init -q $A && git -C $A -c core.hooksPath=/dev/null fetch -q --depth 1 https://github.com/Comett1225/AbsentMotion 0f5d891b7e6fd7260ca6191b4eafef23141230c8 && git -C $A checkout -q FETCH_HEAD; }
[ -x $K/bin/gn ] || deps/skia.sh
[ -f $K/out/sksl/build.ninja ] || (cd $K && bin/gn gen out/sksl --args='is_official_build=false is_debug=false skia_compile_sksl_tests=true skia_enable_pdf=false
    skia_enable_skottie=false skia_use_dawn=false skia_use_gl=false skia_use_metal=false skia_enable_ganesh=false skia_enable_graphite=false' > /dev/null)
PATH=/opt/homebrew/bin:$PATH ninja -C $K/out/sksl skslc > /dev/null || exit 1
cp $K/src/sksl/sksl_*.sksl $K/out/sksl/   # (the modules skslc reads beside itself: Skia's BUILD.gn copies them so)
old=($E/*/am_*.wgsl(N) $E/*/am_*.am(N)); rm -f $old   # (made again; where each was is kept)
made=0 why=()
for f in $A/app/src/main/assets/effects/*.json(N); do
    n=${f:t:r}
    [[ $n == foreign ]] && continue
    if r=$(python3 $E/sources/from_absent.py $f $W/am_$n.wgsl $K/out/sksl/skslc 2>&1); then made=$((made + 1)); else why+=("$n: ${r##*: }"); fi
done
for f in $W/am_*.wgsl(N) $W/am_*.am(N); do   # (.frag and .raw.wgsl left in W)
    was=${(M)old:#*/${f:t}}
    mv $f ${was:-$E/${f:t}}
    [[ -n $was ]] || echo "new: $E/${f:t} (put it into its folder)"
done
cp $A/LICENSE $E/sources/AbsentMotion-LICENSE.txt && cp $A/NOTICE $E/sources/AbsentMotion-NOTICE.txt
echo "$made made; not made $#why:"
printf '  %s\n' $why
