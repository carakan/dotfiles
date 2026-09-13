# PLATFORMS.md — one dotfiles repo, multiple operating systems

This repo runs on **macOS today** and is being prepared for **Linux** —
specifically **Omarchy** (Arch + Hyprland, planned adoption). The `./install`
script detects the OS via `uname -s` and loads:

1. `install.conf.yaml` — COMMON links, safe on every platform
2. `install-darwin.yaml` or `install-linux.yaml` — platform-only links

## Rules

- **Common** = tools with identical paths and no platform owner: zsh, git, asdf,
  bat, ruby, gh, ripgrep, atuin, zsh-patina, delta, lazygit (XDG), vscode.
- **Platform** = macOS paths (`~/Library/...`, karabiner, yabai/skhd, iterm,
  macos defaults) OR anything the target Linux environment owns.
- `packages/sh/zshrc` stays cross-platform; OS deltas live in
  `packages/sh/zshrc-darwin` / `packages/sh/zshrc-linux` (sourced by a `uname`
  case at the tail), plus the inline plugin-delta `case` before oh-my-zsh.
- asdf `tool-versions` is shared across platforms.

## Omarchy coexistence policy

Omarchy **owns and git-updates** its own config tree and several well-known
paths. Our installs must never fight it. The deny-list below was verified
against the omarchy manual at the time of writing — **re-verify at omarchy
install time**, omarchy has changed terminal/bar/shell conventions between
generations.

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

1. `git clone` + `./install` → common + `install-linux.yaml` (near-empty by design).
2. **Check the deny-list against the current omarchy manual** before adding
   anything to `install-linux.yaml`.
3. Shell deltas (PATH/brew/asdf) come from `packages/sh/zshrc-linux`
   automatically — feature-detected, no distro assumptions.
4. Homebrew on Linux works (linuxbrew pattern proven on the old `ubuntu`
   branch) but on Omarchy prefer pacman; add tooling via omarchy's own
   package flow, keep this repo for *config*, not packages.

## Machine-local state (never linked on other machines)

- `packages/sh/zshrc` tail: trm-cli alias/source — guarded, skips when the
  path doesn't exist.
- `~/.vim` / `~/.vimrc` legacy nvim links (darwin) — local machine state the
  nvim FLIP will replace.
