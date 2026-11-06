#!/bin/zsh
# A group in a group: the outer one's moves as one, the inner one's in turn (check/group_in_group.c).   zsh check/group_in_group.sh
cd "$(dirname "$0")/.."
./edit.sh out/group_in_group_build.motolii < /dev/null > /dev/null 2>&1; rm -f out/group_in_group_build.motolii   # (the library built again if it changed)
rm -f out/group_in_group.motolii
cc check/group_in_group.c -Lout -lmotolii -Wl,-rpath,$PWD/out -o out/group_in_group || exit 1
cd out/wgpu_kit && MOTOLII_MUTE=1 ../group_in_group $PWD/../group_in_group.motolii 2>&1 | grep "^at \|PASS\|FAIL\|not opened"
