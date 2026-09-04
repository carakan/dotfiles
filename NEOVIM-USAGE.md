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
| `<leader>f0`–`f9` | Set fold level |
| `<Leader>=` | Equalize window sizes |
| `<C-w>o` | Zoom current window (toggle with same key) |
| `<C-w>` `+`/`-`/`=` | Resize windows |
| `zh` / `zl` | Horizontal scroll |
| `<C-h><C-j><C-k><C-l>` | Navigate splits **and tmux panes** seamlessly (vim-tmux-navigator) — ⚠️ **broken today**: `vimrc.local:155-158` overrides with plain window-moves; restored in migration per KEYMAP-COLLISIONS.md A.1 |
| `<leader>ew` / `es` / `ev` / `et` | Edit file relative to current one (same window / split / vsplit / tab) |
| `Q` | Pick a buffer to close (close-buffers menu) |

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
| `<leader>a` | Code action |
| `<space>y` / `<space>h` | Yank list (coc-yank) *(migrates → fzf-lua registers; slot kept)* |
| `:CocCommand` | Run any coc command |

> `<leader>a` conflict note (MIGRATION.md §4d): also bound to treesitter swap-parameter. One of them moves during phase 2 — decision recorded in MIGRATION.md.

## Diagnostics & formatting — ALE *(keys stay identical: nvim-lint + conform.nvim take the same slots)*

| Keys | Action |
|---|---|
| `]a` / `[a` | Next / previous error (wrapped) |
| `<leader>f` | Format / auto-fix current buffer |

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
| `:Neogit` | Full git UI (kitty graph) |
| `:Octo` | GitHub PRs/issues from nvim (picker: fzf-lua) |

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
| `<leader>a` / `<leader>A` | Swap parameter with next / previous *(owner under review — see conflict note)* |
| `gnn` `grn` `grc` `grm` | Incremental selection: start / expand node / expand scope / shrink |
| `cs`/`ds`/`ys`/`S` | Surround — change / delete / add / visual-add (nvim-surround; see examples below) |
| `gS` / `gJ` | Split one-liner into lines / join block to one line (splitjoin) |
| `ci(`/`caq`/… | Targets.vim extended text objects (quotes, parens, separators) |
| `f`/`t`/`T` | Jump-highlight for find/till (qs + hlslens lens below) |
| `n` / `N` | Search with virtual lens showing `[count] ▲▼` (hlslens) |
| `:Inspect` | Show treesitter highlight captures under cursor *(native; replaces old `<leader>is`)* |
| `<C-M-n>` | Multicursor: start / add next match (repeat to grow); `<C-M-p>` previous; `:MCstart`, `:MCvisual`, `:MCclear` |

### Surround examples (nvim-surround — same UX as tpope/vim-surround)

`cs"'` → change `"…"` to `'…'` · `ysiw]` → wrap word in `[…]` · `ds"` → remove quotes ·
visual `S<p class="x">` → wrap selection in tag.

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
| nvim-tree | File tree — **no toggle bound today**; `<leader>e` to be defined in phase 2 (MIGRATION.md §9) |
| smartcolumn | Auto color-column at 80/120/150 per window (no keys) |
| indent-blankline + snacks.indent | Indent guides (no keys) |
| noice + nvim-notify | Cmdline/messages/notifications UI (no keys) |
| statuscol / scrollbar | Sign column segments + minimap-ish scrollbar with search/git/diag marks |

## Rails / Elixir — projectionist *(keys stay identical)*

| Keys / Command | Action |
|---|---|
| `:A` / `:AS` / `:AV` / `:AT` | Jump to alternate file (model↔spec, controller↔spec, lib↔test) same window / split / vsplit / tab |
| `:Econtroller` `:Emodel` `:Espec` … | Rails navigation commands |
| `:Service` `:Query` | Custom projections for app/services, app/queries (with templates) |
| `:Generate` / `:Rake` / `:Runner` | vim-rails project commands |
| `<leader>a` (coc) | (see Code intel) |

Spec templates auto-scaffold RSpec describe blocks; Elixir `mix.exs` projects get lib↔test alternates + `mix test` dispatch.

## Vim common (timeless)

- Write unicode: `"\u{HEXCODE}"` in strings, or `<C-v>u` + hexcode.
- `:call dein#update()` updates plugins **today** → becomes `:Lazy update` after migration.
- `:h <topic>` / `K` in help buffers.
