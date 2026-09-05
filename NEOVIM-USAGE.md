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
| `<leader>a` / `<leader>A` | Swap parameter with next / previous *(sole owner confirmed in step-0)* |
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

## System keyboard notes *(audited 2026-09-04 — KEYMAP-COLLISIONS.md §H–§L)*

- **tmux prefix `C-a` swallows nvim's `C-a`** (increment number / beginning-of-line): inside tmux press `C-a C-a` (works instantly thanks to `escape-time 0`) or use `0`/`Home` in nvim.
- **tmux binds bare `<Tab>` as pane picker** (`bind-key -n tab`) — it hijacks `<Tab>` inside nvim (completion select/jump) today; fix queued in MIGRATION.md phase 2 (send-keys Tab when `$is_vim`).
- **Karabiner swaps left_cmd ↔ left_option on the Apple keyboard only** (`karabiner.json:38-45`) — on that board, skhd binds respond to the *opposite* physical modifier vs the built-in/external boards. Muscle-memory trap, intentional, KEEP.
- Karabiner historically dropped F1/F2 brightness remaps and added the cmd/opt swap + fn-keys passthrough (see audit §K for the 2023→now delta).

## Vim common (timeless)

- Write unicode: `"\u{HEXCODE}"` in strings, or `<C-v>u` + hexcode.
- `:call dein#update()` updates plugins **today** → becomes **`vim.pack.update()`** after migration (nvim 0.12 built-in manager — no lazy.nvim, user decision 2026-09-04).
- `:h <topic>` / `K` in help buffers.
