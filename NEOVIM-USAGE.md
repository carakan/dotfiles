# Neovim Usage — living cheat-sheet

> **Contract:** shortcuts listed here are the keymap contract for the nvim
> migration (see [`packages/nvim/MIGRATION.md`](./packages/nvim/MIGRATION.md),
> phase-3 checklist). Plugins may be swapped for lua equivalents, but **these
> keys must keep working** unless a checkbox in MIGRATION.md says otherwise.
> Companion: [`packages/nvim/legacy-lua-extracted.lua`](./packages/nvim/legacy-lua-extracted.lua)

Last updated: 2026-09-04 · nvim v0.12.5

---

## Basics

| Keys | Action |
|---|---|
| `<C-s>` | Save file (normal/insert/visual) |
| `<bs>` (normal) | Alternate buffer (`<c-^>`) |
| `J` / `K` (visual) | Move selection down / up |
| `<` / `>` (visual) | Indent, keeps selection |
| `.` (visual) | Repeat last normal-mode change |
| `j` `k` | Wrapped-line aware up/down |
| `0` `$` `^` `Home` `End` | Screen-line motion when `wrap` is on |
| `Y` | Yank to end of line (`y$`) |
| `<leader>/` | Clear search highlight |
| `<leader>fc` | Jump to next git conflict marker |
| `<Leader>=` | Equalize window sizes |
| `<C-w>o` | Zoom current window (toggle with same key) |
| `<C-w>` `+`/`-`/`=` | Resize windows |
| `zh` / `zl` | Horizontal scroll |
| `<C-h><C-j><C-k><C-l>` | Navigate splits **and tmux panes** seamlessly (vim-tmux-navigator) — fixed in step-0 (plain window-move overrides deleted; window motion remains via `<C-w>h/j/k/l`) |
| `<leader>ew` / `es` / `ev` / `et` | Edit file relative to current one (same window / split / vsplit / tab) |
| `Q` | Pick a buffer to close (close-buffers menu) — **shadows native multicursor's `Q`**; multicursor trial uses `{Visual}Q` / `gQ` / `]C` instead |

## Fuzzy finding — fzf-lua *(keys stay identical after migration)*

| Keys | Action |
|---|---|
| `<C-p>` | Files |
| `<C-t>` | Buffers |
| `<C-c>` | Commands |
| `<leader>ss` | Live grep (project) — visual selection too |
| `<leader>sh` | Live grep incl. hidden (`-u`) |
| `<leader>sw` / `<leader>sW` | Grep word under cursor / WORD |
| `<leader>sl` | Re-run last grep |
| `<leader>ag` | Grep prompt |
| `<leader>ag` (visual) | Grep selection |
| `<leader>M` | Resume last picker |
| `<leader>m` | Browse keymaps |
| `<leader>;` | Lines in current buffer |
| `<leader>?` | History (oldfiles) |
| `<leader>A` | Windows |
| `<leader>O` | Tags in current buffer |
| `<leader>ft` | Filetypes |
| `<leader>ga` / `<leader>gl` | Commits (buffer / project) |
| `<leader>o` | Tags via coc fzf-preview *(migrates → fzf-lua btags/ltags; slot kept)* |
| `F` | Project grep with prompt *(migrates → `<leader>sw` style; slot kept)* |

In pickers: preview follows selection; `delta` renders git diffs; images preview via snacks (kitty graphics) with chafa fallback.

## Code intel — coc.nvim *(keys stay identical: blink.cmp + native LSP take the same slots)*

| Keys | Action |
|---|---|
| `gd` / `gy` / `gi` / `gr` | Definition / type definition / implementation / references |
| `K` | Hover docs (help topics in vim/help buffers) |
| `<leader>rn` | Rename symbol |
| `[c` / `]c` | Previous / next diagnostic |
| `<c-space>` | Trigger completion |
| `<TAB>` | Select completion / expand snippet / jump |
| `<C-n>` / `<C-p>` | Cycle completion menu |
| `<leader>ca` | Code action *(moved from `<leader>a` in step-0 — that key now belongs to treesitter swap-parameter)* |
| `<space>y` / `<space>h` | Yank list (coc-yank) *(migrates → fzf-lua registers; slot kept)* |
| `:CocCommand` | Run any coc command |

