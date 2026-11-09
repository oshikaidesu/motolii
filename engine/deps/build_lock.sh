# engine/deps/build_lock.sh: the one build lock of this machine (/tmp/motolii-build.lock), taken by every script that
# writes what all checkouts share (engine/third_party's builds, a GPU busy for minutes), sourced at its top:
#   source deps/build_lock.sh; build_lock "$@"   (after its cd; build_unlock: let it go before the script ends, else at its end)
# The lock is a folder (mkdir is atomic, as the hand-run recipe had it) holding the holder's pid and command. A script
# run by one that holds it (MOTOLII_BUILD_LOCK is the holder's pid, passed down) goes on inside it; a holder that is gone
# (its pid not running: killed, crashed) is broken through; while another holds it, a line every 30 s says who.
# A lock folder with no pid in it is a hand-run recipe's: waited for, and broken only after an hour.
# MOTOLII_BUILD_DRY=<seconds>: take the lock, hold it that long, and end the script there (to see the lock work).
_build_lock_dir=/tmp/motolii-build.lock
_build_lock_mine=0   # (in a function $0 is its own name: the script is $ZSH_ARGZERO)

build_unlock() {
  (( _build_lock_mine )) || return 0
  [ "$(cat $_build_lock_dir/pid 2>/dev/null)" = "$$" ] && rm -rf $_build_lock_dir
  _build_lock_mine=0
  unset MOTOLII_BUILD_LOCK
}

build_lock() {
  local holder said=0
  if [ -n "$MOTOLII_BUILD_LOCK" ] && [ "$(cat $_build_lock_dir/pid 2>/dev/null)" = "$MOTOLII_BUILD_LOCK" ] && kill -0 $MOTOLII_BUILD_LOCK 2>/dev/null; then
    echo "${ZSH_ARGZERO:t}: inside the build lock of $MOTOLII_BUILD_LOCK" >&2
  else
    until mkdir $_build_lock_dir 2>/dev/null; do
      holder=$(cat $_build_lock_dir/pid 2>/dev/null)
      if [ -n "$holder" ] && ! kill -0 $holder 2>/dev/null; then   # (its holder is gone: broken through, if no one did so first)
        mv $_build_lock_dir $_build_lock_dir.gone.$$ 2>/dev/null && echo "${ZSH_ARGZERO:t}: build lock of $holder broken (not running)" >&2
        rm -rf $_build_lock_dir.gone.$$; continue
      fi
      if [ -z "$holder" ] && [ -n "$(find $_build_lock_dir -maxdepth 0 -mmin +60 2>/dev/null)" ]; then   # (a hand-run recipe's, an hour old)
        mv $_build_lock_dir $_build_lock_dir.gone.$$ 2>/dev/null && echo "${ZSH_ARGZERO:t}: build lock with no holder, an hour old, broken" >&2
        rm -rf $_build_lock_dir.gone.$$; continue
      fi
      if [ $((said % 30)) = 0 ]; then echo "${ZSH_ARGZERO:t}: waiting for the build lock: ${holder:-?} $(cat $_build_lock_dir/command 2>/dev/null)" >&2; fi
      sleep 1; said=$((said + 1))   # (not (( said++ )): it is 0 the first time, a failure that ends a set -e script)
    done
    echo $$ > $_build_lock_dir/pid
    print -r -- "${ZSH_ARGZERO:t} $*" > $_build_lock_dir/command
    _build_lock_mine=1
    export MOTOLII_BUILD_LOCK=$$
    autoload -Uz add-zsh-hook && add-zsh-hook zshexit build_unlock   # (at its end, whatever trap the script sets)
  fi
  if [ -n "$MOTOLII_BUILD_DRY" ]; then
    echo "${ZSH_ARGZERO:t}: holding the build lock $MOTOLII_BUILD_DRY s (MOTOLII_BUILD_DRY), building nothing" >&2
    sleep $MOTOLII_BUILD_DRY; exit 0
  fi
}
