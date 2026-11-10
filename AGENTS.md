# AGENTS.md — dotfiles repo playbook

For any agent working in this repo: the machine conventions, the tooling
policy, and the recurring tasks. Start here, don't re-derive.

## 0. Git policy — NEVER commit automatically

- **Do not run `git commit` in this repo without the user's explicit
  approval, per change.** The user wants to monitor and review every change
  before it enters history.
- Default flow: edit files → show the diff (`git status`, `git diff`) → let
  the user commit. Stage only the exact paths the user names.
- `git reset --soft` / `git reset --mixed` to un-commit my own local commits
  is allowed (and expected) when the user asks; never rewrite pushed history.

## 0b. Change tracking — every tweak lives in this repo

- **Every change to this machine's configuration is tracked here.** A tweak
  that lives only on the machine (a hand-edited dotfile in `$HOME`, a
  one-off `sed` on a system file, a manual `brew link`, a hand-written
  `~/.tmux.conf` line, an env var exported from a shell profile that is not
  in this repo) is **not a change — it is an untracked change**, and it is
  forbidden. It cannot be reviewed, cannot be reproduced on the other
  machine, and will be silently lost the next time dotbot relinks a file.
- **The rule:** the tracked artifact lives in this repo, and the machine's
  state is a *symlink* to it (or a copy produced by a tracked script).
  - Config file → `packages/<tool>/<config>`, symlinked into place.
  - A behavioural change that needs a command → a **script in this repo**
    (`packages/<tool>/<name>.sh`, executable, idempotent, documented in
    its header) that performs the change. Never "run this once by hand".
  - A decision that changed a file's content → the change is in the file
    in this repo, and the *reason* is in the file's comments and in this
    document.
- **No global workarounds without a tracked script and documentation.** If a
  fix has to be applied outside `$HOME`/the repo — a system file, a Homebrew
  formula's own files, a keg, a LaunchAgent plist, an `/etc` path — it needs
  (a) a script in this repo that applies it, idempotently, and (b) prose
  documenting what it patches, why, and how to verify it. Both, not either.
  "I edited it once on the machine" is never acceptable, and neither is
  "here is the script" without the prose.
- **Verification must be reproducible from the repo.** Any claim that a
  tweak is in place must be checkable by running something in this repo (a
  check script, a config load, a command whose output proves it) — not by
  the agent's memory of what it did earlier in the session.
- The same applies to **rollbacks**: a fix that was reverted needs the
  revert recorded too (in git history, and in the doc if the state is
  subtle), so the repo never claims a state the machine no longer has.
- Corollary for agents: **if you cannot express the change as a tracked
  artifact, you have not finished the change.** Say so, and say what is
  missing, instead of leaving the machine in a state the repo does not
  describe.

## 1. Runtime tooling policy (brew vs asdf)

- This is an **Intel x86_64 macOS** machine — Homebrew is Tier 3: **no
  bottles, every formula upgrade compiles from source**. Small CLI tools are
  fine (seconds to a few minutes); big runtimes are not.
- **Runtimes (nodejs, bun, python) are owned by asdf, never brewed.**
  **rust is owned by rust-lang's standalone installer** (not asdf, not brew):
  installed into brew's `rust` keg as 1.99.1 - self-contained, no Homebrew
  llvm needed. See the brew doc for the procedure.
  `~/.tool-versions` is the source of truth (asdf 0.20: `asdf set -u <tool>
  <version>` — there is no `asdf global` in 0.20). Resolution order: nearest
  `.tool-versions` walking up beats `~/.tool-versions`, `ASDF_<TOOL>_VERSION`
  beats both, and several versions on one line are ordered **fallbacks**
  (first installed wins), not alternatives. A pin to a version that is not
  installed (`asdf current <tool>` shows `false`) makes every shim of that
  tool fail with "No version is set for command <name>" — delete the dead pin
  instead of trying to build it (Python 2.7 cannot build on macOS 15+).
  Upgrade path: `asdf install <tool> <ver>` (nodejs downloads official
  prebuilt binaries; python compiles — check `asdf list <tool>` first, the
  version may already exist) → `asdf set -u` → `asdf reshim <tool>`.
  Current split (2026-10-21): interactive pins in `~/.tool-versions` are
  nodejs 22.23.0 / bun 1.4.2; brew's kegs point at the newest asdf installs
  (node 26.12.0, bun 1.4.3) so brew dependents need no source build.
- Brew kegs for runtimes are **symlinks into `~/.asdf/installs/...`** with a
  copied `INSTALL_RECEIPT.json` whose `source.versions.stable` matches the
  keg name string exactly (revision suffix included). Full procedure and
  traps: `docs/brew-intel-symlink-workaround.md`.
