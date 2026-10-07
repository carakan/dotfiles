# tmux

Single source for `~/.tmux.conf`. Linked by `install.conf.yaml`.

## Images (the confusing part)

**kitty cannot display sixel, and tmux cannot display kitty's native image
protocol.** Both facts are load-bearing here:

- kitty's binary contains **zero** sixel support
  (`strings /Applications/kitty.app/Contents/MacOS/kitty | grep -i sixel` → no
  hits). Kitty renders images through its own APC graphics protocol:
  `ESC _G … ESC \`.
- tmux has no native support for that APC protocol. It understands **sixel**
  only, and only for the terminals listed under `terminal-features` below.
  `sixel_support` reports 1 on the server, but that is just "this build has the
  code" — it is still gated on the *outer* terminal advertising `sixel`.

So inside tmux, any program that emits raw kitty graphics is **silently
dropped**. Not garbled — dropped. The image simply never appears. That is the
whole bug.

The one working route is tmux's passthrough envelope: the program wraps its
sequence in `ESC P tmux; … ESC \` (ESC bytes inside doubled), and tmux forwards
it verbatim. `allow-passthrough on` (top of `tmux.conf`) is what makes this
possible. Measured on this machine, for a 9616-byte PNG:

| how the image is emitted | reaches kitty? |
|---|---|
| raw APC, passthrough off | no — 0 bytes |
| raw APC, passthrough on | no — 0 bytes |
| wrapped in `ESC P tmux; …` | **yes — SHA-256 match, 4/4 chunks in order** |

`--passthrough=auto` is *not* sufficient. Inside tmux chafa deliberately falls
back to symbol art rather than emit a sequence it assumes will be dropped, so
both the format and the passthrough mode must be named explicitly.

That is what `bin/showimg` does:

```sh
showimg photo.png                    # picks the right protocol automatically
showimg -s 80x40 photo.png           # explicit size
showimg --list-commands photo.png    # show what it would run
```

It resolves to `chafa -f kitty --passthrough=tmux` under tmux,
`chafa -f kitty` in bare kitty, and plain `chafa` elsewhere. `viu` is used as a
fallback (sized with `-w`/`-h`; it has no `--tmux` flag — it keys off `$TMUX`,
and it rejects both `-s WxH`, where `-s` means `--static`, and a `--`
separator), and `img2sixel` is refused inside tmux because it has no passthrough
mode at all — better a clear error than another silent drop.

### Size comes from the pane, not the shell

`showimg` asked tmux for `#{pane_width}x#{pane_height}` via `$TMUX_PANE`
instead of reading `COLUMNS`/`LINES`. Those two are shell variables that bash
sets but **never exports**, so a script running as a child process sees neither
and silently fell through to the `80x24` fallback — in every pane, at any size.
Images rendered at the wrong dimensions under tmux, which is what "doesn't show
properly" looked like.

Verified: a 120x40 pane now selects `-s 119x38`, a 60x20 pane `-s 59x18`, and
an explicit `-s 30x15` is passed through untouched. One column and two rows are
dropped so the image never wraps onto the prompt.

### Why no `sixel` in the kitty feature list

`terminal-features` for `xterm-kitty` deliberately omits `sixel`: advertising
it would claim a capability kitty does not have.

Sixel entries exist for terminals that actually decode sixel — `mlterm`,
`foot`, `wezterm`, `contour`, `blackbox`, `mintty`, `xterm-direct` — scoped to
those names. A `*:sixel` wildcard is not usable: matching entries **union**
unconditionally (verified both orders give the same result), so it would reach
`xterm-kitty` and make tmux emit sixel bytes kitty cannot render. A bare
`xterm*` has the same collision, plus it matches a nested `tmux-256color`
client and promises images to an inner tmux that will drop them.

Enabling `sixel` on a client only changes how tmux **forwards** an image it
already parsed; it does not make the client render anything new. Two gates
in `tty_cmd_sixelimage`:

1. the client must carry `TERM_SIXEL` (set by the `sixel` feature) or a terminfo
   `Sxl` capability, and
2. `tty->xpixel`/`ypixel` must be non-zero.

Gate 2 is why **Termius can never show sixel here**: it reports
`#{client_cell_width}x#{client_cell_height}` = `0x0`, so tmux falls back to the
text placeholder regardless of the feature list. kitty reports `8x19` but fails
gate 1 by having no decoder at all.

