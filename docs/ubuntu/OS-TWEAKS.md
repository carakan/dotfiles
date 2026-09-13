# OS-specific tweaks

Platform-specific system tweaks applied outside the dotfiles (PAM, systemd, launchd).
Kept here so a fresh machine can be re-tweaked in minutes.

## Linux (Ubuntu 24.04)

### Process/thread limit — `fork: Resource temporarily unavailable`

**Symptom:** tools that spawn many short-lived processes (e.g. hundreds of `uname`
probes) start failing with `fork: Resource temporarily unavailable` (EAGAIN).

**Cause:** `/etc/security/limits.conf` ships `soft nproc 4096`. Every PAM login
session (console, ssh, sudo) inherits that low soft limit; `ulimit -u` in
`zshrc` only patches the shells that source it.

**Fix (global, permanent):**

```
# /etc/security/limits.conf
*    soft    nproc    8192
*    hard    nproc    8192
```

Apply with `sudoedit /etc/security/limits.conf`, then log out/in (reboot for ssh/sudo
sessions). Current `limits.d/` entries (`10-gamemode.conf`, `25-pw-rlimits.conf`) only
touch the `gamemode`/`pipewire` users, so the `*` entry above governs normal users.

**Safety net in `zshrc`:**

```sh
ulimit -n 200000   # open file descriptors
ulimit -u 8192     # processes; must be <= hard nproc from limits.conf
```

**Verify:**

```sh
ulimit -u          # 8192
ulimit -Hn         # hard fd limit
systemctl show user-$(id -u).slice -p TasksMax   # must be >= nproc; Ubuntu default is high
```

Note: `hard nproc` in limits.conf caps `ulimit -u` — raising the zshrc value further
without raising the hard limit will make `ulimit -u` fail on login shells.

### File descriptors (`too many open files`)

- Linux: set `nofile` soft/hard in `/etc/security/limits.conf` the same way, plus the
  `ulimit -n 200000` line in `zshrc`. Systemd services ignore PAM limits — override per
  unit with `LimitNOFILE=` or globally in `/etc/systemd/system.conf` (`DefaultLimitNOFILE=`).
- macOS: `sudo cp limit.maxfiles /Library/LaunchDaemons/ && sudo launchctl load -w
  /Library/LaunchDaemons/limit.maxfiles` (the `limit.maxfiles` plist in this repo sets
  262144/524288 at boot).

## macOS

- See the `limit.maxfiles` section above.
- Homebrew shims and casks live under `/opt/homebrew`; the `zshrc`/`bashrc` already
  branch on `uname` so no extra tweak is needed.

## ROCm (Ubuntu 24.04, RX 6800 XT / gfx1030)

Installed via the ROCm 10+ repo (`stable.repo.amd.com`, deb822 format — the old
`repo.radeon.com/rocm/apt/*` repos stop at 7.2.4). Kernel uses the in-tree `amdgpu`
driver (no DKMS), which is fine for compute on gfx1030.

Consumer RX 6800/6900 XT is not on AMD's official list, but the same ISA ships for
Radeon PRO W6800 — `HSA_OVERRIDE_GFX_VERSION=10.3.0` in `zshrc` covers it.

```sh
# Repo (one-time)
sudo mkdir --parents --mode=0755 /etc/apt/keyrings
wget https://stable.repo.amd.com/rocm/gpg/packages.gpg -O - | \
    gpg --dearmor | sudo tee /etc/apt/keyrings/amdrocm.gpg > /dev/null
sudo tee /etc/apt/sources.list.d/amdrocm-stable.sources <<'EOF'
X-Repo-Id: amdrocm-stable
Types: deb
URIs: https://stable.repo.amd.com/rocm/core/packages/ubuntu2404/
Suites: stable
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/amdrocm.gpg
Enabled: yes
EOF

# Remove pre-10.0 repos and old installer meta
sudo rm -f /etc/apt/sources.list.d/rocm.list /etc/apt/sources.list.d/amdgpu.list \
    /etc/apt/sources.list.d/amdgpu-proprietary.list /etc/apt/sources.list.d/amdgpu-proprietary.sources
sudo apt purge -y amdgpu-install || true

# Install (arch-targeted metapackage) + GPU access groups
sudo apt update && sudo apt install -y amdrocm10.0-gfx1030
sudo usermod -a -G render,video $LOGNAME   # re-login after
```

`zshrc` points at the `/opt/rocm` symlink (not `/opt/rocm-<ver>`), so upgrades never
need path edits. Verify with `/opt/rocm/bin/rocminfo | grep -i gfx`.

Docs: https://rocm.docs.amd.com/en/docs-10.0.0/