- **neovim is the nightly, symlinked into brew — never compiled.** The keg
  `/usr/local/Cellar/neovim/0.12.6` is a symlink to
  `~/.local/opt/nvim-nightly` (the tarball from
  `github.com/neovim/neovim/releases/tag/nightly`); brew still reports the
  **last stable** version because the keg directory name, the receipt's
  `source.versions.stable` and the formula's stable must be the same string.
  Refresh: `packages/nvim/update-nightly.sh` (idempotent; keeps the receipt,
  re-wires `/usr/local/opt/neovim`, `/usr/local/bin/nvim`,
  `/usr/local/lib/nvim` — the last one matters, upstream builds the nightly
  with prefix `/usr/local`, so nvim loads its tree-sitter parsers from
  there). `brew pin neovim` keeps `brew upgrade` from replacing the symlink
  with a build. `brew info neovim` fails with "linked/neovim is not inside a
  keg" — same wart as node, harmless.
- **Never run `brew cleanup`, and never let brew run one for you.** Homebrew
  cleans up automatically after every install/upgrade (`==> Cleanup`), which
  deletes superseded kegs. That is how neovim's binary disappeared on
  2026-11-05: its keg was a dependency install (`installed_on_request:
  false`), got renamed `0.12.6_old` when a newer version arrived, and the
  automatic cleanup deleted it — nobody uninstalled anything.
  `HOMEBREW_NO_INSTALL_CLEANUP=1` in `packages/sh/zshrc-darwin` disables the
  automatic one. Install formulae as requested ones and keep them as
  top-level `Brewfile` entries so brew's bookkeeping knows they are wanted.
- **Revision bumps (`x.y.z` → `x.y.z_1`) are swaps, never builds.** The
  source is identical; only the packaging revision changed. Rename the keg
  (or its symlink), rewrite the receipt's `source.versions.stable`, repoint
  `/usr/local/opt/<formula>`, and repoint the `/usr/local/bin` links. Done
  for node (26.12.0), bun (1.4.3) and python@3.14 (3.14.8_3). llvm@21
  (21.1.8_1) was a real build too, but a failed install's rollback deleted
  it on 2026-10-23 — hence llvm's new home in `.llvm-builds` (below).
- **llvm is compiled once and NEVER deleted.** Homebrew ships no Intel
  bottle and upstream publishes no macOS x86_64 prebuilt for 23.x, so
  `brew install llvm` compiles from source (23.1.4 took 54 min). The real
  build is parked **outside the Cellar**, in
  `~/.local/opt/llvm-builds/<version>`; brew's keg entry
  `/usr/local/Cellar/llvm/<version>` is only a **symlink** to it, and
  `/usr/local/lib/libLLVM-<major>.dylib` points at the current build.
  `brew cleanup` may remove the keg symlink (fine) but cannot touch the
  build: it is not a keg. **Never delete a build under
  `~/.local/opt/llvm-builds/`, and never keep a build as a real directory
  in `Cellar/llvm/<version>`** — that is exactly what a failed install's
  rollback does: on 2026-10-23 it deleted llvm@21's real 21.1.8_1 build and
  left a dangling symlink that made brew fail with
  `Errno::EEXIST: File exists @ dir_s_mkdir - /usr/local/Cellar/llvm/23.1.4`.
  **Never park a build inside `Cellar/`** — not even in a dot-directory:
  brew enumerates every directory under `Cellar/` as a *formula name*, so
  `Cellar/.llvm-builds` broke the crystal upgrade with
  `Error: crystal: No available formula with the name '.llvm-builds'`.
  Verify with `packages/llvm/check-llvm-keg.sh` (checks every build is
  intact, restores a missing keg symlink and the `libLLVM-<major>.dylib`
  link; exit 0 = safe) — run it after any brew operation that touched
  llvm, and before assuming "llvm is missing".
  Bumping: `brew install llvm` then `packages/llvm/park-llvm.sh` (parks the
  new build and re-points the symlinks; **the previous build and its
  `Cellar/llvm/<old-version>` symlink stay**, so anything needing that exact
  version keeps resolving). Procedure: `docs/brew-intel-symlink-workaround.md`.