> `<leader>a` owner resolved (step-0): treesitter swap-parameter keeps it; coc code-action lives on `<leader>ca` until phase 3 replaces coc with native LSP.

## Diagnostics & formatting — ALE *(keys stay identical: nvim-lint + conform.nvim take the same slots)*

| Keys | Action |
|---|---|
| `]a` / `[a` | Next / previous error (wrapped) |
| `<leader>f` | Format / auto-fix current buffer — *(fires instantly since step-0: the `<leader>f0–f9` fold maps were deleted; folds are disabled anyway)* |

## Testing — vim-test + tslime *(keys stay identical)*

| Keys | Action |
|---|---|
| `<leader>tn` | Test nearest to cursor |
| `<leader>tf` | Test current file |
| `<leader>ta` | Whole suite |
| `<leader>tl` | Re-run last test |
| `<leader>tv` | Visit last run test file |
| `<C-c><C-c>` | Send selection / line to tmux pane (tslime) |
| `<C-c>r` | Reset tslime pane target |

Tests run **inside the current tmux pane** (`strategy = tslime`) — core of the review workflow.

## Git

| Keys / Command | Action |
|---|---|
| `<leader>pd` | Preview current hunk (gitsigns) |
| `<leader>pr` | Reset current hunk (gitsigns) |
| inline blame | Current-line git blame always on (gitsigns) |
| `<leader>gy` (n/v) | Copy GitHub URL of selection/line (gitlinker) |
| `:DiffviewOpen [ref]` | Diff view against ref |
| `:DiffviewFileHistory` | File/repo history |
| `<leader>gg` | **LazyGit** float (snacks) — full git UI, see section below |
| `:Octo` | GitHub PRs/issues from nvim (picker: fzf-lua) |

## LazyGit — `<leader>gg` (snacks.lazygit, replaces neogit)

Floating lazygit terminal themed from your highlight groups (nixvi-style flat
look: `NormalFloat:Normal`, borderless feel). LazyGit is a TUI — its own keys
apply inside the float. Press `?` anytime for the live keybindings menu, `x`
to quit... actually `q` quits. Panels: `1` status · `2` files · `3` branches ·
`4` commits · `5` stash.

### Everyday flow (files panel = your staging area)

| Key | Action |
|---|---|
| `space` | **Stage / unstage** the selected file (toggle) |
| `a` | Stage **all** changes |
| `u` | Unstage selected (when staged change selected, `d` unstages too) |
| `c` | **Commit** staged changes (message prompt inside lazygit) |
| `C` | Commit using `$GIT_EDITOR` |
| `A` | Amend last commit |
| `d` | Discard changes (careful — offers choices on staged items) |
| `e` | Open file in editor (opens in **this nvim**, not an external one) |

### History, stash, rebase