## Environment propagation

`update-environment` forwards `KITTY_WINDOW_ID`, `KITTY_INSTALLATION_DIR`,
`KITTY_LISTEN_ON`, `KITTY_PID`, `KITTY_SHELL_INTEGRATION` and `COLORTERM`.
chafa and viu read these to decide whether real pixels are available; without
them an image silently degrades to coloured unicode blocks, which looks like a
rendering bug but is really a missing environment variable.

`allow-passthrough on` permits passthrough only while the pane is visible. For
a background pane that must still emit, use `allow-passthrough all`.

## Nested tmux

No `tmux-256color` entry needed: nested tmux is auto-detected via DA and gets a
superset of these features by default. Kitty's `usstyle` feature supplies the
exact `Smulx`/`Setulc` undercurl sequences, so no `terminal-overrides` are
needed either.

## tmux 3.8 (`next-3.9` build)

Installed from `brew install tmux`, which currently tracks tmux's git HEAD
(`next-3.9`, superset of 3.8). The full 3.8 notes are in
`CHANGES FROM 3.7c TO 3.8`; what actually mattered here:

### Two silent breakages, both in floating panes

Neither of these errors out in a way you'd notice — tmux accepts the syntax and
just does the wrong thing:

**`move-pane -f` no longer floats anything.** With no `-s`/`-t`, 3.8 reads the
current pane as both ends of the move and fails with `source and target panes
must be different`. The old `bind f move-pane -f` became a no-op.

**`split-window -f` was repurposed.** It used to mean "floating"; it now means
"span the full window height/width". It still parses, so `split-window -fh`
silently produced a *tiled* pane. There is no floating flag left on
`split-window` at all — 3.8 creates a floater automatically when the target
pane is already floating.

Both are handled by `bin/tmux-float-toggle`, bound to `prefix+f` and `prefix+F`
(it picks the direction from `#{pane_floating_flag}` and refuses with a message
when the window has a single pane, since there is no other pane to move it
against). Verified round trip: `pane_floating_flag` `0 → 1 → 0`, back to its
original size.

Note both `move-pane` and `join-pane` need a *different* pane at each end — both
reject a pane that is source and target at once — so finding that other pane is
the script's only real job. It also has to pass `tmux -S "${TMUX%%,*}"`, because
`run-shell` jobs that fall back to a plain `tmux` reach the default socket
instead of the one that fired them.

This is what closes the 3.7c limitation: 3.7c could float a pane but never put
it back. 3.8's `join-pane` accepts a floating source and tiles it, which is what
makes `prefix+F` possible at all.

### Copy mode

3.8 adds horizontal scrolling, which matters for the 1M-line scrollback these
windows accumulate: `h`/`l` (and the arrows) now scroll within a wrapped line,
`0`/`$` jump to the logical start/end of it, and `C-u`/`C-d` scroll by half a
screen. `copy-mode-current-line-style` dims the line the cursor sits on, which
complements the existing relative line numbers.

### Scrollbars: `modal` → `auto-hide`

`pane-scrollbars` was `off` because the old `modal` mode narrows the pane by the
scrollbar width and reflows the text (no margin escape hatch — `scrollbar.c` has
no `TTYC_MARGINS` path), which was a bad trade against kitty's own scrollbar.

3.8 adds `auto-hide`, which fixes exactly that: the bar is an overlay, so the
pane never changes width. Verified — `pane_width` stayed 100 before, during and
after a scroll under `auto-hide`. `pane-scrollbars-style` styles it, and
`pane-scrollbars-timeout` (2000ms) controls how long it lingers.

### `#{client_charset}` is not a thing — use `#{client_utf8}`

`#{client_charset}` expands to an **empty string** rather than erroring, in every
tmux version (checked 3.7c and this 3.8 build; zero mentions in the man page).
That is what makes it so easy to misread as "no charset detected". The real
format is `#{client_utf8}`, a 1/0 flag:

```sh
tmux display-message -p '#{client_utf8}'          # 1
tmux display-message -p '#{?client_utf8,UTF-8,non-UTF-8}'
tmux list-clients -F '#{client_name}: #{?client_utf8,UTF-8,non-UTF-8}'
```

