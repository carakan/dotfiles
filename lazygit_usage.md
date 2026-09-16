# lazygit_usage.md — lazygit in these dotfiles

Setup: `packages/lazygit/config.yml` (dotbot-symlinked to
`~/Library/Application Support/lazygit/config.yml`). Requires **lazygit ≥ 0.65**
(Homebrew), **delta** for diff rendering, **gh** for PR integration, and — for
the AI commands — the local qwen llama-server (ToshLLM) at
`http://127.0.0.1:8080/v1` with its API key in `~/.config/toshllm/api-key`
(untracked, chmod 600; same pattern as `gh` hosts.yml — never hardcode it).
Runs inside tmux (footer messages) and inside the nvim snacks float (`<leader>gg`).

Theme: Solarized Osaka Dark, nerd fonts v3, custom `delta` diff renderer.

---

## AI commit messages (local qwen)

All logic lives in **`bin/lazygit-ai`** (one script, one prompt — edit
`packages/lazygit/prompt` to change how qwen replies; it's linked to
`~/.config/lazygit-ai/prompt` by dotbot). The custom commands in
`config.yml` are one-liners calling it. Both act on the **staged** diff, split
in two: **modified tracked files** (`git diff --cached --diff-filter=M`) go in
as the full analyzable diff; everything else — added/deleted/renamed
(`--diff-filter=m --name-status`) — is passed as **name + status reference
only**, so huge new files (lockfiles, blobs) can't overflow the model's
64k-token context. The prompt tells qwen to treat that second section as
reference. Feedback is a **tmux status-line message** (5 s,
non-blocking); outside tmux it degrades to silent. Failures (no staged
changes, server down, empty reply) surface as a lazygit error popup **with
the server's reason** — e.g. a huge staged diff that exceeds the model's
64k-token context reports the token counts; no draft is left behind. The
diff is streamed (stdin → jq → curl), so its size never hits the OS argv
limit. Env overrides: `LAZYGIT_AI_URL`, `LAZYGIT_AI_MODEL`,
`LAZYGIT_AI_TIMEOUT`, `LAZYGIT_AI_PROMPT`, `TOSHLLM_API_KEY`.

### `Ctrl+G` — generate, review, commit yourself

1. Stage files (`space`), focus the Files panel, press `Ctrl+G`.
2. Spinner "Asking local qwen for a commit message..." while the diff goes to
   `http://127.0.0.1:8080/v1/chat/completions`.
3. tmux footer: *"Ready to commit with LLM - press c to review and commit"*.
4. Press `c` — the commit panel opens **pre-filled**: summary (first line) +
   description (body).
5. Edit as needed → submit with **`Ctrl+C`** (`submitEditorText`). `<enter>`
   inserts a newline instead (see overrides below).

Commit + push is deliberately two keys: `c` (panel) then `P` (push). lazygit
has no auto-push-on-commit option; rebinding `c` to `git commit && git push`
would trade the message panel for git's editor.

Draft lives in `$GIT_DIR/LAZYGIT_PENDING_COMMIT` (per-worktree; worktrees don't
share drafts). `esc` in the panel clears it; lazygit deletes it after committing.

### `Ctrl+C` — generate and commit automatically (one-shot)

Same generation, then `git commit -m` runs immediately with the full message
(summary + body, hooks included) and the tmux footer confirms:
*"LLM commit done: \<summary\>"*. lazygit auto-refreshes with the new commit.
No draft is written, so a later `c` won't pick up a stale message.

> Note: in the **Files panel** `Ctrl+C` is this command, not quit. Quit from
> there with `q`/`<esc>`; `<c-c>` still quits in every other context and still
> submits inside the commit panel.

### Message format

Qwen replies with a conventional-commit summary (`type: subject`, ≤ 72 chars)
plus a body explaining what/why. The command strips `<think>` blocks (Qwen3
reasoning), trims whitespace, and maps first line → Commit summary, rest →
Commit description (toggle focus with `<tab>`). Timeout: 120 s (27B model on
CPU).

---

## Keybinding overrides (vs stock lazygit)

