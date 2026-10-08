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
sudo apt update && sudo apt install -y amdrocm10.1-gfx1030
sudo usermod -a -G render,video $LOGNAME   # re-login after
```

`zshrc` points at the `/opt/rocm` symlink (not `/opt/rocm-<ver>`), so upgrades never
need path edits; `rocm-bin`/`core`/`core-10`/`rocm-amdgcn` alternatives are in auto
mode and flip to the newly installed version. Versions install side-by-side
(`/opt/rocm/core-10.0`, `/opt/rocm/core-10.1`) — purge the old one after verifying:
`apt purge -y 'amdrocm-*10.0*' 'amdrocm10.0*' && apt autoremove`.
Verified 2026-09-23: 10.1.0-3, hipcc smoke test PASS on gfx1030 (in-tree driver, no reboot).

Docs: https://rocm.docs.amd.com/en/docs-10.1.0/

### GPU undervolt — RX 6800 XT (`gpu/` in this repo)

**Symptom:** whole machine halts/restarts during long GPU loads (ComfyUI/ROCm) —
GPU thermal limit trips. **Cause:** stock v/f curve runs high voltage at 2.5 GHz;
hotspot heat + current spikes take the card over its limits.

**Fix:** unlock the amdgpu overdrive sysfs, then apply a −75 mV VDDGFX offset at
every boot (`gpu/gpu-undervolt`, applied by `gpu/gpu-undervolt.service`).

```sh
# 1) unlock overdrive (once)
sudoedit /etc/default/grub   # GRUB_CMDLINE_LINUX_DEFAULT="quiet splash iommu=pt amdgpu.ppfeaturemask=0xffffffff"
sudo update-grub && sudo reboot

# 2) after reboot — install and enable the boot-time apply
sudo install -m755 ~/dotfiles/gpu/gpu-undervolt /usr/local/sbin/
sudo install -m644 ~/dotfiles/gpu/gpu-undervolt.service /etc/systemd/system/
sudo gpu-undervolt apply
sudo systemctl enable --now gpu-undervolt
```

**Tuning:** `OFFSET` at the top of the script. −75 mV is safe on ~all 6800 XT
silicon; try −100..−125 for more (artifacts, app crashes or driver resets =
back off). Compare `gpu-undervolt status` under identical load.

**Verify:**

```sh
gpu-undervolt status                          # edge/hotspot/mem °C, power, offset
journalctl -k | grep -iE 'throttl|thermal'    # throttle events (amdgpu logs when hot)
```

Sustained load to reproduce the old halts: run ComfyUI, or a torch matmul loop
(`python3 -c "import torch; a,b=torch.randn(8192,8192,device='cuda'),torch.randn(8192,8192,device='cuda'); [a@b for _ in range(20000)]; torch.cuda.synchronize()"`).

**Rollback:** `sudo gpu-undervolt reset`, `sudo systemctl disable --now gpu-undervolt`.
GUI alternative: CoreCtrl (Ubuntu repos) drives the same sysfs.
If halts persist while hotspot stays < ~95°C, suspect power delivery (PSU
transients / PCIe power connectors), not thermals.

## ssh-agent — enter passphrase once per boot

**Symptom:** `Enter passphrase for key '~/.ssh/id_ed25519'` on every git push /
ssh from a new shell or tmux pane.

**Cause:** each shell/tmux spawned its own `ssh-agent` (found 9 running), so keys
were never cached between shells. No `AddKeysToAgent` either.

**Fix (already applied):**

1. One shared agent as a systemd user service —
   `~/.config/systemd/user/ssh-agent.service`:

   ```ini
   [Unit]
   Description=SSH key agent

   [Service]
   Type=simple
   Restart=on-failure
   Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
   ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK

   [Install]
   WantedBy=default.target
   ```

   ```
   systemctl --user daemon-reload && systemctl --user enable --now ssh-agent
   ```

2. `~/.ssh/config` (chmod 600):

   ```
   Host *
     AddKeysToAgent yes
     IdentityFile ~/.ssh/id_ed25519
   ```

   `AddKeysToAgent` loads the key into the agent automatically on first use —
   no manual `ssh-add` needed.

3. `zshrc` exports the shared socket:

   ```sh
   export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
   ```

The passphrase is then asked once per boot (stored in the agent until logout).
Already-open shells/tmux panes keep their old `SSH_AUTH_SOCK` — restart them or
export the socket path manually. Verify with
`ssh-add -l` (agent answers, even if it lists no identities).