tmux derives that flag from the `utf8` terminal feature (new in 3.8), falling
back to inspecting `LC_CTYPE`. The feature list declares `utf8` for `xterm-kitty`
plus every other common client name (`xterm*`, `screen*`, `tmux*`, `vt100*`,
`rxvt*`, `st*`, `alacritty*`, `contour*`, `terminator*`) so tmux never has to
guess from the locale.

**Reattach to apply.** Features are negotiated once, at attach time, and cached
on the client. Editing `terminal-features` and running `source-file` does
nothing to already-connected clients — `refresh-client` does not re-negotiate
either. Verified: after adding the `utf8` entries, `refresh-client` on the
offending client left `client_utf8` at 0; it flips on detach/reattach.

Entries are scoped by terminal name rather than a catch-all `*:utf8` so a
client whose terminfo genuinely lacks `U8` is not promised UTF-8 output.

### Why the Termius client reports `utf8=0`

The second client here is not tmux at all:

```
$ tmux list-clients -F '#{client_name} type=#{client_termtype} utf8=#{client_utf8}'
/dev/ttys000  kitty(0.49.2)        1
/dev/ttys020  Termius 7.11.1       0
```

Termius (the iOS terminal) announces `TERM=tmux-256color` but sends no usable
device-attributes reply, so tmux falls back to a terminfo lookup that finds
nothing (`infocmp -x Termius` → "couldn't open terminfo file"). With no
terminfo `U8` capability and no locale in its environment, `client_utf8` is 0.

`tmux-256color` itself is fine — its terminfo does carry `U8#1`, so a real
nested `tmux attach` reports `utf8=1` even with a bare config. Termius is the
odd one out, and the `utf8` terminal feature is the override that fixes it once
it reattaches.

### What was deliberately not enabled

- **`theme`** — left at the 3.8 default of `detect`. The onedark plugin sets
  explicit hex colors for every style, so `detect` vs `dark` makes no visible
  difference; pinning it would only be noise. (3.8's own default status bar is
  `bg=themegreen,fg=themeblack` — those are 3.8 *theme keywords*, not a
  conflict with the plugin.)

## Monitor hooks: they do work, and they were silently broken

An earlier version of this file said monitor hooks never fired. **That was
wrong** — it was a harness artifact, and the real feature was quietly dead for a
different reason. Both are now fixed and verified.

Monitor syntax is `set-hook -T -B name:what:format command`:

- `name` must begin with `@`.
- `what` is empty (the attached session), a pane id (`%3`), `%*` for all panes,
  a window id (`@2`), or `@*` for all windows.
- **`-T` must come before `-B`.** The other order fails with
  `too many arguments`.

Monitors are client-scoped: they cannot be created at config-parse time
(`no current session`), so they are registered by `bin/tmux-agent-monitors` from
the `client-attached` hook.

The bug that made the agent-finisher notification never appear was quoting.
tmux hands a hook command to `sh -c` after one round of unescaping, so a nested
`run-shell -b "tmux set -t \"#{pane_id}\" …"` leaves a literal `\"` in the string
and the command no-ops. The hook registers, the format evaluates true, and
nothing happens — no error, no log. The fix was to move the logic into
`bin/tmux-agent-start` / `bin/tmux-agent-done` and have the hooks call them with
plain arguments. Verified end to end through the real `client-attached` hook:

```
start hook: busy-since='1791211984' cmd='sleep'
done hook:  busy-since cleared
NOTIFICATION: sleep finished in t:bg (5s)
```

Two more traps worth knowing:

- `run-shell` does **not** inherit the client's environment, so
  `TMUX_AGENT_DONE_TEST` set in your shell never reaches the hook. Use
  `tmux set-environment -g` if a hook needs a variable.
- `TMUX` inside a `run-shell` job is `socket-path,server-pid,session-id`; the
  first field is what `tmux -S` needs. Scripts that fall back to a plain `tmux`
  when `TMUX` is unset will silently talk to the *default* socket instead.

The ordinary 3.8 event hooks (`pane-created`, `pane-exited`, `pane-died`,
`pane-title-changed`, `window-renamed`, `pane-shell-prompt`, …) all fire
correctly and are available if you want edge-triggered behaviour instead of
polling.