- **crystal's bootstrap link needs `libLLVM-<major>.dylib` in
  `/usr/local/lib`.** crystal's build links the compiler with
  `-lLLVM-23` but the `-L` to llvm's lib dir does not survive the build
  (`ld: library 'LLVM-23' not found`), while `/usr/local/lib` *is* in the
  link's search list. Hence `/usr/local/lib/libLLVM-23.dylib` →
  `~/.local/opt/llvm-builds/23.1.4/lib/libLLVM-23.dylib` (the check script
  maintains it). Note `/usr/local/lib/libLLVM.dylib` is rust's own bundled
  LLVM — a different, unversioned file; do not confuse the two.
- Known broken state: `awscli`, `sphinx-doc`, `gobject-introspection` have no
  binary and `meson` tracebacks — their site-packages were deleted by the
  Oct-2026 python-keg swap. Reinstall them (not a python rebuild).
- **Network firewall (2026-10-21):** `proxy.golang.org` (and all mirrors),
  `golang.org`, `crates.io` and `static.crates.io` are UNREACHABLE; only
  `github.com`, release asset CDNs and `registry.npmjs.org` respond. So:
  Go builds that fetch modules (gh) and Rust builds (atuin) cannot be built
  from source here — swap in the official **release binary** instead
  (procedure in the brew doc). Vendored Go builds (lazygit, omp, engram,
  gentle-ai) and npm builds (pi-coding-agent) work fine. (The firewall was
  later lifted for one session, so gh/atuin did get real source builds.)
- **A hollow `llvm` breaks Rust, not just brew's bookkeeping** (2026-10-23: the
  hollow keg is gone — `llvm` is a real build now, see the llvm bullet above
  — but the failure mode is worth keeping). Homebrew's `rustc` links
  `/usr/local/opt/llvm/lib/libLLVM.23.1.dylib`; with a hollow keg (no
  `lib/` at all) `rustc` aborted and every cargo build died at
  `cargo fetch`. llvm@21's libs are NOT a substitute (ABI mismatch:
  `Symbol not found: __ZN4llvm10PGOOptions...`), upstream publishes no
  macOS x86_64 asset for 23.1.x, and llvm has no bottle at all — so the
  only llvm here is a source build (~54 min), and it is kept forever. rust
  itself comes from the **rustup** toolchain
  (`~/.rustup/toolchains/stable-x86_64-apple-darwin`), whose rustc is
  self-contained (`@rpath/libLLVM.dylib`). To let a brew build use it,
  temporarily point the rust keg's `bin/rustc` at the rustup binary
  (backup, symlink, build, restore) — `RUSTC=…` in the environment does NOT
  survive brew's build sandbox.
- **asdf can carry a second version of a tool** (2026-10-21): the repo's
  `packages/asdf/tool-versions` now reads `python 3.14.8 3.15.0`. asdf uses
  the FIRST version as the default and falls back to the others for binaries
  that only exist there — that is how `python3.15` resolves to 3.15.0 while
  `python3` stays 3.14.8, using asdf's own generated shim (no hand-written
  shim needed). brew's `python@3.15` keg points at the same asdf install.