| Binding | This config | Stock |
|---|---|---|
| `return` | `q` **and** `<esc>` — close popups, step back, quit at top level | `<esc>` |
| `quitOnTopLevelReturn` | `true` — return at top level exits (closes the nvim float) | `false` |
| `quit` | untouched (stock `q`, `<c-c>`) — `q` is consumed by `return` above, so top-level quit comes from `quitOnTopLevelReturn` | `q`, `<c-c>` |
| `submitEditorText` | `<c-c>` (commit panel submit) | `<enter>` |
| `appendNewline` | `<enter>` (newline in commit panel) | — |
| `scrollDownMain` | `<pgdown>`, `J`, `<ctrl+d>`, `<ctrl+down>` | `<pgdown>`, `J`, `<ctrl+d>` |
| `scrollUpMain` | `<pgup>`, `K`, `<ctrl+u>`, `<ctrl+up>` | `<pgup>`, `K`, `<ctrl+u>` |
| `confirmInEditor` | `<alt+enter>`, `<ctrl+s>` (0.62+ default `cmd/ctrl+enter` is flaky through kitty+tmux) | `<ctrl+enter>`, `<ctrl+s>` |

Why `quit: '<esc>'` is gone: in the merge conflicts view `<esc>` was unclaimed,
and fell through to quit, killing lazygit mid-merge. Now `<esc>` is a return
key — it closes popups, backs out of the conflicts view, and quits at top level
(closing the nvim float). Hard quit anywhere: `<c-c>`.

Custom commands: `<c-g>` / `<c-c>` (Files panel only — full docs above).

---

## Global

