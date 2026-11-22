# AGENTS.md — dotfiles repo playbook

Standing rules and procedures for this machine. Start here, don't re-derive.

**History, rationale, measurements and implementation specs live in
[`CHANGELOG.md`](CHANGELOG.md).** This file says what to do; the changelog says
how the current state was reached and how each fix works. When a rule below
looks arbitrary, the changelog has the incident behind it.

## 0. Git policy — NEVER commit automatically

- **Do not run `git commit` without the user's explicit approval, per
  change.** Edit files → show `git status` / `git diff` → let the user commit.
  Stage only the paths the user names.
- `git reset --soft|--mixed` to un-commit my own local commits is expected
  when asked; never rewrite pushed history.

## 0b. Change tracking — every tweak lives in this repo

- The tracked artifact lives in the repo; machine state is a **symlink** to it
  (`packages/<tool>/<config>` → `$HOME`) or a copy produced by a tracked
  script. A hand-edited file in `$HOME` or a one-off `sed` on a system file is
  an uncounted change: it cannot be reviewed, and dotbot will overwrite it.
- Behavioural change → an executable, idempotent script in the repo
  (`packages/<tool>/<name>.sh`, documented in its header). Never "run this
  once by hand".
- Anything outside `$HOME` (system file, keg, LaunchAgent, `/etc`) needs
  **both** an idempotent script that applies it **and** prose saying what it
  patches, why, and how to verify.
- Verification must be reproducible from the repo (a check script, a config
  load, a command whose output proves it) — not the agent's memory.
- A revert must be recorded too, so the repo never claims a state the machine
  no longer has.
- If a change cannot be expressed as a tracked artifact, say so instead of
  leaving the machine in a state the repo does not describe.

## 1. Runtime tooling policy (brew vs asdf)

- **Intel x86_64 macOS → Homebrew is Tier 3**: no bottles, every formula
  upgrade compiles. Small CLI tools are fine; big runtimes are not.
- **Runtimes belong to asdf, never brew** (nodejs, bun, python). **rust**
  comes from the rustup toolchain, never asdf, never brew.
  `~/.tool-versions` is the source of truth (asdf 0.20: `asdf set -u <tool>
  <version>`; there is no `asdf global`). Resolution: nearest
  `.tool-versions` walking up wins, `ASDF_<TOOL>_VERSION` beats both, several
  versions on one line are **fallbacks** (first installed wins). A pin to an
  uninstalled version (`asdf current <tool>` → `false`) makes every shim of
  that tool fail — delete the dead pin, do not build it (Python 2.7 cannot
  build on macOS 15+).
  Upgrade: check `asdf list <tool>` first (the version may already exist) →
  `asdf install <tool> <ver>` → `asdf set -u` → `asdf reshim <tool>`.
- Brew kegs for runtimes are **symlinks into `~/.asdf/installs/…`** with a
  copied `INSTALL_RECEIPT.json` whose `source.versions.stable` matches the keg
  name exactly (revision suffix included). Procedure and traps:
  `docs/brew-intel-symlink-workaround.md`. Revision bumps (`x.y.z_1`) are
  swaps — rename the keg/symlink, rewrite the receipt, repoint
  `/usr/local/opt/<formula>` and the `/usr/local/bin` links — never builds.
- **neovim is the nightly, symlinked into brew, pinned.** Keg
  `/usr/local/Cellar/neovim/0.12.6` → `~/.local/opt/nvim-nightly`; brew still
  reports the last stable because keg name, receipt and formula stable must be
  one string. Source: `github.com/neovim/neovim/releases/tag/nightly`.
  Refresh with `packages/nvim/update-nightly.sh`, which also rewires
  `/usr/local/opt/neovim`, `/usr/local/bin/nvim` and `/usr/local/lib/nvim`
  (upstream builds the nightly with prefix `/usr/local`, so the parsers load
  from there).
  `brew pin neovim`. `brew info neovim` fails with "linked/neovim is not
  inside a keg" — harmless. Never compile neovim.
- **Never run `brew cleanup`, and never let brew run one.** (`brew cleanup
  --purge` does not exist; plain `brew cleanup <formula>` drops old kegs.)
  `HOMEBREW_NO_INSTALL_CLEANUP=1` is set in `packages/sh/zshrc-darwin`.
  Install formulae as *requested* and keep them as top-level `Brewfile`
  entries, or brew's bookkeeping treats them as disposable.
