#!/usr/bin/env bash
# ROCm 10 + general disk garbage cleaner for Ubuntu 24.04
# Safe to re-run. Review before running: it purges packages and caches.
set -uo pipefail

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi

say "Stale Ubuntu-repo ROCm libs (superseded by amdrocm 10.0 in /opt/rocm)"
$SUDO apt-get purge -y libamd-comgr2 libamdhip64-5 libhsa-runtime64-1 libhsakmt1

say "Old kernels + residual 'rc' packages"
$SUDO apt-get autoremove --purge -y

say "apt cache (2.0G)"
$SUDO apt-get clean
$SUDO rm -rf /var/lib/apt/lists/*

say "systemd journals (533M -> 100M)"
$SUDO journalctl --vacuum-size=100M

say "pip cache (11G)"
rm -rf ~/.cache/pip
command -v pip >/dev/null && pip cache purge 2>/dev/null

say "uv cache (1.9G)"
command -v uv >/dev/null && uv cache clean || rm -rf ~/.cache/uv

say "ROCm comgr cache (1.7G, regenerated on demand)"
rm -rf ~/.cache/comgr

say "Homebrew cache + old versions (401M)"
command -v brew >/dev/null && brew cleanup --prune=all

say "Repo debris (old 7.1.1 installer .deb, stray tarball)"
rm -fv ~/dotfiles/amdgpu-install_7.1.1.70101-1_all.deb ~/dotfiles/tarball.tar.gz

say "Done — space now"
df -h / | tail -1
