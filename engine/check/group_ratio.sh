#!/bin/zsh
# A group's copies dealt to its things by their ratios, its Copies card from when it is made, its Arrange card only when asked (check/group_ratio.c).   zsh check/group_ratio.sh
cd "$(dirname "$0")/.."
./edit.sh out/group_ratio_build.motolii < /dev/null > /dev/null 2>&1; rm -f out/group_ratio_build.motolii   # (the library built again if it changed)
rm -f out/group_ratio.motolii
cc check/group_ratio.c -Lout -lmotolii -Wl,-rpath,$PWD/out -o out/group_ratio || exit 1
cd out/wgpu_kit && MOTOLII_MUTE=1 ../group_ratio $PWD/../group_ratio.motolii 2>&1 | grep "^count \|^thing \|^  copy \|^  picture\|^  the group\|^every \|^the x2\|^by hand\|PASS\|FAIL\|not opened"