- **llvm is compiled once and never deleted.** Homebrew has no Intel bottle
  and upstream ships no macOS x86_64 build. The real build lives in
  `~/.local/opt/llvm-builds/<version>`; `Cellar/llvm/<version>` is only a
  symlink, and `/usr/local/lib/libLLVM-<major>.dylib` points at the current
  build. **Never delete a build, never park one inside `Cellar/`** (brew reads
  every directory there as a formula name), and do not let a failed install's
  rollback replace the build with a real directory.
  `packages/llvm/check-llvm-keg.sh` verifies and repairs the links (exit 0 =
  safe); `packages/llvm/park-llvm.sh` parks a new build. Note
  `/usr/local/lib/libLLVM.dylib` (unversioned) is rust's own LLVM.
- **crystal's bootstrap needs `/usr/local/lib/libLLVM-<major>.dylib`**
  (its build links `-lLLVM-<major>` without a surviving `-L`); the check
  script maintains it.
- Small tools upgrade via brew and build from source on purpose (direnv, git,
  engram). `brew pin` blocks dependent installs — runtimes stay unpinned.
  engram = `gentleman-programming/tap/engram` (formula and cask share the
  name, use the full tap name). "Untrusted tap" warnings for `carakan/local`
  and `jstkdng/programs` are noise.
- **Network firewall:** `proxy.golang.org`, `golang.org`, `crates.io`,
  `static.crates.io` are unreachable; only `github.com`, release CDNs and
  `registry.npmjs.org` answer. Go module builds and Rust builds cannot compile
  here — use the official release binary (brew doc). Vendored Go and npm
  builds work.
- Known broken: `awscli`, `sphinx-doc`, `gobject-introspection` (no binary),
  `meson` tracebacks — site-packages lost in the python-keg swap. Reinstall;
  not a python rebuild.
- asdf's python and brew's framework python disagree on paths: bridge with a
  `.pth` in the asdf install's site-packages listing both directories.

## 2. asdf gotchas

- Shims (`~/.asdf/shims`) are first on PATH and shadow `/usr/local/bin`. An
  orphan shim silently overrides brew binaries: delete that shim + `hash -r`.
- `asdf reshim <plugin>` after touching versions.
- `asdf uninstall` takes one version per call; loop for multiples.
- Never purge old asdf versions wholesale — projects pin them locally.

## 3. Dotfiles conventions

- Layout: `packages/<tool>/<config>` symlinked into `$HOME` (e.g.
  `~/.config/kitty` → `packages/kitty`, `~/.tmux.conf` → `packages/tmux/tmux.conf`). Absolute paths
  (`/Users/carakan/.dotfiles/packages/...`) inside configs are the norm.
- **Brewfile discipline**: anything intentionally installed outside brew gets
  a comment in `Brewfile` explaining why, so `brew bundle` never resurrects
  it. Currently yabai (manual, see §4).
- LaunchAgents: plists in `packages/<tool>/`, symlinked into
  `~/Library/LaunchAgents/` by `install-darwin.yaml`. Any script they call
  must set its own PATH (`/usr/local/bin` first) — launchd gives a bare
  `/usr/bin:/bin`.
- Work products (docs, scripts) belong in this repo, not scattered in `$HOME`.

## 4. yabai / skhd

- **Manual install, checksummed**, at `/usr/local/bin/yabai`; brew must not
  own it. Installed: **v7.3.5**, sha256
  `f25c6b50a9a71736403bf0051b2f23e70ff36ecfcfee92193fb5f5cd98d94927`,
  scripting-addition payload **2.1.39**.
- **Upgrade procedure** (root step included, order matters):
  1. download the release tarball + `.sha256`, verify it, and cross-check the
     inner binary against the digest GitHub reports for the bare `yabai` asset;
  2. copy the old binary to `~/.local/state/yabai/yabai-v<old>.bak`;
     `install -m 755` the new one;
  3. rewrite the digest in `/etc/sudoers.d/yabai` — the rule pins
     `sha256:<digest> /usr/local/bin/yabai --load-sa`, mode 640;
  4. bump `CFBundleVersion`/`CFBundleShortVersionString` in
     `packages/yabai/Yabai.app/Contents/Info.plist`, replace the agent symlink
     (`rm` + `ln -s`) and `launchctl bootout` + `bootstrap` the job;
  5. `yabairc` runs `--load-sa` itself on start, installing the payload.
  Do **not** restart the daemon before step 3: `--load-sa` cannot prompt
  without a TTY, the SA then never loads, no window events fire and the
  window manager is dead.
  Restart without touching the plist:
  `launchctl kickstart -k gui/501/com.asmvik.yabai`; verify with
  `sudo /usr/local/bin/yabai --load-sa` and the socket file.
