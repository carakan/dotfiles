#!/bin/bash
# Verify the compiled LLVM builds are intact and that brew's keg entries are
# only symlinks into them.
#
# WHY THIS EXISTS (Intel macOS only)
# ---------------------------------
# Homebrew is Tier 3 on Intel macOS: no bottles, every upgrade compiles from
# source, and upstream publishes no macOS x86_64 prebuilt for llvm 23.x. So
# `brew install llvm` costs ~1 h here, and each compiled build is parked
# outside brew's reach:
#
#   ~/.local/opt/llvm-builds/<version>/            <- the real, compiled build
#   /usr/local/Cellar/llvm/<version> -> the build  <- what brew sees
#
# The build must NOT live under /usr/local/Cellar: brew enumerates every
# directory there as a *formula name*, so a build stored there breaks any
# operation that walks the Cellar ("Error: crystal: No available formula with
# the name '.llvm-builds'"). It must not be a hidden dir either - same
# enumeration problem, and hidden paths are what makes a build look like it
# does not exist. ~/.local/opt is user-owned, invisible to brew, and matches
# the machine's ~/.local convention.
#
# Consequences:
#   - brew cleanup / a failed install's rollback cannot delete the build: it
#     is not in the Cellar and not a keg.
#   - the keg symlink IS brew's to remove (that is fine); the check restores
#     it and can re-point it at any preserved build.
#   - /usr/local/lib/libLLVM-<major>.dylib points at the current build, which
#     is how crystal's bootstrap link finds it (its -L to llvm's lib dir does
#     not survive the build).
#
# Run it after any brew operation that touched llvm, and before blaming
# "llvm is missing" on brew.
#
# ELSEWHERE
# ---------
# On Apple Silicon (bottles exist) and on Linux (a normal package manager)
# this scheme is unnecessary - the script detects that and exits 0 without
# doing anything. It never fails a non-Intel machine.
set -uo pipefail

# --- platform guard: the scheme only exists on Intel macOS ---
if [ "$(uname -s)" != "Darwin" ]; then
  echo "not macOS - the parked-llvm scheme is Intel-macOS-only, nothing to check."
  exit 0
fi
if [ "$(uname -m)" != "x86_64" ]; then
  echo "not Intel macOS (this is $(uname -m)) - brew ships bottles here, so llvm"
  echo "installs from a bottle and needs no parked build. Nothing to check."
  exit 0
fi
if ! command -v brew >/dev/null 2>&1; then
  echo "brew not found - nothing to check."
  exit 0
fi

BREW_PREFIX=$(brew --prefix 2>/dev/null)
if [ -z "$BREW_PREFIX" ] || [ ! -d "$BREW_PREFIX/Cellar" ]; then
  echo "brew prefix not usable ('$BREW_PREFIX') - nothing to check."
  exit 0
fi

BUILDS="$HOME/.local/opt/llvm-builds"
CELLAR="$BREW_PREFIX/Cellar"
failures=0

note() { echo "  $1"; }
fail() { echo "  FAIL: $1"; failures=$((failures + 1)); }

if [ ! -d "$BUILDS" ]; then
  echo "FAIL: $BUILDS does not exist - no compiled llvm build is preserved."
  echo "      Recompiling takes ~1 h. Treat this as a build emergency."
  exit 1
fi

builds=$(ls -1 "$BUILDS" 2>/dev/null)
if [ -z "$builds" ]; then
  echo "FAIL: $BUILDS is empty - the compiled llvm build is gone."
  exit 1
fi

echo "llvm builds preserved in $BUILDS:"
current=""
for v in $builds; do
  build="$BUILDS/$v"
  problems=""

  [ -L "$build" ] && problems="$problems is-a-symlink"
  [ -f "$build/INSTALL_RECEIPT.json" ] || problems="$problems no-receipt"
  [ -x "$build/bin/llvm-config" ] || problems="$problems no-llvm-config"
  ls "$build"/lib/libLLVM*.dylib >/dev/null 2>&1 || problems="$problems no-libLLVM"

  if [ -n "$problems" ]; then
    fail "$v:$problems"
  else
    note "$v intact ($(du -sh "$build" 2>/dev/null | cut -f1), llvm-config $("$build/bin/llvm-config" --version 2>/dev/null))"
  fi

  # brew's view of this build: a symlink into ~/.local/opt/llvm-builds,
  # never a real directory it can wipe
  keg="$CELLAR/llvm/$v"
  if [ -L "$keg" ]; then
    target=$(readlink "$keg")
    if [ "$target" != "$build" ]; then
      fail "$keg -> $target (expected $build)"
    fi
  elif [ -d "$keg" ]; then
    fail "$keg is a real directory - a build stored there is one brew can delete."
    echo "        move it: mv $keg $build && ln -s $build $keg"
  else
    echo "  repairing: keg symlink for $v was missing"
    ln -s "$build" "$keg" || fail "could not create $keg"
  fi
  current="$v"
done

# the version brew considers current
opt_current=$(readlink "$BREW_PREFIX/opt/llvm" 2>/dev/null | sed 's|.*/||')
if [ -n "$opt_current" ]; then
  note "opt/llvm -> $opt_current"
  if [ ! -e "$BREW_PREFIX/opt/llvm" ]; then
    fail "$BREW_PREFIX/opt/llvm does not resolve"
  fi
else
  fail "$BREW_PREFIX/opt/llvm is missing"
fi

# the versioned dylib in the default linker search path (crystal's bootstrap
# link needs it: the -L to llvm's lib dir does not survive the build)
if [ -n "$current" ]; then
  major=$(echo "$current" | cut -d. -f1)
  dylib="$BREW_PREFIX/lib/libLLVM-$major.dylib"
  target="$BUILDS/$current/lib/libLLVM-$major.dylib"
  if [ -L "$dylib" ] && [ "$(readlink "$dylib")" = "$target" ]; then
    note "lib/libLLVM-$major.dylib -> current build"
  else
    echo "  repairing: $dylib did not point at the current build"
    ln -sfn "$target" "$dylib" || fail "could not create $dylib"
  fi
fi

if [ "$failures" -eq 0 ]; then
  echo "OK: every compiled llvm build is intact and reachable."
  exit 0
fi
echo "FAILED: $failures problem(s). Do not let brew rebuild llvm - it will."
exit 1