| Key | Action |
|---|---|
| `1`–`5` | Jump to side panel (numbers shown on each panel title), `0` focus main view |
| `←` / `→` | Previous / next panel tab |
| `P` / `p` | Push / Pull |
| `f` (Files panel) | Fetch |
| `R` | Refresh repo state (no fetch) |
| `z` / `Z` | Undo / Redo (reflog-driven) |
| `m` | Merge/rebase options (abort, continue, skip) |
| `\|` / `\` | Cycle diff renderers forward / reverse ("delta" ↔ "delta sbs") |
| `}` / `{` | Increase / decrease diff context size |
| `(` / `)` | Decrease / increase rename similarity threshold |
| `W`, `<ctrl+e>` | Diffing options (diff against ref, reverse) |
| `<ctrl+s>` | Filter options (filter commits by path/author) |
| `<ctrl+w>` | Toggle whitespace in diff |
| `<ctrl+p>` | Custom patch options |
| `:` | Execute shell command |
| `<alt+shift+c>` | Edit config file (also `e` in Status panel) |
| `@` | Command log options |
| `?` | Keybindings menu |
| `+` / `_` | Next / prev screen mode (normal/half/full) |

## List panels (all side panels)

| Key | Action |
|---|---|
| `j`/`k`, arrows | Move |
| `v`, `<shift+↑/↓>` | Range select |
| `,` / `.` | Previous / next page |
| `<` / `>` (`<home>`/`<end>`) | Top / bottom |
| `/` | Search (or filter, where supported) — `n`/`N` next/prev match |
| `H` / `L` | Scroll left / right |
| `[` / `]` | Previous / next tab |

## Files panel

| Key | Action |
|---|---|
| `space` | Stage / unstage file |
| `a` | Stage / unstage all |
| `enter` | Stage individual lines (staging view); on a directory, collapse |
| `c` | Commit staged (opens panel — pre-filled after `Ctrl+G`) |
| `A` | Amend last commit with staged changes |
| `C` | Commit with git editor |
| `d` | Discard options for file |
| `D` | Working-tree reset options (nuke) |
| `e` / `o` | Edit in nvim (hosting nvim when inside a float) / open |
| `i` | Add to .gitignore |
| `s` / `S` | Stash / stash options (staged, unstaged…) |
| `` ` `` | Flat vs tree file view; `-`/`=` collapse/expand all |
| `M` | Merge-conflict options |
| `<ctrl+f>` | Find base commit for fixup |
| `<ctrl+b>` | Filter files by status |
| `<ctrl+t>` | External difftool |

## Staging view (`enter` on a file)

| Key | Action |
|---|---|
| `space` | Stage / unstage selected lines or hunk |
| `a` | Toggle line-by-line vs hunk selection |
| `v` | Range select |
| `<tab>` | Switch staged/unstaged view |
| `d` | Discard (unstaged) / unstage (staged) |
| `E` | Edit hunk in editor |
| `<c-f>` | Find base commit for fixup |
| `esc` | Back to files panel |

## Commit message panel

| Key | Action |
|---|---|
| `<c-c>` | Submit commit (this config) |
| `<enter>` | Newline (this config) |
| `<tab>` | Toggle summary ↔ description |
| `<esc>` | Close — clears the AI draft if unchanged |

## Branches

| Key | Action |
|---|---|
| `space` | Checkout (`-` or `c` `-` for previous branch) |
| `n` / `N` | New branch / move unpushed commits to new branch |
| `d` | Delete (local/remote options) |
| `r` | Rebase checked-out branch onto selected |
| `M` | Merge into current (regular / squash) |
| `f` | Fast-forward from upstream |
| `u` | Upstream options (set, unset, reset to upstream) |
| `s` | Sort order |
| `T` | New tag |
| `R` | Rename |
| `i` | git-flow options (git-flow-next supported) |
| `o` / `O` / `G` | Create PR / PR options / open PR in browser (needs `gh`) |
| `<enter>` | View commits |

## Commits panel

| Key | Action |
|---|---|
| `enter` | View commit files (then `space`/`a` build a custom patch, `<c-p>` for patch options) |
| `r` / `R` | Reword / reword with editor |
| `d` | Drop commit (rebase) |
| `s` / `f` | Squash / fixup into commit below |
| `F` / `S` | Create fixup! commit / apply fixups (autosquash) |
| `e` / `i` | Edit here (interactive rebase) / start interactive rebase |
| `<c-j>`/`<c-k>`, `<alt+↓/↑>` | Move commit down / up |
| `A` | Amend with staged changes (works deeper via rebase) |
| `a` | Set author / co-author |
| `t` / `T` | Revert / Tag |
| `g` | Reset options onto commit (soft/mixed/hard) |
| `C` / `V` | Cherry-pick copy / paste; `<c-r>` clears selection |
| `B` | Mark base commit for `rebase --onto` |
| `n` / `N` / `w` | New branch / move commits to new branch / worktree |
| `o` / `G` | Open in browser / open PR |
| `<c-l>` | Log options (graph, sort) |
| `b` | Bisect options |

## Merge conflicts

With a conflicted file (`UU`) focused, lazygit opens the interactive merging
view. It shows the raw conflict markers **by design** — lazygit parses the file
itself; delta/diffRenderers are intentionally not applied here (they only
render read-only diffs, which stay delta-styled).

| Key | Action |
|---|---|
| `space` | Pick hunk at cursor |
| `b` | Pick both hunks |
| `↑/↓` or `k/j` | Move within conflict |
| `←/→` or `h/l` | Previous / next conflict |
| `z` | Undo last resolution |
| `M` | Merge-conflict options |
| `e` / `o` | Edit / open file |
| `<esc>` | Back to files panel (safe — no longer quits) |

While a conflicted file is focused, lazygit re-enters merging automatically —
that's 0.65 behavior, not a trap.

## Stash / Reflog / Status

- Stash: `space` apply, `g` pop, `d` drop, `n` branch from stash, `r` rename.
- Reflog: `space` checkout, `g` reset, `C`/`V` cherry-pick, `o` browser.
- Status: `enter` recent repos, `a`/`A` cycle branch log, `e` edit config.

## Maintenance notes

- Homebrew updates lazygit in place; config targets ≥ 0.65 field names
  (`git.diffRenderers`, custom-command `output:` — the old `git.pagers` /
  `subprocess:` are gone and lazygit auto-migrates+rewrites the file if it sees
  them).
- In `command: >` folded blocks, keep every content line at the same indent:
  deeper-indented lines keep literal newlines and break the shell command.
- If lazygit prints "user config must be migrated", review the diff it made.
- The AI key file is machine-local and untracked on purpose; rotate it in
  ToshLLM and update `~/.config/toshllm/api-key` together.