- **The SA is required.** Without it `window_created` / `window_focused` /
  `application_*` never fire (borders freeze), and window opacity, shadows
  and mouse handling stop working. Two hard requirements: the NOPASSWD rule
  above, and SIP's Filesystem Protections **and** Debugging Restrictions
  disabled (`csrutil disable --no-debugger --no-filesystem`, Recovery-only,
  keeping `--no-restricted --no-unsigned`) — the fork checks
  `CSR_ALLOW_UNRESTRICTED_FS` and `CSR_ALLOW_TASK_FOR_PID` and refuses
  otherwise. The SA also gates `normal_window_opacity`,
  `mouse_modifier`/`mouse_action1`/`mouse_action2`/`mouse_drop_action` and
  `window_shadow`. Socket: `/tmp/yabai-sa_<username>.socket` (named after the
  user, e.g. `/tmp/yabai-sa_carakan.socket`) — missing means the SA is dead. `yabairc`
  re-arms it on `dock_did_restart`.
- **Both LaunchAgents are repo-managed** and launch app bundles
  (`packages/yabai/Yabai.app`, `packages/yabai/YabaiSessionRestore.app`), never
  the raw binary: macOS takes
  the Login Items name from the launched executable. The daemon launcher is
  an unsigned wrapper that execs `/usr/local/bin/yabai`, so the row shows no
  developer. BTM caches the row per `~/Library/LaunchAgents` directory event —
  after editing a plist, replace the symlink and re-bootstrap, or the old name
  sticks. Process is named "Yabai" (`pgrep -x yabai` does not match).
  The daemon agent is `KeepAlive true` so a clean exit at login restarts it.
- Logs: `~/.local/state/yabai/yabai.err.log` (never `/tmp` — wiped at boot).
- `packages/yabai/session_restore.sh` is the safety net: after 20 s without a socket it
  re-enables and bootstraps `com.asmvik.yabai`, then waits up to 5 min. Exit
  1 = yabai itself never came up.
- Configs: `packages/yabai/yabairc` (spaces, rules, border signal via
  `packages/yabai/update_border_color.sh`, SA reload)
  and `packages/yabai/skhdrc`. Space labels and display assignments go
  through `space_label` / `space_to_display`, which skip no-op calls; keep new
  lines on those helpers so a clean login writes nothing to the error log.
- **skhd's LaunchAgent is local, not repo-managed**
  (`~/Library/LaunchAgents/com.koekeishiya.skhd.plist`) and runs
  `~/.config/skhd/skhd-launch.sh`, which retries in a loop (skhd 0.3.9 aborts
  when another app holds SecureEventInput). Its Login Items row reads
  "skhd-launch" — **never delete it**: skhd runs every yabai shortcut. If
  shortcuts stop, check `pgrep -fl skhd` first.
- Workspace sessions: `ctrl+alt-s` saves to
  `~/.local/state/yabai/session.json`, `ctrl+alt-r` re-applies,
  `com.carakan.yabai-session` loads it once at login. Log:
  `~/.local/state/yabai/restore.log`.

## 5. Terminal stack

- **Font: Maple Mono NFMT** (`MapleMono-NFMT-{Light,Bold,LightItalic,BoldItalic}`).
  NFMT = NFM (Nerd Font icons normalised to one cell) with the icons stretched
  vertically to cap height, produced by `packages/fonts/nfmt-icon-scale.py`.
  The stock NFM and NF families stay installed for rollback.
  `kitty.conf` sets `font_features` per **PostScript name**:
  `+calt +zero +cv01 +cv02 +cv03 +cv04 +cv10 +cv64 +cv67 +ss04 +ss05`. Do not
  add `onum` (the font has no such feature) and do not pair `cv64` with
  `ss02` (cv wins) or `cv69` with `cv01` (same glyph). `narrow_symbols` must
  keep the whole NF private-use area at one cell; there is deliberately **no
  `symbol_map`** — every NF codepoint is in the primary face, and a symbol
  face is what made icons render at two sizes.