## OPEN: powerline glyphs correct in Termius on Ubuntu, broken on macOS

**Status: diagnosed, not yet fixed.** Do not "fix" this by changing fonts
without reading this section — an earlier guess on that was wrong.

### Symptom

The status bar's powerline separators render correctly in a Termius client
attached to the **Ubuntu** tmux session, but show as wrong/garbled characters
in a Termius client attached to the **macOS** tmux session.

### What is NOT the cause

- **Not the font.** Termius is one app with one font. Both sessions emit
  identical bytes from identical config, and Ubuntu renders them correctly,
  so Termius *does* have a font covering these code points. An earlier claim
  that "Termius has no Nerd Font" was inferred from the symptom rather than
  tested, and is wrong.
- **Not the config.** `packages/tmux/tmux.conf` is deployed to both platforms
  by `install-linux.yaml` and `install-darwin.yaml`, and the theme plugin is
  the same checkout. Both servers emit the same glyphs.

### What the status bar actually emits

```
status-left  : U+E0B0, U+E0B1
status-right : U+E0B2 (x4), U+E0B3
```

All Private Use Area, i.e. Nerd Font Powerline glyphs with no Unicode
meaning. kitty on macOS renders them via:

```
font_family postscript_name=MapleMono-NF-Light
symbol_map   U+e0b0-U+e0c8 … Maple Mono NF Regular
```

That `symbol_map` is macOS-side only; it explains why kitty works, not why
Termius on macOS differs from Termius on Ubuntu.

### Leading hypothesis: server-side, not terminal-side

Same client + same bytes + different rendering ⇒ the difference is in tmux.
Prime suspect is colour-style negotiation. The theme uses `#[fg=…,bg=…]`
spans throughout, which need tmux ≥3.2 *and* a client that negotiates RGB.
The macOS config only declares features for kitty:

```tmux
set -as terminal-features 'xterm-kitty:RGB:…'
```

There is no entry for a Termius/xterm client. If Termius negotiates as plain
xterm on one side and as something RGB-capable on the other, tmux may
downgrade or drop the background spans, which would mangle exactly this kind
of segmented status bar.

### Captured macOS baseline (measured 2026-10-05)

Everything knowable without the Ubuntu box, so the post-reboot check is a
plain comparison:

```
tmux -V     : tmux next-3.9
LANG        : en_US.UTF-8          <- locale theory does NOT apply here

clients:
  xterm-kitty   -> …,RGB,usstyle,…      (kitty, full features)
  tmux-256color ->  bpaste,focus,title  (no RGB)

glyphs emitted by the theme:
  status-left  : U+E0B0, U+E0B1
  status-right : U+E0B2 (x4), U+E0B3
```

The `tmux-256color` client with **no `RGB`** is the anomaly: it is the one that
behaves like Termius, and the theme's config only grants a full feature set to
`xterm-kitty`:

```tmux
set -as terminal-features 'xterm-kitty:RGB:clipboard:usstyle:…'
```

### To confirm, run these on BOTH machines

```sh
tmux -V
tmux display -p '#{client_termname}'
tmux display -p '#{client_termfeatures}'
```

Compare the `client_termfeatures` line against the baseline above. If the
Ubuntu/Termius client reports `RGB` and the macOS one does not, that is the
answer. Also check the Ubuntu `~/.tmux.conf` is really this file —
`PLATFORMS.md` notes omarchy owns `~/.config/omarchy/**`, so a local override
would explain the difference outright.

### Also worth checking

`PLATFORMS.md` records that **omarchy owns and git-updates its own config tree**
under `~/.config/omarchy/**`. If the Ubuntu box runs omarchy, its `~/.tmux.conf`
may not actually be this file — a local override would explain everything.
Check `git -C ~/.tmux/plugins/tmux-onedark-theme log` and compare the deployed
`~/.tmux.conf` on both hosts.

### Candidate fix if it is the RGB/terminal-features path

Add an entry for Termius alongside the kitty one, e.g.:

```tmux
set -as terminal-features 'xterm*:RGB'
```

Scoped as narrowly as the real `client_termname` allows — a bare `xterm*` also
matches a nested `tmux-256color` client and would promise RGB to an inner tmux.
This is **untested**; only apply it once the `client_termname` output confirms
the hypothesis.