| Key | Panel | Action |
|---|---|---|
| `4` → `enter` | commits | **Diff** of the selected commit |
| `4` → `<ctrl+o>` | commits | **Copy abbreviated SHA** to clipboard |
| `4` → `r` | commits | Reword commit message |
| `4` → `e` | commits | Start **interactive rebase** from selected commit |
| `4` → `d` | commits | Drop commit (via rebase) |
| `4` → `s` / `f` | commits | Squash / fixup into the commit below |
| `4` → `m` | commits | View merge/rebase options (abort/continue/skip) |
| `3` → `B` | branches | Mark base commit for `--onto` rebase |
| `2` → `s` | files | **Stash** all changes (`S` = stash options: staged, unstaged, keep-index) |
| `5` | stash | Stash list: `space` apply, `g` pop, `d` drop |
| `z` | any | **Undo** last git action (reflog-based) · `Z` redo |
| `` ` `` | files | Toggle flat ↔ **tree view** of changed files |
| `p` / `P` | any | Pull / Push |

### Integration notes

- **Config**: `packages/lazygit/config.yml` → `~/Library/Application Support/lazygit/config.yml` (**real macOS path** — Go `os.UserConfigDir`; a `~/.config/lazygit/config.yml` XDG fallback symlink also points there). **Theme: Solarized Osaka Dark** (craftzdog extra) — snacks passes `configure = false` so the yml theme rules inside the float too. Delta side-by-side pager + `lazygit-theme` delta feature (Solarized accents, defined in `packages/delta/themes.gitconfig`); colored graph branch log; `notARepository: skip`.
- `e` opens files in the **hosting nvim** when inside the float (`$NVIM` remote trick from r4ppz), standalone nvim otherwise.
- Extra scrolling: `J`/`K`/`ctrl-d`/`ctrl-u` scroll the main panel; `q`/`esc` quit; startup popups disabled.
- Worktrees: run `<leader>gg` inside any worktree — lazygit operates on that tree (see §worktrees).
- octo + lazygit: checkout a PR via `:Octo pr checkout`, then `<leader>gg` for stage/commit.


## Editing — motions & text objects *(keys stay identical)*

| Keys | Action |
|---|---|
| `s` (motion) | Flash jump — type chars, hit to leap (replaces easymotion) |
| `ak` / `ik` | Around / inside **block** (treesitter textobject) |
| `ac` / `ic` | Around / inside **class** |
| `af` / `if` | Around / inside **function** |
| `aa` / `ia` | Around / inside **argument/parameter** |
| `]m` / `[m` | Next / previous function start |
| `]]` / `[[` | Next / previous class start |
| `<leader>a` / `<leader>A` | Swap parameter with next / previous *(sole owner confirmed in step-0)* |
| `gnn` `grn` `grc` `grm` | Incremental selection: start / expand node / expand scope / shrink |
| `cs`/`ds`/`ys`/`S` | Surround — change / delete / add / visual-add (nvim-surround; see examples below) |
| `gS` / `gJ` | Split one-liner into lines / join block to one line (splitjoin) |
| `ci(`/`caq`/… | Targets.vim extended text objects (quotes, parens, separators) |
| `f`/`t`/`T` | Jump-highlight for find/till (qs + hlslens lens below) |
| `n` / `N` | Search with virtual lens showing `[count] ▲▼` (hlslens) |
| `:Inspect` | Show treesitter highlight captures under cursor *(native; replaces old `<leader>is`)* |
| **Multicursor — NATIVE 0.13** *(trial; multicursor.nvim was loaded but never bound any keys — `<C-M-n>` never actually existed)* |
| `Q` / `{Visual}Q` | Place/remove multicursor; with `[count]`: place at each search match (normal `Q` = close-buffers here, use Visual `Q`) |
| `gQ` | Multicursor command (see `:h Q`, source header lists gQ) |
| `]C` | Jump to next multicursor |
| `g CTRL-A` | Insert ascending number at each multicursor ("counter") |
| `<C-LeftMouse>` | Toggle multicursor · `CTRL-L` clears all (also does nohl + diffupdate) |
| Rendering | kitty cursors protocol if the terminal chain supports it, else `hl-MCursor` highlights — inside tmux expect the highlight fallback |

### Surround examples (nvim-surround — same UX as tpope/vim-surround)

`cs"'` → change `"…"` to `'…'` · `ysiw]` → wrap word in `[…]` · `ds"` → remove quotes ·
visual `S<p class="x">` → wrap selection in tag.

### Visual block — all the ways (audited SAFE system-wide, KEYMAP-COLLISIONS.md J.0)

| Keys | Action |
|---|---|
| `<C-v>` | Enter **blockwise visual** from normal mode (column selection) |
| `v` then `<C-v>` (or `V` then `<C-v>`) | Switch between charwise / linewise / blockwise visual |
| `gv` | **Reselect the last visual selection** (remembers its mode) — the "other way" when you lost a selection |
| `<C-o>` then `<C-v>` (from insert) | One-shot: pop to normal, enter blockwise, return to insert after |
| `<C-g>` (in visual) | Toggle visual ↔ select mode |
| `I` / `A` (after block select) | Insert at start / end of **every** line of the block — `Esc` applies to all |
| `r x` / `c` (after block select) | Replace / change every character of the block |

No layer grabs `<C-v>`: not Karabiner (only caps remapped), not kitty (`cmd+v` paste is a different combo), not tmux (its `C-v` lives only in copy-mode-vi for rectangle-toggle), not zsh. Standard key works.

### Sort — sort.nvim *(installed 2026-09-04; replaces vim-sort-motion, same `gs` keys)*

| Keys / Command | Action |
|---|---|
| `gs` + motion | Sort operator — `gsip` paragraph, `gsii` indentation level, `gs2j`/`gs3j` next 2–3 lines, `gsi(` lines inside parens |
| `gs` (visual) | Sort the selection |
| `:Sort` (visual) | Sort selected lines |
| `:Sort ip` / `:Sort 2j` | Ex command with motion argument |
| `:%Sort` | Whole buffer |

Delimiter-aware: sorts segmented lines (comma lists, `{ a, b, c }`-style) keeping structure — not just whole-line sort. Supports natural ordering and custom delimiters/presets via setup opts (`:h sort.nvim`). Mind the trio: `gs` sort (this) · `gS`/`gJ` splitjoin · `s`/`S` flash jump (normal) / surround (visual).

## GitHub in the editor — octo.nvim

Configured with **fzf-lua as picker** (every list opens in fzf-lua), emojis on, projects_v2 scope warnings suppressed.

### The workflow

```vim
:Octo pr list          " open PR picker (fzf-lua) — filter by author/state/label
:Octo pr search author:@me is:open
:Octo pr create        " from current branch: title/body buffer → submit with :Octo pr create (again)
:Octo pr checkout 123  " checkout PR #123 locally (branch + review)
:Octo pr changes       " review the diff of the PR under cursor
:Octo pr merge squash  " or merge/rebase — closes with confirmation
:Octo pr commits       " commits of PR under cursor
:Octo pr browse        " open in browser
:Octo issue list       " issue picker; :Octo issue create → template buffer
:Octo repo browse      " open repo home
:Octo review start     " enter review mode on the PR under cursor
:Octo review submit    " submit pending review comments (comment/approve/request-changes)
```

### Inside octo buffers (issues, PRs, diffs)

| Key / Command | Action |
|---|---|
| `<CR>` on a `#123` / URL / sha | Open that issue/PR/commit |
| `:Octo comment add` (visual on diff lines) | Attach a review comment to those exact lines |
| `:Octo comment add` (issue/PR buffer) | Top-level comment (opens editable buffer, `:wq`-style submit via `:Octo comment submit`... follow the buffer hint) |
| `:Octo reload` | Refresh the buffer from GitHub |
| `:Octo pr url` / `:Octo issue url` | Copy the URL (gitlinker-friendly) |
| `:h octo` | Full command + buffer-map reference |

Review flow that fits the AI-code era: checkout PR → `:Octo pr changes` → select suspicious lines in visual → `:Octo comment add` → `:Octo review submit` — everything without leaving nvim, and every list is fzf-lua so muscle memory from `<leader>gl`/`ga` applies.

## Git worktrees — `<leader>wt` family (worktrees.nvim)

A worktree = a second checkout of the same repo in another directory, on a
different branch, sharing `.git`. Perfect for the review workflow: run the AI
agent's branch in `../feature-x` while your current tree stays untouched — no
stashing, tests can run in one tree while you edit another.

Configured with `base_path = ".."` → worktrees are created as **sibling
directories** of the current project root.

| Key | Action |
|---|---|
| `<leader>wtc` | **Create**: prompts for a branch name, creates `../<branch>/` checked out on that branch and registers it |
| `<leader>wts` | **Switch**: pick an existing worktree (fuzzy) → change to it |
| `<leader>wtd` | **Delete**: pick a worktree → remove its directory + registration (guarded against the primary tree) |

Plumbing equivalents when scripting outside nvim: `git worktree add ../fix-42 fix-42` · `git worktree list` · `git worktree remove ../fix-42`.

**Tips**
- Each worktree has its own session: prosession keeps a separate buffer layout per directory.
- octo + worktrees compose: checkout a PR (`:Octo pr checkout`) inside a worktree and your main checkout stays clean.
- Servers/tests: run `mix test`/`rspec` in worktree A via tslime while editing worktree B — no state collisions.
- `nvim-tree`/fzf-lua always operate on the *current* tree; `<C-t>` buffers list is per-worktree.

## AI agents *(phase 4 — slots reserved; keys defined when wired)*

| Tool | Role |
|---|---|
| opencode.nvim | Primary agent: context injection, prompt with LSP context, accept/reject edits in-editor |
| omp (oh-my-pi) | Review-mode integration (`omp` CLI v18.1.10); docs JS-rendered — read during phase 4 |
| local autocomplete | Existing toshLLM + llama.cpp server at `http://127.0.0.1:8080/v1` (OpenAI-compatible) wired as completion source — **no new research, no benchmark** (user directive) |

## Sessions & windows

| Keys / Command | Action |
|---|---|
| `:Prosession <dir>` | Open project session (auto-restore buffers/layout) |
| `:Obsession` | Toggle session tracking |
| `:SCROLL`-style `lens.vim` | Auto window resize animation *(plugin being replaced — see MIGRATION.md §4d)* |

## Databases — vim-dadbod + vim-dadbod-ui *(keys stay identical; completion moves to blink.compat)*

Connections run against **postgresql@18** on localhost. dadbod is the query
engine, dadbod-ui the drawer/sidebar; both share the same connection.

| Keys / Command | Action |
|---|---|
| `:DBUI` | Open the database drawer (tree: connections → schemas → tables → columns) |
| `:DBUIToggle` | Show / hide the drawer |
| `:DBUIAddConnection` | Add a connection (e.g. `postgresql://localhost:5432/mydb`) |
| `:DBUIFindBuffer` | Jump from a SQL buffer to its tree entry |
| `:DBUIRenameBuffer` | Rename a saved query buffer |
| `:DB <url>` | Ad-hoc connection buffer without the UI |
| `<LocalLeader>S` (in SQL buffer) | Execute query on the bound connection (works with visual ranges — select, `<LocalLeader>S`) |
| `o` / `<CR>` (drawer) | Expand / open entry under cursor |

**Behavior worth knowing:**

- Opening a table in the drawer creates a scratch SQL buffer already bound to
  that connection — write a query there and `<LocalLeader>S` it.
- **Table helpers** (configured for postgresql): under each table the drawer
  exposes `Count` (`SELECT COUNT(*) FROM "{table}"`) and `Explain`
  (`EXPLAIN ANALYZE {last_query}` — replays your last query with the plan).
- Nerd-font database icons are on; echo notifications on (`g:db_ui_*` in
  `vimrc.local`).
- SQL completion inside these buffers comes from vim-dadbod-completion —
  during migration this needs **blink.compat** (MIGRATION.md §4d) or it
  silently dies.
- `lifepillar/pgsql.vim` adds postgres-specific syntax for `.pgsql` files on
  top of the built-in sql filetype.

## Tools & niceties

| Keys / Command | Action |
|---|---|
| `<leader>d` | Look up word in Dash.app (dash.vim) |
| `gx` | Open URL under cursor / github issue / brewfile / package.json dep (gx.nvim) |
| `:CccPick` / `:CccConvert` | Color picker / convert color format (ccc.nvim) |
| `:Octo` | (see Git) |
| `:Markview` toggle | Rendered markdown preview (markview.nvim) |
| `:TailwindSort` etc. | tailwind-tools utilities |
| `<leader>wtc` / `wts` / `wtd` | Git worktree create / switch / delete |
| `<leader>M` | (see fzf-lua resume) |
| `<leader>e` | **Native 0.13 directory browser** (`nvim-dir`, netrw replacement) — trial; compare with `:NvimTreeToggle` (nvim-tree still installed, phase-2 decides) |
| smartcolumn | Auto color-column at 80/120/150 per window (no keys) |
| snacks.indent | Indent guides (no keys) — indent-blankline deleted 2026-09-04, snacks replaces it |
| noice + nvim-notify | Cmdline/messages/notifications UI (no keys) |
| statuscol.nvim | Status column: line numbers + fold column + signs (restored 2026-09-08 — snacks.statuscolumn didn't work out) |
| scrollbar | Minimap-ish scrollbar with search/git/diagnostic marks |

## Rails / Elixir — projectionist *(keys stay identical)*

| Keys / Command | Action |
|---|---|
| `:A` / `:AS` / `:AV` / `:AT` | Jump to alternate file (model↔spec, controller↔spec, lib↔test) same window / split / vsplit / tab |
| `:Econtroller` `:Emodel` `:Espec` … | Rails navigation commands |
| `:Service` `:Query` | Custom projections for app/services, app/queries (with templates) |
| `:Generate` / `:Rake` / `:Runner` | vim-rails project commands |
| `<leader>a` (coc) | (see Code intel) |

Spec templates auto-scaffold RSpec describe blocks; Elixir `mix.exs` projects get lib↔test alternates + `mix test` dispatch.

## System keyboard notes *(audited 2026-09-04 — KEYMAP-COLLISIONS.md §H–§L)*

- **tmux prefix `C-a` swallows nvim's `C-a`** (increment number / beginning-of-line): inside tmux press `C-a C-a` (works instantly thanks to `escape-time 0`) or use `0`/`Home` in nvim.
- **tmux binds bare `<Tab>` as pane picker** (`bind-key -n tab`) — it hijacks `<Tab>` inside nvim (completion select/jump) today; fix queued in MIGRATION.md phase 2 (send-keys Tab when `$is_vim`).
- **Karabiner swaps left_cmd ↔ left_option on the Apple keyboard only** (`karabiner.json:38-45`) — on that board, skhd binds respond to the *opposite* physical modifier vs the built-in/external boards. Muscle-memory trap, intentional, KEEP.
- Karabiner historically dropped F1/F2 brightness remaps and added the cmd/opt swap + fn-keys passthrough (see audit §K for the 2023→now delta).

## Image rendering *(nvim 0.13 nightly `vim.ui.img` era)*

| Context | Path | Status |
|---|---|---|
| nvim in kitty, **no tmux** | native `vim.ui.img` — `:checkhealth vim.images` passes; API: `vim.ui.img.set(blob, {width, height, row, col}) → id`, `get(id)`, `del(math.huge)` clears all | ✅ |
| nvim **inside tmux** (normal case) | **snacks.image only** (wraps kitty protocol in tmux passthrough; powers fzf-lua previews via `snacks_image`) | ✅ |
| nvim inside tmux, native `vim.ui.img` | ❌ false negative — nightly's `vim.tty` sends raw kitty APC without the `Ptmux` wrap, tmux swallows it | until nvim adds it |

- tmux side is already correct: `allow-passthrough on` + kitty `terminal-features` RGB (tmux.conf:3,46).
- The `:checkhealth vim.images` "not supported" inside tmux is a **known false negative**, not a config problem. Test in a plain kitty window to confirm the stack.
- Example/demo API code: <https://github.com/FractalCodeRicardo/dev-config/tree/master/nvim/lua/my/vim-img>

## Vim common (timeless)

- Write unicode: `"\u{HEXCODE}"` in strings, or `<C-v>u` + hexcode.
- `:call dein#update()` updates plugins **today** → becomes **`vim.pack.update()`** after migration (nvim 0.12 built-in manager — no lazy.nvim, user decision 2026-09-04).
- `:h <topic>` / `K` in help buffers.