- **asdf's python and brew's framework python disagree on paths:** pip
  installs brew's python modules into `/usr/local/lib/python3.15/site-packages`
  (brew's framework scheme) while the asdf-backed interpreter reads its own
  install's site-packages. Bridge them with a `.pth` in the asdf install's
  site-packages listing both directories (meson, and anything else pip
  installed, needs this).
- Small tools upgrade via brew and **build from source on purpose**
  (direnv ~17s, git ~3min, engram ~1s). Just let them.
- `brew pin` blocks dependent installs — runtimes stay **unpinned** (keg
  names already match stable, so nothing rebuilds).
- engram = `gentleman-programming/tap/engram` (formula+cask share the name —
  use the full tap name). `brew cleanup --purge` does not exist; plain
  `brew cleanup <formula>` removes old kegs.
- "Untrusted tap" warnings for `carakan/local`, `jstkdng/programs` are noise.

## 2. asdf gotchas

- Shims live in `~/.asdf/shims` which is **first on PATH** — they shadow
  `/usr/local/bin`. An orphan shim (plugin removed, shim left) silently
  overrides brew binaries; fix = delete that one shim + `hash -r`.
- After touching versions: `asdf reshim <plugin>`.
- `asdf uninstall` takes ONE version per invocation; loop for multiples.
- Never purge old asdf versions wholesale — legacy projects pin them via
  project-local `.tool-versions` (documented incident in the brew doc).

## 3. Dotfiles conventions

- Layout: `packages/<tool>/<config>` symlinked into `$HOME` (e.g.
  `~/.config/kitty` → `packages/kitty`). Absolute paths
  (`/Users/carakan/.dotfiles/packages/...`) inside configs are the norm.
- **Brewfile discipline**: anything intentionally installed outside brew gets
  a comment in `Brewfile` explaining why — never let `brew bundle` resurrect
  it. Currently: yabai (manual install, see §4).
- LaunchAgents live on the machine only (`~/Library/LaunchAgents`); the
  scripts they call live in the repo. Any LaunchAgent script MUST set its own
  PATH (`/usr/local/bin` first) — launchd provides a bare `/usr/bin:/bin`.
- All work products (docs/scripts) belong in this repo, not scattered in
  `$HOME`.

## 4. yabai / skhd

- yabai is installed **manually** (Christian-SC26 fork release, checksummed)
  to `/usr/local/bin/yabai` — Brewfile documents why brew must not own it.
  Upgrade = download release tar.gz, verify sha256, replace binary,
  `launchctl kickstart -k gui/501/com.asmvik.yabai` (retry once if it exits
  0 — startup lock-race clean-exit).
- **The sudoers rule pins the binary's sha256**, so an upgrade needs a root
  step of its own. `/etc/sudoers.d/yabai` holds
  `carakan ALL=(root) NOPASSWD: sha256:<digest> /usr/local/bin/yabai --load-sa`
  (root-only file, mode 640 — `cat` needs sudo). A new binary has a new
  digest, so `sudo yabai --load-sa` stops matching the rule and asks for a
  password — which is fatal, because `yabairc` runs `--load-sa` at login
  without a TTY: the SA then never loads, no window events fire, and the
  window manager is dead. After replacing the binary: rewrite the digest in
  the rule, then re-run `sudo /usr/local/bin/yabai --load-sa` to install the
  payload the new binary ships (the payload changes between releases —
  v7.1.29 and v7.1.31 changed it without a version bump).
- **Both LaunchAgents are repo-managed** (`packages/yabai/com.asmvik.yabai.plist`,
  `packages/yabai/com.carakan.yabai-session.plist`, symlinked into
  `~/Library/LaunchAgents/` by `install-darwin.yaml`). They were hand-made
  local files until 2026-10-21, which is how yabai ended up not starting at
  login at all. Never edit the copies in `~/Library/LaunchAgents` — edit the
  repo files and re-run `./install`.
- yabai's own log is `~/.local/state/yabai/yabai.err.log` (**not** `/tmp`:
  /tmp is wiped at reboot, which hid the login failures).
- **The scripting addition is loaded, and it is required.** `yabairc` runs
  `sudo /usr/local/bin/yabai --load-sa` at startup and re-arms it on
  `dock_did_restart` (a Dock restart drops the SA that Dock.app carries).
  Without the SA yabai delivers **no** window events at all —
  `window_created` / `window_focused` / `application_*` never fire — so
  `update_border_color.sh` never runs and the border colors stay frozen at
  the values set in `yabairc`. The same SA gates window opacity
  (`normal_window_opacity`) and the mouse handling (`mouse_modifier`,
  `mouse_action1/2`, `mouse_drop_action`). Two hard requirements:
  `/etc/sudoers.d/yabai` must grant NOPASSWD for exactly
  `/usr/local/bin/yabai --load-sa` (sudo cannot prompt without a TTY, and
  the signal action runs without one), and the SA needs SIP's Filesystem
  Protections **and** Debugging Restrictions disabled — the fork checks
  `CSR_ALLOW_UNRESTRICTED_FS` and `CSR_ALLOW_TASK_FOR_PID` and refuses
  with "System Integrity Protection: Filesystem Protections and Debugging
  Restrictions must be disabled!" otherwise. That is a Recovery-only
  `csrutil disable --no-debugger --no-filesystem` (keep
  `--no-restricted --no-unsigned` too, or the flags already off get reset).
  The SA's socket is `/tmp/yabai-sa_<user>.socket` (named after the user
  name, not the uid — `/tmp/yabai-sa_carakan.socket`); if it is missing, the SA
  is dead.
- `session_restore.sh` is the safety net: after 20 s without a yabai socket
  it re-enables and bootstraps `com.asmvik.yabai` itself, then waits up to
  5 min for the socket. Its exit code 1 means yabai itself never came up.
- Configs: `packages/yabai/yabairc` (9 labeled spaces, app→space rules,
  border-color signal, dock-restart SA reload), `packages/yabai/skhdrc` (all
  global shortcuts).
- **Workspace sessions**: `ctrl+alt-s` saves the full arrangement to
  `~/.local/state/yabai/session.json` (manual, on demand); `ctrl+alt-r`
  re-applies; `com.carakan.yabai-session` LaunchAgent auto-loads it at login
  (`packages/yabai/session_restore.sh` — waits for the post-login window
  count to stabilize, then applies once). Log:
  `~/.local/state/yabai/restore.log`.

