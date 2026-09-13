# PLATFORMS.md — one dotfiles repo, multiple operating systems

This repo runs on **macOS today** and on **plain Ubuntu** (the live second
platform). **Omarchy adoption is deferred** — the coexistence policy below
applies only when/if omarchy lands; for now treat it as a future-tense
reference. The `./install` script detects the OS via `uname -s` and loads:

1. `install.conf.yaml` — COMMON links, safe on every platform
2. `install-darwin.yaml` or `install-linux.yaml` — platform-only links

## Ubuntu (live second platform)

Plain Ubuntu is feature-detected, not distro-locked:

- **Package manager**: apt for system packages; linuxbrew for user packages
  (feature-detected at `~/.local/bin` and `/home/linuxbrew/.linuxbrew/bin`).
- **tmux >= 3.4 required**: pane-scrollbars and popup syntax in
  `packages/tmux/tmux.conf` need it. Ubuntu 22.04's stock tmux is too old —
  install via the tmux PPA or via linuxbrew (`brew install tmux`).
- **kitty**: shared with macOS. The `macos_*` directives in
  `packages/kitty/kitty.conf` are inert on Linux (kitty ignores them).
- **Font dependency**: Maple Mono NF (the ligature-bearing variant used in
  kitty, tmux-fzf statusline, fzf border labels). Install via linuxbrew
  `brew install --cask font-maple-mono-nf`, or drop the .ttf into
  `~/.local/share/fonts/` and run `fc-cache -f`. **Do NOT use
  `packages/fonts/fontspatched/`** — that's legacy Hasklug Nerd Font for old
  kitty (before the switch to Maple Mono NF).
- **ROCm boxes** (RX 6800/6900 XT / gfx1030): see `docs/ubuntu/OS-TWEAKS.md`
  for the apt repo, group setup, and `HSA_OVERRIDE_GFX_VERSION` rationale. The
  ROCm env exports are guarded in `packages/sh/zshrc-linux` (only fire when
  `/opt/rocm` exists).
- **`~/.tool-versions` is machine-local on Linux**: asdf reads it directly,
  and dotbot's clean step never deletes regular files, so it's safe to leave
  unlinked on Ubuntu. Darwin still links the shared `packages/asdf/tool-versions`.
- **`bin/clean.sh` + `bin/clipcopy`** land in `~/.local/bin` (created by
  dotbot's `create: true`). `clipcopy` dispatches to `pbcopy` (Darwin),
  `wl-copy` (Wayland), or `xclip -selection clipboard` (X11 fallback).

## Rules

- **Common** = tools with identical paths and no platform owner: zsh, git, asdf,
  bat, ruby, gh, ripgrep, atuin, zsh-patina, delta, lazygit (XDG), vscode.
- **Platform** = macOS paths (`~/Library/...`, karabiner, yabai/skhd, iterm,
  macos defaults) OR anything the target Linux environment owns.
- `packages/sh/zshrc` stays cross-platform; OS deltas live in
  `packages/sh/zshrc-darwin` / `packages/sh/zshrc-linux` (sourced by a `uname`
  case at the tail), plus the inline plugin-delta `case` before oh-my-zsh.
- asdf `tool-versions` is shared across platforms (darwin links the shared
  copy; Linux keeps it machine-local).

## Omarchy coexistence policy (DEFERRED — reference only)

If/when omarchy lands, **owns and git-updates** its own config tree and
several well-known paths. Our installs must never fight it. The deny-list
below was verified against the omarchy manual at the time of writing —
**re-verify at omarchy install time**, omarchy has changed terminal/bar/shell
conventions between generations.

| Path | Owner | Policy |
|---|---|---|
| `~/.config/omarchy/**` | omarchy | never touch |
| `~/.config/hypr/**` | omarchy | never touch |
| `~/.config/kitty/` | conditional — foot is omarchy's default terminal | our kitty link is **darwin-only**; revisit only if omarchy's terminal is switched to kitty |
| `~/.tmux.conf` | omarchy ships its own (different prefix/layouts) | **either/or** — darwin-only link today; add to `install-linux.yaml` only as a deliberate decision |
| `~/.bashrc` | omarchy's sanctioned user-extension file | our bash links are **darwin-only**; Linux aliases go *inside* omarchy's .bashrc or a file it sources |
| `~/.config/nvim/` | future conflict — omarchy ships a Neovim setup | decided at omarchy install time (our packages/nvim migration lands on macOS first) |
| git, gh, atuin, bat, ripgrep, delta, lazygit (XDG), vscode | nobody | safe in COMMON |

## Playbook: adopting this repo on a new Linux box

1. `git clone` + `./install` → common + `install-linux.yaml` (Ubuntu shape).
2. For omarchy (when adopted): **check the deny-list against the current
   omarchy manual** before adding anything to `install-linux.yaml`.
3. Shell deltas (PATH/brew/asdf/ROCm) come from `packages/sh/zshrc-linux`
   automatically — feature-detected, no distro assumptions.
4. Homebrew on Linux works (linuxbrew pattern proven on the old `ubuntu`
   branch) but on Omarchy prefer pacman; add tooling via omarchy's own
   package flow, keep this repo for *config*, not packages.

## Machine-local state (never linked on other machines)

- `packages/sh/zshrc` tail: trm-cli alias/source — guarded, skips when the
  path doesn't exist.
- `~/.vim` / `~/.vimrc` legacy nvim links (darwin) — local machine state the
  nvim FLIP will replace.
