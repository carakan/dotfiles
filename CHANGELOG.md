# CHANGELOG — implementation record

What changed on this machine, why, and *how the fix works*. `AGENTS.md` holds
the standing rules an agent must follow; this file holds the history and the
implementation specs behind those rules — the mechanism, the evidence, and
the traps that cost a session to find.

Conventions: newest first, grouped by date, one `###` per subsystem. Each
entry says what changed, why, and how to verify it. Facts that are still
load-bearing as *rules* live in `AGENTS.md`; everything about how the state
was reached lives here.

---

## 2026-11-22

### yabai 7.3.3 → 7.3.5

- **Release check.** Christian-SC26 fork, universal binary (x86_64 + arm64),
  Developer ID `Polina Haritonova (DVJTWMLL8X)`, notarized. Tarball sha256
  `3b47ef35e8cf5fe6841b62e0ffc191032dbe74d6487333e820965726ce69f85d`
  (matches the published `.sha256`); the binary inside is
  `f25c6b50a9a71736403bf0051b2f23e70ff36ecfcfee92193fb5f5cd98d94927`, which
  also matches the digest GitHub reports for the bare `yabai` asset — a
  second, independent check that the tarball was not repacked.
- **Scripting addition 2.1.38 → 2.1.39** (bumped in 7.3.4, unchanged in
  7.3.5). One `--load-sa` is therefore required when coming from 7.3.3.
  `yabairc` performs it on start, so "restart the agent" is the whole
  procedure once the sudoers digest matches.
- **`KeepAlive` changed from `{Crashed: true}` to `true`.** yabai can lose
  the startup lock race at login and exit **0**; `{Crashed}` only restarts
  abnormal exits, so the window manager stayed dead until a manual
  `kickstart`. `ThrottleInterval 5` still bounds a crash loop.
- **`yabairc` space handling made idempotent.** Evidence from
  `~/.local/state/yabai/yabai.err.log` (cumulative): 768 ×
  `acting space is already located on the given display.`, 93 ×
  `could not locate the space to act on!`, 8 ×
  `cannot send space to display because mission-control is active.` — about
  nine lines per login, all from the unconditional `space N --label` and
  `space --display` calls. `space N --display X` exits **1** even when the
  space is already there, so this was not just noise: a failing setup step was
  indistinguishable from a correct one.
  - `space_label <index> <label>` skips indexes past the real space count
    (this machine has 8 spaces; the config labels 9).
  - `space_to_display <label> <display>` queries `.display` first and skips
    displays that do not exist, so the 2-display layout stays quiet when the
    laptop is undocked.
  - Verified by running the real `yabairc` against the live daemon: exit 0,
    `yabai configuration loaded..`, and **zero** new lines in
    `yabai.err.log`.
- **Login Items record refreshed.** The daemon bundle's `CFBundleVersion`
  went 7.3.3 → 7.3.5, so the agent symlink was replaced (`rm` + `ln -s`) and
  the job re-bootstrapped — BTM caches the record keyed on directory events
  in `~/Library/LaunchAgents`, and `kickstart` alone re-runs the *loaded*
  definition without re-reading the plist.
- **Root step (digest pin).** The sudoers rule pins the binary digest, so the
  new binary stops matching:

  ```sh
  sudo sh -c 'printf "carakan ALL=(root) NOPASSWD: sha256:f25c6b50a9a71736403bf0051b2f23e70ff36ecfcfee92193fb5f5cd98d94927 /usr/local/bin/yabai --load-sa\n" > /etc/sudoers.d/yabai && chmod 640 /etc/sudoers.d/yabai'
  launchctl bootout gui/501/com.asmvik.yabai
  launchctl bootstrap gui/501 ~/Library/LaunchAgents/com.asmvik.yabai.plist
  ```

  Proof the pin is real: `sudo -n /usr/local/bin/yabai --load-sa` answers
  `sudo: a password is required` after swapping the binary while the old rule
  is still in place. Rollback binaries stay at
  `~/.local/state/yabai/yabai-v7.3.3.bak` and `yabai-v7.3.1.bak`.

### Terminal font: Maple Mono NF → NFM → NFMT

