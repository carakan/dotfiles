#!/bin/bash
# Park the freshly compiled llvm build and turn the Cellar entry into a symlink.
#
# Layout after this (Intel macOS only - see check-llvm-keg.sh for why):
#   ~/.local/opt/llvm-builds/23.1.4/            <- the real, compiled build (kept forever)
#   /usr/local/Cellar/llvm/23.1.4 -> the build  <- what brew sees
#   /usr/local/opt/llvm -> ../Cellar/llvm/23.1.4
#   /usr/local/lib/libLLVM-23.dylib -> the build <- default linker search path
#
# On a future bump (llvm 23.2.0):
#   1. brew install llvm                # compiles the new version
#   2. ./park-llvm.sh                   # moves it to ~/.local/opt/llvm-builds/
# The previous build stays there - it is never deleted, and its
# /usr/local/Cellar/llvm/<old-version> symlink keeps resolving for anything
# that needs that exact version.
set -uo pipefail

if [ "$(uname -s)" != "Darwin" ] || [ "$(uname -m)" != "x86_64" ]; then
  echo "not Intel macOS - the parked-llvm scheme is only needed there"
  echo "(no bottles on Tier 3, no upstream x86_64 prebuilt for llvm 23.x)."
  echo "Nothing to park."
  exit 0
fi
if ! command -v brew >/dev/null 2>&1; then
  echo "brew not found - nothing to park." >&2
  exit 1
fi

BREW_PREFIX=$(brew --prefix 2>/dev/null)
CELLAR="$BREW_PREFIX/Cellar"
BUILDS="$HOME/.local/opt/llvm-builds"

# the newest real (non-symlink) keg brew just built
V=$(find "$CELLAR/llvm" -maxdepth 1 -type d -name '[0-9]*' -exec basename {} \; 2>/dev/null | sort -V | tail -1)
if [ -z "$V" ]; then
  echo "no built llvm keg found in $CELLAR/llvm" >&2
  exit 1
fi

echo "==> built keg: $CELLAR/llvm/$V"
mkdir -p "$BUILDS"

if [ ! -L "$CELLAR/llvm/$V" ]; then
  echo "==> moving the real build to $BUILDS/$V"
  mv "$CELLAR/llvm/$V" "$BUILDS/$V" || exit 1
  ln -s "$BUILDS/$V" "$CELLAR/llvm/$V" || exit 1
else
  echo "==> $CELLAR/llvm/$V is already a symlink, leaving it"
fi

# opt/llvm must point at the version brew considers current
ln -sfn "../Cellar/llvm/$V" "$BREW_PREFIX/opt/llvm"

# the versioned dylib in the default linker search path
major=$(echo "$V" | cut -d. -f1)
ln -sfn "$BUILDS/$V/lib/libLLVM-$major.dylib" "$BREW_PREFIX/lib/libLLVM-$major.dylib"

echo "==> layout:"
ls -la "$CELLAR/llvm/" | tail -n +2
echo "    real build: $BUILDS/$V ($(du -sh "$BUILDS/$V" | cut -f1))"
echo "    llvm-config: $("$BREW_PREFIX/opt/llvm/bin/llvm-config" --version 2>/dev/null)"
echo "    receipt: $([ -f "$BUILDS/$V/INSTALL_RECEIPT.json" ] && echo present || echo MISSING)"
echo "    libLLVM-$major.dylib -> $BUILDS/$V/lib/libLLVM-$major.dylib"