## 5. Terminal stack state

- **fzf 0.75.0** (`packages/sh/fzf.zsh`, sourced by the zshrc): the config
  targets **fzf >= 0.75.0** (Homebrew 0.75.0, verified 2026-11-08). What
  0.75.0 actually adds is narrow, and the config uses it deliberately:
  - The new `{change,transform,bg-transform}-info-command` actions. A
    permanent `--info-command` is **not** set: the man page states it
    "runs synchronously and blocks the UI until completion", so it would
    re-introduce a shell spawn per keystroke — the exact stall the bg-
    transform label variants were introduced to remove. Instead it is an
    **opt-in toggle**: `alt-i` switches the info line to
    `<counter> | pos <n>` (FZF_INFO + FZF_POS), `alt-u` restores the plain
    counter (an empty change-info-command resets it). Verified in tmux:
    baseline `3/3 +S` → alt-i `3/3 +S | pos 1` → alt-u `3/3 +S`.
  - Two semantics changes that do **not** affect this config:
    `transform-nth`/`transform-with-nth` no longer split output at the pipe
    character (only the `change-` pair rotates through pipe-separated
    values), and `change-nth`/`change-with-nth` now apply the value AFTER
    the current one and skip values equal to the current one. This config
    uses neither family.
  - The **bg- transform variants** are now used for the two label
    transforms (list label on `result-final`, preview label on `focus`) and
    for the Ctrl-T `focus:+bg-transform-header`. The plain `transform-*`
    actions block the UI while the command runs; these three fire on every
    result change or cursor move, so the synchronous form was a per-move
    stall. The list label is on **`result-final`, not `result`**:
    `result` also fires on every intermediate snapshot while the input
    stream is still loading, so a slow producer spawns the transform dozens
    of times for a label that is overwritten before it is ever displayed.
    Measured with a 50-item **pipe** producer: `result` fired 50 times,
    `result-final` once. (A producer redirected to a *file* shows no
    difference — fzf reads a seekable file in one pass. The pipe is the
    case that matters.) Steady-state behaviour after loading is identical.
  - **Bind commands must be POSIX, not bash.** fzf runs them through
    `$SHELL -c`, so `[[ ... ]]` breaks on a box whose `$SHELL` is dash
    (`[[: not found`, label dies with it). The label transforms use
    `[ ... ]` and quote `$FZF_QUERY` (a multi-word query otherwise splits
    into extra test operands: `[: a: unexpected operator`). Keep new bind
    bodies POSIX. Note fzf substitutes `{}` as a **single-quoted** string
    (`'a b|c'`), so a multi-word item stays one word in `[ -n {} ]`.
  - `alt-u` binds `change-info-command:` with an **empty** value, which
    unsets the info command and restores fzf's native counter with no
    shell spawn. `change-info-command:echo $FZF_INFO` looks equivalent and
    is not: the command stays installed, so fzf keeps spawning a shell to
    produce the counter on every keystroke. Measured by pointing `$SHELL`
    at a logging wrapper: after `alt-u`, the info command ran **0** times
    over 5 keystrokes; with `echo $FZF_INFO` it ran **10** times.
  - **`packages/fzf/check-fzf.sh`** is the tracked verification script
    (AGENTS.md §0b): it checks the installed fzf against the documented
    floor, parses every option set the config ships through fzf itself
    (fzf exits 2 with `unknown option` / `unknown action` /
    `unsupported key` on anything it does not know), confirms the
    0.75-only actions AND events exist, and runs every transform body
    under **both bash and dash**, requiring exit 0 and identical output.
    That last check is what catches a bashism: fzf's own parser accepts
    `[[ ... ]]` happily, so only running the body reveals it. Run the
    script after any fzf upgrade or any edit to a bind body.
  - Quoting trap in this file: `FZF_DEFAULT_OPTS` is a **single-quoted**
    shell string that ends with `.../fzf'"`. Swapping those last two
    characters silently breaks the export (zsh then parses the option
    lines as commands and reports `not valid in this context`), and the
    symptom appears far from the cause. Keep the terminator byte-exact.