- **kitty 0.51.0** (`packages/kitty/kitty.conf`): scrollbar
  scrolled-or-hovered, `padding_fill_strategy neighboring_cell`, native
  `cursor_trail 3`. No `custom_shaders` — shader pipelines were removed and
  must not be re-added casually. Remote control is
  `allow_remote_control socket-only` + `listen_on unix:kitty-{kitty_pid}`
  (per-instance socket; `socket-only` denies TTY requests). `listen_on` is
  **not reloadable** — it applies on the next kitty start. Launch task windows
  with an explicit command (`kitty @ launch --type=window -- <cmd>`); a bare
  shell lets the omz tmux plugin steal the session.
- **fzf ≥ 0.75.0** (`packages/sh/fzf.zsh`): the info line is an opt-in toggle
  (`alt-i` / `alt-u`), never a permanent `--info-command`; label transforms
  use the `bg-` variants and the list label sits on `result-final`. Bind
  bodies must be **POSIX** (`$SHELL -c`, dash-safe: `[ … ]`, quoted
  `$FZF_QUERY`). `--border` and `--popup` must never both be set (every picker
  dies silently). Keep the `FZF_DEFAULT_OPTS` terminator byte-exact.
  Run `packages/fzf/check-fzf.sh` after any fzf upgrade or bind edit.
- **zsh**: deja (autosuggestions) is sourced **after** zsh-patina in
  `packages/sh/zshrc` — patina repaints the line and erases the ghost text,
  and omz's plugin order cannot express this. Keep the `DEJA_*` vars beside
  the integration. p10k theme `packages/sh/pk10.zsh` (symlinked to
  `~/.p10k.zsh`): no `context` element, element is `vcs`, and the gitstatus
  plugin must start **before** `oh-my-zsh.sh`;
  `POWERLEVEL9K_DIR_MAX_LENGTH=0` (fish-style shortening).
- **tmux** (`packages/tmux/tmux.conf`, symlinked live): the long-command
  finisher is **shell-only** — `packages/sh/zshrc` sources
  `bin/tmux-agent-hooks`, whose `preexec`/`precmd` hooks call
  `bin/tmux-agent-notify` for runs >= `@agentic-notify-secs` (default 30).
  Never re-add a tmux monitor path without first proving on the running tmux
  that a `set-hook -B` subscription actually fires: 3.8 registers them and
  never fires them (re-verified 2026-11-22 at global, session and pane
  scope), and the deleted `tmux-agent-{monitors,start,done}` existed only to
  work around that. There is no tmux-side run state: the `@busy-*` pane
  options are gone, so nothing can go stale. The silence watchdog does not
  use monitors. `pane-scrollbars` is `auto-hide`; revert that one line if
  Termius shows corruption. **FROZEN by the user**: never touch the zshrc
  clear-on-attach scoping without an explicit request — breaking it
  re-creates the phone "ascii garbage" bug. 3.8-only lines stay gated on the
  option existing.
- **`packages/sh/zshenv` → `~/.zshenv`** is the only file sshd exec channels
  source; it puts `/usr/local/bin` and `~/.local/bin` on PATH. Non-negotiable.
  `packages/sh/profile` → both `~/.profile` and `~/.zprofile`.
- **Mobile/Termius**: plain SSH. Auto-attach is SSH-only
  (`SSH_CONNECTION`): the takeover block does `attach -d` onto
  `$TMUX_AUTO_SESSION` (default `main`), desk↔phone swap semantics.
  `TMUX_AUTO_ATTACH_OFF=1` opts a connection out. ANSI half-block art
  only, no pixel protocols; `bin/clipcopy` is the tmux↔system clipboard sink.
- **mosh is forbidden with Termius** — the client sends no terminal type,
  mosh-server clamps to 8 colours and loses scrollback. Do not retry.
- **delta 0.21.2 + lazygit 0.66.3** (`packages/git/gitconfig`,
  `packages/lazygit/config.yml`, `packages/delta/themes.gitconfig`): delta is
  git's pager via `--features=lazygit-carakan`, the only locally defined theme.
  lazygit ignores unknown features silently, so a typo there downgrades the
  renderer without an error. Renderers template `--{{colorScheme}}` and gate
  `--side-by-side` on `{{if gt .width 140}}`. `[delta] hyperlinks = true`.
  `git.diffContextSize: 1` mirrors `[diff] context = 1`.

## 5b. Neovim / vim