- **Packaging line.** `MapleMono-NF-*` (installed, Version 8.004 =
  v8.0-beta.4) → `MapleMono-NFM-*` (icons normalised to the 600/1000 em
  advance) → `MapleMono-NFMT-*` (same, stretched vertically to cap height).
  All three families remain installed; `kitty.conf` points at NFMT.
- **Why NF was wrong, measured.** In the NF build icon ink is 1.4–1.9× the
  600-unit cell (U+F121 code 1154×924, U+E62B vim 873×816), while the config
  also carried
  `symbol_map U+e000-…,U+f0001-U+f1af0 Maple Mono NF Regular`. Consequences:
  1. every icon came from the **Regular** face, heavier than the Light text;
  2. because a symbol_map face is a non-primary face, `kitty/fonts.c`
     computes `desired_cells = ceil(ink_width / cell_width)` from the ink,
     so 90 % of icons (9495 of 10504 measure wider than a cell) were drawn
     as **2-cell** runs when a space followed, and as 1-cell runs otherwise;
  3. the old `narrow_symbols` list capped only 2,099 of 10,505 codepoints,
     so the cap was applied to a minority — the visible symptom was two icon
     sizes.
- **Fix, three parts.**
  - NFM: every Nerd Font glyph has a 600-unit advance, i.e. exactly one cell
    (verified: 10,505 PUA codepoints, one advance value).
  - `symbol_map` removed: the primary face already covers every NF codepoint
    (10,505 vs SymbolsNerdFont's 10,071 — a superset), so `font_for_cell`
    never falls back and icons inherit the text weight.
  - `narrow_symbols U+E000-U+F8FF,U+F0000-U+FFFFD 1` (plus the four
    non-PUA dingbats): belt-and-braces for the bold/italic path, which is the
    only one that can widen a PUA glyph (`font_idx > 0`).
- **NFMT (icon size).** kitty only ever constrains glyph *width*
  (`render_bitmap`: crop up to 2/10 cell, else rescale); height is bounded
  only by the line box. NFM normalises icons to the advance, which leaves
  them at ~80 % of the 730-unit cap height. `packages/fonts/nfmt-icon-scale.py`
  flattens each icon outline and stretches it in Y (factor 1.22, per-glyph
  clamped to the line box, powerline glyphs ≥900 units skipped) and renames
  the family. Text glyphs, advances, cmap and GSUB are byte-identical.
  Measured at font-size 64: vim 37 → 44 px, code 32 → 38, material 39 → 48;
  widths unchanged at 39. Re-derive with
  `python3 packages/fonts/nfmt-icon-scale.py ~/Library/Fonts ~/Library/Fonts 1.35`.
- **`docs/kitty-font-features.svg`** — rendered comparison sheet for the
  feature set below (generated with harfbuzz, `currentColor` only).

### kitty `font_features`

- Set for all four faces (`MapleMono-NFMT-{Light,Bold,LightItalic,BoldItalic}`
  — kitty indexes `font_features` by **PostScript name**, verified against
  name ID 6): `+calt +zero +cv01 +cv02 +cv03 +cv04 +cv10 +cv64 +cv67 +ss04 +ss05`.
- **`+onum` removed.** v8 ships `numr/ordn/sups/subs/frac/dnom` and no
  `onum`; `hb-shape` output is identical with and without it. The feature was
  carried over from a Cascadia block and had never done anything.
- **Additions and why.** `ss04` stops `__` merging into one underline
  (Python dunders); `ss05` drops the thin escaped backslash; `cv67` a taller
  `|`; `cv10` barred `z`/`Z`; `cv64` keeps `<=`/`>=` with a flat bottom bar.
- **Conflicts, verified by shaping not by docs.** `cv64` overrides `ss02`
  (`+ss02,+cv64` still shapes `less_equal.liga.cv64`), so the two are never
  enabled together; `cv69` is literally the `@` half of `cv01`
  (both shape `at.cv01`); `cv66` is a no-op in this build; `cv63` shares a
  glyph with `cv64`; `cv68` fights `ss01`.
- **Italic-only variants.** `cv31`–`cv46` fire only on
  `MapleMono-NFMT-LightItalic` (verified per codepoint: italic DIFF, upright
  same). Left disabled.

### delta 0.21.2 / lazygit 0.66.3

- **Two latent config bugs.**
  - `diffRenderers[1]` ran `delta --features=lazygit-theme`; no such feature
    exists and delta ignores unknown features **silently**, so the
    side-by-side renderer was drawing with delta's default colours. Fixed to
    `lazygit-carakan`.
  - `branchLogCmd` used `%C(##FEF9E1)`; `git log --graph` died with
    `error: invalid color value: ##FEF9E1` → `fatal: unable to parse
    --pretty format`, i.e. the branches panel log view was empty. Fixed to
    `%C(#FEF9E1)`.
- **Renderer commands** (lazygit 0.66 template variables, resolved by
  `pkg/config/diff_renderer_config_manager.go` which registers each variable
  both as a map key and as a zero-arg func):
  `--{{colorScheme}}` → `--dark`/`--light`, and
  `{{if gt .width 140}}--side-by-side{{end}}` so SBS degrades to unified in a
  narrow pane (delta cannot measure the pane through lazygit's pager; 0.20
  can read `$COLUMNS` but lazygit does not set it).
- **`git.diffContextSize: 1`** to match `[diff] context = 1` in
  `~/.gitconfig`; the lazygit default of 3 made `{`/`}` jump.
- **`[delta] hyperlinks = true`.** Delta emits absolute `file:///Users/…`
  targets and github.com commit links (origin is `carakan/dotfiles`); tmux
  already grants `hyperlinks` in `terminal-features`.
- **Theme `lazygit-carakan` completed** (all values from the existing
  palette): `hunk-label` = U+F105 (NF angle-right; feeds `navigate-regex`,
  which regenerated to include it), `hunk-header-style … file line-number`
  (activates `hunk-header-file-style` and `hunk-header-line-number-style`,
  both previously dead), `blame-timestamp-output-format = %Y-%m-%d`,
  `blame-separator-style = #414036`, `blame-code-style = syntax`,
  `inline-hint-style = #63696d italic`, merge-conflict ours/theirs
  style + decoration in `#4a7ebe` / `#d26681`. Removed
  `hunk-header-active-border-color`, which is not a delta option.
- **Blame trap.** `blame-*timestamp-format*` is the **input** format: delta
  parses git's timestamp with it (`handlers/blame.rs`), so shortening it
  makes delta stop recognising blame output and pass raw text through. The
  output knob is `blame-timestamp-output-format`. Before the fix a 25-char
  timestamp overflowed `{timestamp:^13}` and dragged the separator right.
- **`blame-separator-style` accepts no `box`** — `box` exists only on
  `*-decoration-style`; delta aborts with
  `Invalid color or style attribute: box`.
- **Vendored themes refreshed** to the 0.21.2 `themes.gitconfig` (new
  `colibri-colorblind`, rewritten `colibri`, `line-numbers-*-style = line`),
  with the local `lazygit-carakan` block preserved verbatim.

---

## 2026-11-20

### zsh autosuggestions (deja) vs zsh-patina ordering

Both wrap the same ZLE widgets and the last wrapper draws last. patina
repaints the whole line to apply syntax colours, so patina loaded after deja
erases the ghost text and the suggestions never appear. `packages/sh/zshrc`
sources deja **after** zsh-patina, explicitly — it is deliberately not an omz
plugin, because omz sources every plugin before the patina activation and the
order cannot be expressed in the plugin list.

Verified: `zsh -f` + deja shows the ghost; adding patina removes it;
reversing the order brings it back. `deja fuzzy` / `deja empty` persist
`fuzzy` / `empty_suggestions` in `~/.local/share/deja/config`
(`fuzzy=tight`, `empty_suggestions=off`); `~/.local/share/deja/init.zsh` is
written and refreshed by the binary itself.

### fzf: `--border` and `--popup` are mutually fatal

fzf 0.75 parses either alone, but with both set it exits immediately and
draws nothing — every picker (Ctrl-T, Ctrl-R, Alt-C, the tmux-fzf plugin's)
died silently because they all inherit `FZF_DEFAULT_OPTS`. `--popup` was
dropped: it selects the 0.74 non-modal floating pane, which unzooms a zoomed
window on tmux 3.7. What remains is the classic modal picker with the rounded
border and labels, correct on every tmux. The per-option-set parse check in
`packages/fzf/check-fzf.sh` cannot see this class of bug — each set parses on
its own — so the rule is recorded, not just tested.

---

## 2026-11-19

### kitty remote control over a per-instance unix socket

`allow_remote_control socket-only` + `listen_on unix:kitty-{kitty_pid}` — one unix socket per instance in
`$TMPDIR/kitty-<pid>`, so a second instance cannot steal the first one's path
(a fixed name logs `Invalid listen_on, ignoring`). `socket-only` accepts
socket requests and denies TTY requests, so a program running inside the
terminal cannot drive kitty. kitty exports the path as
`KITTY_LISTEN_ON` and `packages/tmux/tmux.conf` forwards it through
`update-environment`, so `kitty @ ls` and `kitty @ get-text --extent=screen`
work inside tmux panes. `listen_on` is **not reloadable** — it applies on the
next kitty start (tmux sessions survive the restart). Traps: `kitty @ launch`
runs the zshrc and the omz tmux plugin then steals the session from the
current window, so launch task windows with an explicit command
(`kitty @ launch --type=window -- <cmd>`).

### tmux long-command finisher moved from monitors to shell hooks

The tmux monitor path is dormant on stable tmux 3.8: `set-hook -B` monitor
hooks register but never fire, and the once-a-second format expansion never
runs even with a control-mode client attached (verified 2026-10-25).
`bin/tmux-agent-monitors` detects the version and no-ops with a stderr note.

Primary path is now shell-driven: `preexec` in `packages/sh/zshrc` records
`@busy-since-<pane>` / `@busy-cmd-<pane>`, `precmd` hands the run to
`bin/tmux-agent-notify` when it exceeded `@agentic-notify-secs` (default 30).
Event driven, version independent, no polling. `bin/tmux-agent-notify` is the
single notifier for both paths: it reports only while the pane state is still
pending and clears that state when it reports, so the two paths cannot
announce the same run twice and the sweep no longer reports a still-running
pane as finished. The monitor path stays as the backstop for panes that go
idle without a shell hook and needs tmux HEAD
(`brew install --HEAD tmux`, next-3.9+).

---

## 2026-11-16

### nvim-scrollbar v1 → v2

v2 replaces v1 on `main` (petertriho/nvim-scrollbar#121) and rejects v1
option names outright. Both setup blocks were rewritten:
`lua/plugins/scrollbar.lua` (live, wired by `plugins.lua`'s
`safe('scrollbar')`) and the dormant copy in `legacy-lua-extracted.lua`
(nothing `dofile()`s it — kept in sync so it cannot become a trap).

| v1 | v2 |
|---|---|
| `handlers` | top-level `providers` (`cursor`/`diagnostic`/`search` default on) |
| `handle` | `scrollbar.thumb`; `color` → `highlight.bg` |
| `marks.<T>.color` | `marks.<T>.highlight.fg` |
| `folds = 1000` | `scrollbar.unit = "screenline"` (v2 has no line limit) |
| `show`, `show_in_active_only`, `max_lines` | inside the `scrollbar` block |
| `Scrollbar<Type>Handle` groups | `Scrollbar<Type>Thumb` (old names kept as aliases) |

Top level accepts only `set_highlights`, `exclude`, `providers`, `marks`,
`scrollbar`, `minimap`. Search marks are native in v2; nvim-hlslens stays
only for its own lens. Before 2026-11-16 the v2 code was on branch
`refactor/v2`, pinned via dein in `packages/vim/vimrc.bundles.local`
(`#{ rev: 'refactor/v2' }` — dein's key is `rev`, not `branch`) and
`nvim-pack-lock.json`; after that date the pin can be dropped. Plain `make`
in the dein checkout fails against Homebrew libgit2: switch branches with git
and re-sync dein's flat cache with
`rsync -a --exclude '.git' <repo>/ ~/.vim/bundle/.cache/init.vim/.dein/`
(**no** `--delete` — that cache merges every plugin's files).

---

## 2026-11-11

### vim-rooter: drop `package.json` as a root marker

Root detection is breadth-first, so the **nearest** ancestor wins. In a
monorepo/worktree (`~/development/nodejs/trm/old-changes`) the nested
`package.json` of `trm/old-changes/api` became the root, rooter `cd`'d there,
and the session's relative buffer paths compounded into `api/api/api/…` on
every save. `g:rooter_patterns` is now
`['.git','_darcs','.hg','.bzr','.svn','Makefile']`; `.git` matches a gitfile,
so worktrees still resolve to the worktree root. Also fixed
`g:rooter_silent_changetocwd` → `g:rooter_silent_chdir`.
`g:rooter_manual_only = 1` plus explicit once-only `Rooter` calls must stay
together — removing them reintroduces automatic project switching.

### p10k: fish-style path abbreviation

`POWERLEVEL9K_DIR_MAX_LENGTH=0` abbreviates every component to its shortest
unique prefix (`~/.dotfiles/p/sh`), last component full; the wizard default
was `80` (shorten only past 80 columns). p10k's `truncate_to_unique`
strategy *is* the fish algorithm, so no OMZ plugin is needed — upstream omz
dropped `plugins/omz`, and rendering `shrink-path` output through a custom
segment would lose the dir block, the git-root anchor and the 🔒 icon.

### yabai 7.3.1 → 7.3.3

Scripting-addition payload 2.1.38; digest pinned
`b2a70005031d50e42582a0f472dbda3504623e5c652e2fcacc080155ee9c63ee`.
Fixed: debugger-hosted apps could not be reached across spaces; stack
overflow past 32 windows (the 33rd window was written past the node's window
list, over the split ratio and insert state); insert feedback tied to the
wrong window; `rule --remove` reordering rules; clients that stop talking to
the daemon blocking all window management (now 1 s + length bounds);
event-queue wraparound; display-return layout loss; multi-message window
lists to the Dock.

---

## 2026-11-10

### tmux phone scoping frozen by user request

The zshrc takeover block attaches only when `SSH_CONNECTION` is set and sets
`clear-on-attach on` just before attaching, so Termius gets the alternate
screen and its own scrollbar stops tracking tmux paint frames. Local shells
reset the option to `off` before omz's plugin attaches, so kitty keeps the
primary screen. `TMUX_AUTO_ATTACH_OFF=1` opts a connection out entirely.

The client-attached monitor guard matches `*kitty*` in `client_termname` —
**not** RGB: 589b896's RGB guard matched every client, because the wildcard
in `terminal-features` grants RGB to all, and the live Termius client
verifiably attaches with RGB.

**Frozen**: do not change the clear-on-attach scoping or the client-attached
guard without an explicit request — breaking them re-creates the phone
"ascii garbage" bug.

---

## 2026-11-08

### fzf 0.75.0 config

The floor is 0.75.0 (Homebrew, verified 2026-11-08). What the config uses
from it:

- `{change,transform,bg-transform}-info-command`. A permanent
  `--info-command` is **not** set — it "runs synchronously and blocks the UI
  until completion", a shell spawn per keystroke. Instead `alt-i` switches
  the info line to `<counter> | pos <n>` (`FZF_INFO` + `FZF_POS`), `alt-u`
  restores the plain counter. Verified in tmux: baseline `3/3 +S` →
  alt-i `3/3 +S | pos 1` → alt-u `3/3 +S`.
- The `bg-` transform variants for the two label transforms and for Ctrl-T's
  `focus:+bg-transform-header`; the plain `transform-*` actions block the UI.
  The list label is on **`result-final`, not `result`**: `result` fires on
  every intermediate snapshot, so a slow producer spawns the transform dozens
  of times for a label that is overwritten unseen. Measured with a 50-item
  **pipe** producer: `result` fired 50 times, `result-final` once (a producer
  redirected to a file is read in one pass and shows no difference).
- `alt-u` binds `change-info-command:` with an **empty** value, which unsets
  the command; `change-info-command:echo $FZF_INFO` looks equivalent and is
  not — the command stays installed and keeps spawning a shell. Measured with
  a logging `$SHELL` wrapper: 0 spawns over 5 keystrokes after `alt-u`, 10
  with `echo $FZF_INFO`.
- **Bind bodies must be POSIX.** fzf runs them via `$SHELL -c`, so `[[ … ]]`
  breaks on dash (`[[: not found`). `[ … ]` and quoted `$FZF_QUERY` (an
  unquoted multi-word query becomes extra test operands). fzf substitutes
  `{}` as a single-quoted string, so a multi-word item stays one word.

Two 0.75 semantics changes that do not affect this config:
`transform-nth`/`transform-with-nth` no longer split output at the pipe, and
`change-nth`/`change-with-nth` now apply the value after the current one and
skip equal values.

The quoting trap in that file: `FZF_DEFAULT_OPTS` is a single-quoted shell
string ending in `.../fzf'"`. Swapping those two characters silently breaks
the export — zsh parses the option lines as commands and reports
`not valid in this context`, far from the cause.

`packages/fzf/check-fzf.sh` guards all of it: version floor, every option set
parsed through fzf itself (exit 2 on unknown option/action/key), presence of
the 0.75-only actions and events, and every transform body run under **both
bash and dash** requiring exit 0 and identical output — fzf's own parser
accepts `[[ … ]]` happily, so only running the body reveals it.

---

## 2026-11-05

### neovim keg deleted by brew's automatic cleanup

`brew install`/`upgrade` runs `==> Cleanup` automatically and deletes
superseded kegs. neovim's keg was a dependency install
(`installed_on_request: false`), got renamed `0.12.6_old` when a newer
version arrived, and was removed — nobody uninstalled anything. The nightly
is a symlinked keg (`/usr/local/Cellar/neovim/0.12.6` →
`~/.local/opt/nvim-nightly`), so the loss was total.

Fixes: `HOMEBREW_NO_INSTALL_CLEANUP=1` in `packages/sh/zshrc-darwin`;
install formulae as requested and keep them as top-level `Brewfile` entries so
brew's bookkeeping knows they are wanted. The nightly keg keeps brew's
reported version at the **last stable** (keg directory name, receipt's
`source.versions.stable` and the formula's stable must be the same string) and
`brew pin neovim` keeps `brew upgrade` from replacing the symlink with a
build. `packages/nvim/update-nightly.sh` refreshes it idempotently, including
`/usr/local/lib/nvim` — upstream builds the nightly with prefix `/usr/local`,
so nvim loads its tree-sitter parsers from there.

---

## 2026-10-27

### tmux pane-scrollbars: `auto-hide`

Re-enabled after the 10-25 OFF decision. The on/off flip-flop across sessions
was itself the "sometimes works" bug, so the value now lives in `tmux.conf`
(committed): `auto-hide`, right side, 2000 ms, themed colours. If Termius
shows rendering corruption while the bar draws, the revert is that single
line.

### workstation gotcha: `TMUX` holding a path

The automation shell can inherit `TMUX=/usr/local/bin/tmux` (a path, not a
socket spec). Every client call then tries to use the binary as a socket:
`error connecting to /usr/local/bin/tmux (Socket operation on non-socket)` —
the message names the socket path it tried, not the binary. Prefix calls with
`env -u TMUX`.

---

## 2026-10-25

### kitty shaders removed, native cursor trail kept

Custom Slang pipelines were tried and removed: the look was not worth it and
they replaced the native trail rendering. Native `cursor_trail 3` (decay
0.1 0.25, colour #676f7f) stays, with `scrollbar scrolled-or-hovered` and
`padding_fill_strategy neighboring_cell`. If revisited: the kitty-shaders
collection targets the git-master API (member usages such as
`cursor_trail_history_to` / `wrapped_time` do not exist on stable), and any
`cursor-trail-move` pipeline suppresses the native trail. A half-written
shader cache shows as ENOENT on `m_*_0.slang-module`; `rm -rf
~/Library/Caches/kitty/shaders` rebuilds it (moot while no `custom_shaders`
line is set).

### tmux agentic helpers re-enabled, auto-attach restored

Silence watchdog (prefix M, per-window opt-in) notifies only through
`bin/tmux-bell-notify`; program bells stay a visual tab marker. The
long-command finisher arms on client attach but only for desktop clients.
Auto-attach returned SSH-only (see 2026-11-10 for the frozen scoping).
Restored with the revert: `remain-on-exit`, prefix X (kill other panes),
copy-mode R (refresh-toggle). 3.8-only lines are gated on the option existing
so a 3.7 server loads the file without errors.

---

## 2026-10-23

### llvm: hollow keg → real build parked outside the Cellar

Homebrew's `rustc` links `/usr/local/opt/llvm/lib/libLLVM.23.1.dylib`; with a
hollow keg (no `lib/`) `rustc` aborted and every cargo build died at
`cargo fetch`. llvm@21's libs are not a substitute (ABI mismatch:
`Symbol not found: __ZN4llvm10PGOOptions…`), upstream publishes no macOS
x86_64 asset for 23.1.x, and llvm has no Intel bottle, so the only llvm here
is a source build (~54 min) kept forever.

The build lives in `~/.local/opt/llvm-builds/<version>`; brew's
`Cellar/llvm/<version>` is only a symlink, and
`/usr/local/lib/libLLVM-<major>.dylib` points at the current build. A failed
install's rollback is what deleted llvm@21's real build and left a dangling
symlink that made brew fail with
`Errno::EEXIST: File exists @ dir_s_mkdir - /usr/local/Cellar/llvm/23.1.4`.
Parking a build inside `Cellar/` — even in a dot-directory — breaks brew:
it enumerates every directory there as a formula name
(`Cellar/.llvm-builds` → `Error: crystal: No available formula with the name
'.llvm-builds'`).

`packages/llvm/park-llvm.sh` parks a new build and re-points the symlinks;
`check-llvm-keg.sh` verifies every build, restores a missing keg symlink and
the `libLLVM-<major>.dylib` link. Note `/usr/local/lib/libLLVM.dylib`
(unversioned) is rust's own bundled LLVM — a different file.

crystal's bootstrap needs `/usr/local/lib/libLLVM-23.dylib`: its build links
`-lLLVM-23` without a surviving `-L` to llvm's lib dir and fails with
`ld: library 'LLVM-23' not found`, while `/usr/local/lib` is in the search
list.

### platform guards verified

`check-llvm-keg.sh` and `park-llvm.sh` exit 0 with a clear "not applicable"
message when `uname` reports Linux or arm64, and the rest of the repo contains
no other Intel-only assumptions (`pk10.zsh` mentions "brew" only in perlbrew
comments; yabai's `session_restore.sh` puts both brew prefixes on PATH).

---

## 2026-10-21

### yabai LaunchAgents became repo-managed

Both agents were hand-made local files until this date, which is how yabai
ended up **not starting at login at all**. They are now
`packages/yabai/com.asmvik.yabai.plist` and
`packages/yabai/com.carakan.yabai-session.plist`, symlinked into
`~/Library/LaunchAgents/` by `install-darwin.yaml`.

Both agents launch **app bundles**, not the raw binary. macOS takes the Login
Items name from the launched executable (BTM `Name`), not from the launchd
label: the raw binary showed as "yabai", and the session agent — running
`/bin/sh session_restore.sh` — showed as "sh" with no description. The
bundles give proper names ("Yabai", "YabaiSessionRestore"), the icon, a
bundle identifier and `CFBundleGetInfoString`. macOS strips spaces from a
script's executable name, so the session row reads "YabaiSessionRestore"
regardless of spelling.

The daemon bundle's executable is an **unsigned wrapper** that execs
`/usr/local/bin/yabai`: with a symlink to the notarized binary, Login Items
showed the fork author's Developer ID ("Polina Haritonova") as the developer.
BTM caches the record and only watches `~/Library/LaunchAgents` for
*directory* events, so editing a plist behind its symlink does not
re-register: the symlink must be replaced (`rm` + `ln -s`) and the job
re-bootstrapped. Side effect of the wrapper: the process is named "Yabai", so
`pgrep -x yabai` no longer matches.

Logs moved to `~/.local/state/yabai/` — `/tmp` is wiped at reboot, which hid
the login failures.

### p10k: `context` removed

The tmux server was started over SSH, so panes inherit `SSH_CONNECTION`,
p10k takes its remote branch and printed `user@host` on every shell. The
element is `vcs`, not `gitstatus` (gitstatus is p10k's async backend behind
it); the backend only runs if the plugin is started **before**
`oh-my-zsh.sh` — see the block in `packages/sh/zshrc`. Daemon:
`~/.cache/gitstatus/gitstatusd-darwin-x86_64`, which must match the theme's
bundled gitstatus version (rebuild:
`powerlevel10k/gitstatus/build -w`, then copy `usrbin/gitstatusd` over it —
plain `make` fails against Homebrew libgit2 1.9). Without it the prompt
silently falls back to p10k's slow synchronous renderer.

### asdf: two versions on one line

`packages/asdf/tool-versions` reads `python 3.14.8 3.15.0`. asdf uses the
first version as the default and falls back to the others for binaries that
only exist there — that is how `python3.15` resolves to 3.15.0 while
`python3` stays 3.14.8, using asdf's own generated shim. brew's
`python@3.15` keg points at the same asdf install.

### network firewall

`proxy.golang.org` (and mirrors), `golang.org`, `crates.io` and
`static.crates.io` are unreachable; only `github.com`, release asset CDNs and
`registry.npmjs.org` respond. Go builds that fetch modules (gh) and Rust
builds (atuin) cannot be built from source here — use the official release
binary (procedure in the brew doc). Vendored Go builds (lazygit, omp, engram,
gentle-ai) and npm builds (pi-coding-agent) work. The firewall was later
lifted for one session, so gh/atuin did get real source builds.

---

## 2026-10-13

### mosh evaluated and rolled back

Termius's mosh client sends no terminal type in-band; mosh-server then clamps
its colour budget to 8 and Termius's repaint model loses scrollback.
Server-side fixes (PATH via zshenv, TERM wrapper, zshrc repair,
`env TERM=… -c 256`) cannot beat a broken client. Termius uses plain SSH.
The infra fixes from that hunt stayed: `~/.zshenv` exec-channel PATH and the
`~/.zprofile` login-env links.

---

## 2026-09 / 2026-10 — vim stack details

- **supra-vim's OmniComplete snippet** in `~/.supra-vim/.vimrc` (~line 339)
  writes the autocmd across several lines with `\` continuations, so Vim
  parses the *pattern* as `*if` and the command as a bare
  `setlocal omnifunc=syntaxcomplete#Complete`, then fires in non-modifiable
  buffers and raises `E21: Cannot make changes, 'modifiable' is off`.
  `packages/vim/vimrc.local` clears it (`augroup END` + `autocmd! FileType
  *if`) and installs a single-line version. Re-apply after any supra-vim
  bootstrap; any multi-line `:autocmd` with `\` continuations has the same
  failure mode — write it on one line.
- **Session store**: `tpope/vim-obsession` + `dhruvasagar/vim-prosession`
  write to `~/.vim/session/`, named by the cwd with `/` → `%`
  (`%Users%carakan%…`). Plugins are dein-managed under `~/.vim/bundle/repos/`
  (not `site/pack/`). prosession loads with
  `execute 'source' fnameescape(path)`; `fnameescape` escapes `%` as `\%`,
  so the load works, but a raw `nvim -S %Users%…` does **not** (E499).
- **mosh** post-mortem: the rollback removed `docs/mosh.md`; the reasoning is
  in git history. Nothing about Termius/mosh should be retried.

---

## Background: brew on Intel (implementation notes)

Tier 3, no bottles, everything compiles. The workaround that makes runtimes
usable is documented in `docs/brew-intel-symlink-workaround.md`: brew's kegs
for node/bun/python are **symlinks into `~/.asdf/installs/…`** with a copied
`INSTALL_RECEIPT.json` whose `source.versions.stable` matches the keg name
string exactly (revision suffix included). `brew info` then reports the
newer version without a build.

Revision bumps (`x.y.z` → `x.y.z_1`) are swaps, not builds: rename the keg
(or symlink), rewrite the receipt's `source.versions.stable`, repoint
`/usr/local/opt/<formula>` and the `/usr/local/bin` links. Done for node
(26.12.0), bun (1.4.3) and python@3.14 (3.14.8_3).

rust comes from the rustup toolchain
(`~/.rustup/toolchains/stable-x86_64-apple-darwin`), whose rustc is
self-contained (`@rpath/libLLVM.dylib`). To let a brew build use it,
temporarily point the rust keg's `bin/rustc` at the rustup binary (backup,
symlink, build, restore) — `RUSTC=…` does not survive brew's build sandbox.

asdf's python and brew's framework python disagree on paths: pip installs
brew's modules into `/usr/local/lib/python3.15/site-packages` while the
asdf-backed interpreter reads its own site-packages. Bridge them with a
`.pth` listing both directories (meson and anything else pip-installed needs
this).

Known broken state: `awscli`, `sphinx-doc`, `gobject-introspection` have no
binary and `meson` tracebacks — their site-packages were deleted by the
Oct-2026 python-keg swap. Reinstall them; it is not a python rebuild.

---