- **zsh prompt** (`packages/sh/pk10.zsh`, symlinked to `~/.p10k.zsh`; note the
  filename typo `pk10`): `context` removed 2026-10-21 — the tmux server was
  started over SSH, so panes inherit `SSH_CONNECTION`, p10k takes its remote
  branch and prints `user@host` on every shell. There is **no `gitstatus`
  element** (that was my error, corrected): the element is `vcs`, and gitstatus
  is p10k's async *backend* behind it. The backend only runs if the plugin is
  started **before** `oh-my-zsh.sh` — see the block in `packages/sh/zshrc`.
  Daemon: `~/.cache/gitstatus/gitstatusd-darwin-x86_64`, must match the theme's
  bundled gitstatus version (rebuild:
  `powerlevel10k/gitstatus/build -w`, then copy `usrbin/gitstatusd` over it —
  plain `make` fails against Homebrew libgit2 1.9). Without this the prompt
  silently falls back to p10k's slow synchronous git renderer.
- **kitty 0.49.2** (`packages/kitty/kitty.conf`): scrollbar
  scrolled-or-hovered, `padding_fill_strategy neighboring_cell`,
  and the NATIVE `cursor_trail 3` (decay 0.1 0.25, color #676f7f).
  Custom Slang shader pipelines were tried and REMOVED 2026-10-25 (look not
  worth it; they also replaced the native trail rendering). If revisited:
  the kitty-shaders collection targets git-master API — port member usages
  (`cursor_trail_history_to`/`wrapped_time` don't exist on stable) — and any
  cursor-trail-move pipeline suppresses the native trail. A half-written
  shader cache shows as ENOENT on `m_*_0.slang-module`;
  `rm -rf ~/Library/Caches/kitty/shaders` rebuilds it — moot while no
  `custom_shaders` line is set.
- **tmux**: `packages/tmux/tmux.conf`, symlinked live. Core session/pane/
  copy-mode config + on-demand plugins, plus the agentic helpers
  RE-ENABLED 2026-10-25 with the guards the 10-14 revert called for:
  silence watchdog (prefix M, per-window opt-in) notifies ONLY through
  `bin/tmux-bell-notify` (program bells stay a visual tab marker); the
  long-command finisher arms on client attach but ONLY for RGB (desktop)
  clients — phones never arm the per-second polling.
  **The finisher is dormant on stable tmux 3.8**: `set-hook -B` monitor
  hooks register there but never fire (verified 2026-10-25: the once-a-second
  format expansion never runs, even with a control-mode client attached);
  `bin/tmux-agent-monitors` detects the version and no-ops with a stderr
  note. `brew install --HEAD tmux` (next-3.9+) + server restart activates it
  on the next attach, no config change. The watchdog does not use monitors
  and works on 3.8. `pane-scrollbars` re-enabled 2026-10-27 as `auto-hide`
  (+ right / 2000ms / themed colours) after the 10-25 OFF decision — the
  on/off flip-flop across sessions was itself the "sometimes works" bug;
  the value now lives in tmux.conf, committed. If Termius shows rendering
  corruption while the bar draws, revert is the single `auto-hide` line.
  Back from the revert: `remain-on-exit`,
  prefix X (kill other panes), copy-mode R (refresh-toggle), clear-on-attach
  off — clear-on-attach is now per-client: `off` is the server default
  (desktop kitty, primary screen), and the zshrc SSH attach path flips it to
  `on` for the phone so Termius gets the alternate screen and its own
  scrollbar stops tracking tmux paint frames (see packages/tmux/README.md,
  "Phone (Termius) scrolling"). The 3.8-only lines are gated on the option
  existing so a 3.7 server loads the file without errors. The client-attached
  monitor guard matches `*kitty*` in client_termname — NOT RGB (589b896's
  RGB guard matched every client; the wildcard grants RGB to all, and the
  live Termius client verifiably attaches with RGB). **FROZEN 2026-11-10,
  user-confirmed working: never modify the zshrc clear-on-attach scoping or
  the client-attached guard again without an explicit request — breaking
  them re-creates the phone "ascii garbage" bug.** Config changes apply on
  `tmux source-file`; server restart only when server-scoped options change.
- **mosh: evaluated and rolled back (2026-10-13) — do not retry with Termius.**
  Termius's mosh client sends no terminal type in-band and mosh-server then
  clamps its color budget to 8 (monochrome) and Termius's repaint model loses
  scrollback. Server-side fixes (PATH via zshenv, TERM wrapper, zshrc repair,
  `env TERM=… -c 256` command) cannot beat a broken client. **Termius: use
  plain SSH** — colors and scrollback work. Full post-mortem in git history
  (`docs/mosh.md` was removed in the rollback commit). The infra fixes from
  that hunt stay: `~/.zshenv` exec-channel PATH and `~/.zprofile` login-env
  links (below).
- `packages/sh/zshenv` → `~/.zshenv`: the ONLY file sshd exec channels
  (`zsh -c`) source. Puts `/usr/local/bin` + `~/.local/bin` on PATH for ssh
  one-liners and any remote-spawned tool. Non-negotiable.
- `packages/sh/profile` → `~/.profile` AND `~/.zprofile`: shared env; zsh
  *login* shells (incl. every sshd login) read `.zprofile`, never
  `.profile`.
- **Mobile (Termius)**: plain SSH. Auto-attach is back (2026-10-25) but
  SSH-ONLY: the zshrc takeover block (`attach -d` onto `$TMUX_AUTO_SESSION`,
  default `main`) runs only when `SSH_CONNECTION` is set — desk↔phone swap
  semantics — and never for local shells. Since 2026-11-10 the same block
  also sets `clear-on-attach on` just before attaching, so the phone gets
  the alternate screen (Termius's client-side scrollbar stops tracking tmux
  paint frames; swipes reach tmux copy-mode history). Local shells reset the
  option to `off` before the omz plugin attaches, so kitty keeps the primary
  screen. The 10-14 regression was `-d`
  firing on every local kitty window, stealing the session from the previous
  one; local shells now go through the omz tmux plugin (attach without -d)
  as before. Opt out per connection with `TMUX_AUTO_ATTACH_OFF=1` — it also
  silences the omz plugin fallback, so an opted-out ssh shell never falls
  through to a mirrored attach. Detach (prefix+d) on the phone ends the ssh
  session by design.
- Mobile client (Termius): ANSI half-block art only — no pixel/graphics
  protocols. `bin/clipcopy` is the tmux↔system clipboard sink.

## 5b. nvim-scrollbar: v2

Migrated to **v2** on 2026-10-22 (v2 replaces v1 on `main` on **2026-11-16**,
petertriho/nvim-scrollbar#121). v2 rejects v1 option names outright, so both
setup blocks were rewritten: `lua/plugins/scrollbar.lua` (the live one, wired
by `plugins.lua`'s `safe('scrollbar')`) and the dormant copy in
`legacy-lua-extracted.lua` (nothing `dofile()`s it — kept in sync so it cannot
become a trap).

| v1 | v2 |
|---|---|
| `handlers` | top-level `providers` (`cursor`/`diagnostic`/`search` default on) |
| `handle` | `scrollbar.thumb`; `color` → `highlight.bg` |
| `marks.<T>.color` | `marks.<T>.highlight.fg` |
| `folds = 1000` | `scrollbar.unit = "screenline"` (v2 has no line limit) |
| `show`, `show_in_active_only`, `max_lines` | inside the `scrollbar` block |
| `Scrollbar<Type>Handle` groups | `Scrollbar<Type>Thumb` (v2 still creates the old names as aliases) |

Top level now accepts only `set_highlights`, `exclude`, `providers`, `marks`,
`scrollbar`, `minimap`. Search marks are native in v2 (nvim-hlslens no longer
needed for them; hlslens stays for its own lens).

Until 2026-11-16 the v2 code is on branch `refactor/v2`, pinned via dein in
`packages/vim/vimrc.bundles.local` (`#{ rev: 'refactor/v2' }` — dein's key is
`rev`, not `branch`) and `nvim-pack-lock.json`. After that date `main` carries
v2 and the `rev` line can be dropped. Plain `make` in the dein checkout fails
against Homebrew libgit2; switch branches with git and re-sync dein's flat
cache with `rsync -a --exclude '.git' <repo>/ ~/.vim/bundle/.cache/init.vim/.dein/`
(**no** `--delete`: that cache merges every plugin's files).

Do not remove this plugin for "tmux/neovim already do it": this nvim build has
**no `+scrollbar` option** (`exists('+scrollbar')` = 0, `options.txt` has zero
mentions) and the tmux config draws no scroll indicator. It is the only
scrollbar.

- **supra-vim's OmniComplete snippet is broken — `packages/vim/vimrc.local`
  replaces it.** The snippet in `~/.supra-vim/.vimrc` (~line 339) writes the
  autocmd across several lines with `\` continuations, so Vim parses the
  *pattern* as `*if` (the `if` gets swallowed by the pattern) and the command
  as a bare `setlocal omnifunc=syntaxcomplete#Complete`. It then fires in
  buffers that are not modifiable and raises
  `E21: Cannot make changes, 'modifiable' is off`. `vimrc.local` clears it
  (`augroup END` + `autocmd! FileType *if`) and installs a single-line
  version that also checks `&modifiable`. Keep that override whenever
  supra-vim is re-bootstrapped; the same trick applies to any multi-line
  `:autocmd` with `\` continuations — write it on one line.

## 6. Recipes

### Update a small CLI tool
`brew update && brew upgrade --formula <tool>` — source build expected;
verify with `brew list --versions` + run the binary.

### Update node/python
asdf path (§1). Never `brew upgrade` them. If a brew keg symlink needs to
track the new version, follow `docs/brew-intel-symlink-workaround.md`.

### Update llvm
`brew install llvm` (compiles from source, ~54 min) → `packages/llvm/park-llvm.sh`
→ `packages/llvm/check-llvm-keg.sh`. The old build is **never** deleted: it
stays in `Cellar/.llvm-builds/<version>` with its `Cellar/llvm/<version>`
symlink intact, so anything pinned to that exact version keeps working. If
the check ever fails, do not let brew rebuild llvm — repair the symlink (the
check does that) or re-point it at an older preserved build.

### App "damaged / can't be opened"
`xattr <app>` → quarantine present? `xattr -dr com.apple.quarantine <app>`
then `codesign -vv --deep`. Quarantined AND unsigned binaries get SIGKILLed
(exit 137, no output) — adhoc-sign with `codesign --force --sign - <bin>`.
If the seal is broken by *injected files* (extra dylibs, patched frameworks),
the app is tampered — report that; do not re-sign, offer the official
installer instead.

### New LaunchAgent script
Script goes in the relevant `packages/<tool>/`, plist in
`~/Library/LaunchAgents`, PATH set inside the script, log to a stable file,
then `launchctl bootstrap gui/501 <plist>`.

## 7. Platform scope (read before porting this repo)

This is the **Intel macOS** configuration, but the configs are cross-platform:
the machine-specific parts are isolated and **inert on other platforms**.

| Piece | Where | Scope |
|---|---|---|
| `install-darwin.yaml` / `install-linux.yaml` | repo root | chosen by `./install` via `uname -s` ✓ |
| `packages/llvm/*.sh` (the `.llvm-builds` scheme) | `packages/llvm/` | **Intel macOS only** — the scripts check `uname -s`/`uname -m` and exit 0 everywhere else ✓ |
| `packages/yabai/`, `packages/karabiner/`, `packages/macos/`, `packages/iterm/` | `packages/` | macOS-only ✓ |
| `bin/ubuntu_clean_rocm.sh` | `bin/` | Linux-only ✓ |
| asdf ↔ brew symlink pattern (node/bun/python) | `docs/brew-intel-symlink-workaround.md` | needed because Intel brew has no bottles; on Apple Silicon brew installs bottles, on Linux the distro package manager does it ✓ |
| the compiled-and-parked llvm (§1) | `Cellar/.llvm-builds/` | Intel-only: no bottles on Tier 3 and no upstream x86_64 prebuilt for 23.x, so llvm has to be compiled here ✓ |

Rules when adding anything machine-specific:

- **Never hardcode `/usr/local` or `x86_64`** — read the prefix from
  `brew --prefix` (`/usr/local` on Intel, `/opt/homebrew` on Apple Silicon)
  and gate on `uname -s` / `uname -m`.
- Put the guard **in the script that needs it** (as `packages/llvm/*.sh` does)
  so the same file is safe on every platform, and make "not applicable" exit
  **0** — a machine without the hack must not report a failure.
- Keep platform-specific config in `packages/<tool>/` or the
  `install-<os>.yaml` files, never in a shared config.

Verified 2026-10-23: `packages/llvm/check-llvm-keg.sh` and `park-llvm.sh`
exit 0 with a clear "not applicable" message when `uname` reports Linux or
arm64, and the rest of the repo contains no other Intel-only assumptions
(`pk10.zsh` mentions "brew" only in perlbrew comments; yabai's
`session_restore.sh` already puts both brew prefixes on PATH).

## tmux workstation gotchas (2026-10-27)
- The automation shell on this Mac can inherit `TMUX=/usr/local/bin/tmux`
  (path, not a socket spec). Every tmux client call then tries to use the
  binary as a socket and fails with "error connecting to /usr/local/bin/tmux
  (Socket operation on non-socket)" — the error names the SOCKET PATH it
  tried, not the binary. Prefix tmux calls with `env -u TMUX` there.
- The tmux server died ~2026-10-27 14:00 (during config-revert experiments);
  stale socket + two zombie `tmux attach` clients lingered. Server was
  rebuilt from the repo config; window names/panes restored by the existing
  attach hooks. Socket default path: /tmp/tmux-501/default.