- **nvim-scrollbar is v2** (v1 option names are rejected). Live setup:
  `lua/plugins/scrollbar.lua`, wired by `plugins.lua`'s `safe('scrollbar')`;
  the dormant copy in `legacy-lua-extracted.lua` must stay in sync. The v1→v2
  option mapping is in `CHANGELOG.md` (2026-11-16). Do not remove the plugin:
  this nvim build has no `+scrollbar` and tmux draws no scroll indicator.
- **supra-vim's OmniComplete autocmd is broken** — `packages/vim/vimrc.local`
  clears it and installs a one-line replacement that also checks
  `&modifiable`. Any multi-line `:autocmd` with `\` continuations must be
  written on one line.
- **vim-rooter**: `g:rooter_patterns` excludes `package.json` (nearest
  ancestor wins; a nested package.json hijacked the root and compounded
  session paths). Keep `g:rooter_silent_chdir` (not `…changetocwd`) and
  `g:rooter_manual_only` together with the explicit once-only `Rooter` calls.
- **Sessions live in `~/.vim/session/`, not the repo**: `~/.vimrc` →
  `~/.supra-vim/.vimrc` → `~/.vimrc.local` → `packages/vim/vimrc.local`.
  `packages/nvim/` is the not-yet-applied 0.10→0.13 migration, not what runs;
  `packages/nvim/FLIP.md` phase 5 would delete the session store.

## 6. Recipes

### Update a small CLI tool
`brew update && brew upgrade --formula <tool>` — source build expected; verify
with `brew list --versions` and run the binary.

### Update node/python
asdf path (§1). Never `brew upgrade` them. If a keg symlink must track the new
version, follow `docs/brew-intel-symlink-workaround.md`.

### Update llvm
`brew install llvm` (~54 min) → `packages/llvm/park-llvm.sh` →
`packages/llvm/check-llvm-keg.sh`. Older builds stay parked and keep their
`Cellar/llvm/<version>` symlink. Never let brew rebuild llvm to "fix" a
missing keg — repair the symlink.

### App "damaged / can't be opened"
`xattr <app>` → `xattr -dr com.apple.quarantine <app>` → `codesign -vv --deep`.
Quarantined **and** unsigned binaries get SIGKILLed (exit 137, no output);
adhoc-sign with `codesign --force --sign - <bin>`. If the seal is broken by
injected files, the app is tampered — report it, do not re-sign.

### New LaunchAgent
Script in `packages/<tool>/` with its own PATH, plist in
`packages/<tool>/` symlinked into `~/Library/LaunchAgents`, log to a stable
file under `~/.local/state/`, then
`launchctl bootstrap gui/501 ~/Library/LaunchAgents/<label>.plist`.

## 7. Platform scope (read before porting)

This is an Intel macOS configuration, but the configs are cross-platform: the
machine-specific parts are isolated and inert elsewhere.

| Piece | Where | Scope |
|---|---|---|
| `install-darwin.yaml` / `install-linux.yaml` | repo root | chosen by `./install` via `uname -s` |
| `packages/llvm/*.sh` (`.llvm-builds` scheme) | `packages/llvm/` | Intel macOS only — scripts gate on `uname`, exit 0 elsewhere |
| `packages/yabai/`, `packages/karabiner/`, `packages/macos/`, `packages/iterm/` | `packages/` | macOS only |
| `bin/ubuntu_clean_rocm.sh` | `bin/` | Linux only |
| asdf ↔ brew keg symlinks | `docs/brew-intel-symlink-workaround.md` | Intel-only workaround; Apple Silicon and Linux use their package managers |
| parked llvm builds | `~/.local/opt/llvm-builds/` | Intel-only (no bottles, no upstream x86_64 prebuilt) |

Rules:

- **Never hardcode `/usr/local` or `x86_64`** — read `brew --prefix`
  (`/usr/local` on Intel, `/opt/homebrew` on Apple Silicon) and gate on
  `uname -s` / `uname -m`.
- Put the guard in the script that needs it, and make "not applicable" exit
  **0**.
- Platform-specific config stays in `packages/<tool>/` or the
  `install-<os>.yaml` files, never in a shared config.

## Gotchas that bite outside their section

- The automation shell can inherit `TMUX=/usr/local/bin/tmux` (a path, not a
  socket spec): every client call then fails with
  `error connecting to /usr/local/bin/tmux (Socket operation on non-socket)` —
  the message names the socket path, not the binary. Use `env -u TMUX`.
- `pgrep -x yabai` matches nothing; the daemon process is named `Yabai`.
- kitty remote control needs `KITTY_LISTEN_ON` in the pane environment; tmux
  forwards it via `update-environment`.
