#!/bin/zsh
# AbsentMotion (Apache-2.0), pinned to one commit, fetched into third_party/AbsentMotion. CMakeLists.txt compiles its
# motion.cpp, scene.cpp, easing.cpp and textanim.cpp as they are (community/absent_motion/).
set -e
cd "$(dirname "$0")/.."
AM_SRC=third_party/AbsentMotion
[ -d $AM_SRC ] && exit 0
mkdir -p $AM_SRC && git init -q $AM_SRC
git -C $AM_SRC -c core.hooksPath=/dev/null fetch -q --depth 1 https://github.com/Comett1225/AbsentMotion.git 0f5d891b7e6fd7260ca6191b4eafef23141230c8
git -C $AM_SRC checkout -q FETCH_HEAD
