# Neovim Migration — living plan & tracker

> **Contract:** this file is the single source of truth for the migration.
> The user updates checkboxes/notes anytime; the agent MUST re-read this file
> before doing any migration work. Nothing gets built that isn't a checkbox
> here. Companion artifacts:
> [`legacy-lua-extracted.lua`](./legacy-lua-extracted.lua) (all current Lua,
> syntax-checked) · [`NEOVIM-USAGE.md`](../../NEOVIM-USAGE.md) (repo root —
> keymap contract: plugins may be swapped, keys must keep working).

**Status:** 📋 planned — phase 0 done · **Last updated:** 2026-09-04

---

## 0. Goals (priority order, user's words)

1. All-Lua config, easy to tweak
2. Delete outdated/useless addons **first** — AI era: user won't write much code,
   will **review/debug AI-generated code**
3. Migrate to a better package manager (dein.vim → lazy.nvim)
4. AI-first setup: code completion, **local models**, integration with
   **opencode** and **omp** (oh-my-pi) review mode

---

## 1. Decisions log (user answers recorded here)

| Date | Topic | Decision |
|------|-------|----------|
| 2026-09-04 | OMP meaning | **oh-my-pi** — the coding agent at omp.sh (`omp` CLI v18.1.10 already installed). Goal: integrate its **review mode** with nvim (docs at <https://omp.sh/docs> are JS-rendered — read during phase 4) |
| 2026-09-04 | `carakan/pmv.vim`, `carakan/lens.vim` | Find modern lua alternatives; lua port only if nothing exists |
| 2026-09-04 | dash.vim | **KEEP** |
| 2026-09-04 | Legacy vimscript plugins | Q: will migration keep ancient vimscript plugins working in neovim? **A: YES** — nvim 0.12 runs legacy vimscript plugins natively (only `vim9script` is unsupported). Deletion is a choice, never forced. See §4 note |
| 2026-09-04 | Typing-assist plugins | **DELETE** (emmet, closetag, endwise, …). Where a maintained lua replacement exists, swap it in; otherwise just delete. Purge list in §4c |
| 2026-09-04 | Usage doc | `USAGE.md` renamed → **`NEOVIM-USAGE.md`** (repo root), refreshed with all current plugins + keymaps. It doubles as the keymap contract: swapping a plugin is fine, its shortcuts are not |
| 2026-09-04 | Local AI models | **NO research, NO benchmark** (user directive). A server already runs at **`http://127.0.0.1:8080/v1`** (toshLLM + llama.cpp, OpenAI-compatible). Migration connects THAT for **autocomplete** (FIM) |
| 2026-09-04 | Keymap collision audit | Dispatched to M3 agent → artifact: [`KEYMAP-COLLISIONS.md`](./KEYMAP-COLLISIONS.md). Scope: ALL global mappings across the 4 vimscript files + plugin defaults; each collision gets a verdict tied to §4 disposition (plugin kept → fix, plugin deleted → auto-resolves) |

---

## 2. Current state (verified 2026-09-04)

```
nvim binary:      v0.12.5 (modern — only the config is ancient)
~/.config/nvim →  ~/.vim                    (REAL dir: dein bundles + sessions)
~/.config/nvim/init.vim → ~/.vimrc → ~/.supra-vim/.vimrc   (spf13 fork, vimscript)
~/.vimrc          → ~/.supra-vim/.vimrc     (519 lines + .before/.bundles scaffolding)
~/.vimrc.local    → dotfiles:packages/vim/vimrc.local      (1341 lines, ALL the Lua)
~/.vimrc.bundles.local → packages/vim/vimrc.bundles.local (dein manifest, ~70 plugins)
~/.vimrc.before.local  → packages/vim/vimrc.before.local
coc-settings.json → packages/coc/coc.json   (bun runtime, 25 coc extensions)
omp CLI:          /usr/local/bin/omp  (v18.1.10)
opencode CLI:     /usr/local/bin/opencode
ollama:           NOT installed (phase 4 gate)
```

**Findings that shaped the plan:**
- Package manager is **dein.vim** (spf13 scaffolding), plugins under `~/.vim/bundle/repos/`
- ~30 plugins are already modern Lua (snacks, flash, noice, fzf-lua, gitsigns,
  neogit, octo, bufferline w/ heavy custom colors, lualine, statuscol, …) — the
  plan ports them, doesn't replace them
- treesitter configured with ~45 parsers but `highlight = false` — legacy syntax
  plugins are doing the highlighting today
- coc.nvim + ALE run simultaneously (double completion/lint stack)
- `<leader>a` is double-bound (treesitter swap-parameter + coc-codeaction) — decide once
- `vimrc.local:90` hardcodes `stree` to ruby 2.7.8 asdf path — use shims
- All Lua extracted to [`legacy-lua-extracted.lua`](./legacy-lua-extracted.lua) (731 lines)

---

## 3. Architecture decisions

- [x] **D1 Framework: hand-rolled modular** (`init.lua` + `lua/config/` + `lua/plugins/`, one file per plugin). Rejected LazyVim/kickstart: user's heavy customizations (own colorscheme fork, custom bufferline/lualine, fzf-lua everywhere) would fight any distro
- [x] **D2 Manager: dein.vim → lazy.nvim**
- [x] **D3 LSP: nvim 0.12 native** `vim.lsp.config` / `lsp.enable`; servers via **Homebrew** (dotfiles philosophy) — EXCEPT `ruby-lsp`/`lexical`: per-project via Bundler (7 asdf rubies; a brew-pinned ruby-lsp mis-serves all but one)
- [x] **D4 Completion: coc.nvim → blink.cmp** (+ friendly-snippets; test a Ruby block snippet end-to-end)
- [x] **D5 Lint/format: ALE → nvim-lint + conform.nvim**, porting existing linter/fixer tables. ALE's `tsserver`/`typecheck`/`vls` entries move to LSP diagnostics, NOT nvim-lint
- [x] **D6 AI stack: opencode.nvim primary** (existing workflow, in-editor accept/reject); **omp review-mode integration**; **local autocomplete via existing toshLLM+llama.cpp server at `http://127.0.0.1:8080/v1`** (user directive: no research, no benchmark). codecompanion.nvim optional via same endpoint. llama.vim & mcphub: cut
- [x] **D7 Treesitter: enable highlight** + migrate to new main-branch API (extracted block is legacy API — see R3/R4)
- [x] **D8 Parallel run: `NVIM_APPNAME=nvim2`** → `~/.config/nvim2`, daily nvim untouched until phase 5
- [x] **D9 Teardown via dotbot** `install.conf.yaml` (NOT stow) — runbook in §7

---

## 4. Plugin disposition

> **Note (user answer):** legacy vimscript plugins keep working in nvim 0.12.
> "Keep as vimscript" is a valid outcome — zero-cost, zero-risk. Lua swaps are
> done only where a maintained replacement exists AND the plugin earns its place.

### a) DELETE — dead weight / superseded

- [ ] python-mode, yssource/python.vim, python_match.vim, pythoncomplete (python group — declared useless)
- [ ] UltiSnips (already disabled `'if':0`) + vim-snippets
- [ ] yats.vim, vim-javascript, elzr/vim-json, html5.vim, css3-syntax, scss-syntax, vim-haml, vim-yaml (treesitter covers syntax)
- [ ] keith/rspec.vim (pure syntax, treesitter covers)
- [ ] plasticboy/vim-markdown (markview.nvim covers)
- [ ] vim-over (obsolete)
- [ ] wildfire.vim (covered by targets/flash/textobjects)
- [ ] hexokinase (unmaintained + Go build step; ccc.nvim covers colors)
- [ ] nvim-treesitter/playground (archived upstream)
- [ ] vim-numbertoggle
- [ ] vim-gutentags + atags custom command (LSP document symbols + fzf-lua `btags`)
- [ ] kana textobj set: textobj-user, textobj-indent, textobj-function, jasonlong/vim-textobj-css (treesitter textobjects already mapped: ak/ik/ac/ic/af/if/aa/ia)
- [ ] reedes writing group: wordy, litecorrect, textobj-sentence, textobj-quote
- [ ] coc-vetur (Vue2-dead), coc-grammarly, coc-word; tslint/vls references
- [ ] `vimade` config in vimrc.local:968 — plugin not in bundles.local; verify where it loads → expect DELETE (unmaintained)

### b) DELETE — typing-assist purge (user: "I don't type code much")

- [ ] emmet-vim (markup expansion — explicitly deleted)
- [ ] vim-closetag (auto-closing tags while typing)
- [ ] vim-endwise (auto `end` for ruby blocks — AI writes complete blocks)
- [ ] vim-sort-motion (`:sort` built-in suffices)
- [ ] auto-pairs → **replace with nvim-autopairs (lua)** — pairing still helps when tweaking AI output *(swap, not delete)*

**Optional lua swaps (decide during phase 2, not urgent):**
- [ ] targets.vim → mini.ai (only if mini.ai's API is preferred; targets works fine as vimscript)
- [ ] vim-abolish → coerce.nvim (case coercion when renaming AI code; abolish works fine as vimscript)
- [ ] splitjoin.vim — keep as vimscript (no maintained lua port; useful when collapsing/expanding AI output)

### c) KEEP (port config as-is)

- [ ] `carakan/new-railscasts-theme` (user's own colorscheme fork — centerpiece)
- [ ] vim-test + tslime.vim (tmux test runner — core of the review workflow)
- [ ] tpope: vim-dadbod + vim-dadbod-ui + vim-dadbod-completion, vim-projectionist (Rails/Ember/Elixir heuristics — big block, port carefully), vim-rails, vim-ruby, vim-rhubarb, vim-repeat, vim-abolish*, vim-obsession + vim-prosession, vim-commentary/nerdcommenter
- [ ] vim-elixir (treesitter highlights it but elixir ftplugin/indent still owned here)
- [ ] vim-tmux-navigator, vim-rooter, vim-automkdir, close-buffers, conflict-marker, targets.vim*, splitjoin.vim*, vim-closetag→DELETED, lifepillar/pgsql.vim, dash.vim, vim-hexokinase→DELETED
- [ ] Modern Lua natives (port setup from extracted file): snacks, flash, noice, nvim-notify, fzf-lua, gitsigns, diffview, neogit, octo, gitlinker, bufferline, lualine, statuscol, scrollbar, smartcolumn, ibl, nvim-surround, nvim-tree, nvim-web-devicons (custom icons block), markview, multicursor, worktrees, ccc, gx, tailwind-tools, hlslens, nvim-bqf, nvim-recorder (commented — decide), force-cul (commented — decide), friendly-snippets, plenary, nui, promise-async
- [ ] **snacks overlaps:** explicitly disable snacks' session/dashboard modules (prosession/obsession own sessions)

### d) REPLACE / ADAPT

- [ ] `carakan/pmv.vim` → find modern lua alternative; port to lua only if none exists
- [ ] `carakan/lens.vim` → find modern lua alternative; port to lua only if none exists
- [ ] vim-dadbod-completion → needs **blink.compat** source (or dadbod omnifunc) or SQL completion silently dies
- [ ] coc-yank (`<space>y` / `<space>h` yank history) → successor: fzf-lua `registers` (add keymap to phase 3 checklist)
- [ ] `<leader>a` conflict: treesitter swap-parameter vs code-action — pick one (proposal: swap stays, code-action moves)

---

## 5. AI-first stack (phase 4 detail)

- [ ] **Local autocomplete (mandated):** wire `http://127.0.0.1:8080/v1` (toshLLM + llama.cpp, OpenAI-compatible) as a blink.cmp completion source (FIM via `/v1/completions`). No ollama install, no benchmark — the server exists (user directive 2026-09-04)
- [ ] **opencode.nvim** — primary agent surface: context injection, prompt with LSP context, accept/reject edits in-editor
- [ ] **omp (oh-my-pi) review-mode integration** — read <https://omp.sh/docs> (JS-rendered; fetch via agent browser or `omp` CLI rpc modes) and design the nvim surface: likely review comments ↔ buffer annotations
- [ ] codecompanion.nvim — *optional*: same local endpoint works as an OpenAI-compatible adapter if chat/inline actions are wanted later
- [ ] Snippet/lint sanity after coc removal: snippets via blink + friendly-snippets (coc-settings.json referenced UltiSnips — that path is gone)

---

## 6. Phases

- [x] **Phase 0 — Extract legacy Lua** → [`legacy-lua-extracted.lua`](./legacy-lua-extracted.lua) (731 lines, luajit syntax-checked) · 2026-09-04
- [ ] **Phase 1 — Scaffold**: `packages/nvim/{init.lua,lua/config/{options,keymaps,autocmds,lazy}.lua,lua/plugins/*.lua}`; lazy.nvim bootstrap; run via `NVIM_APPNAME=nvim2`; port options/keymaps from the 3 vimscript files; theme + UI plugins (bufferline colors, lualine, statuscol, scrollbar, noice, snacks); treesitter new API + capture-mapping pass for railscasts (R3)
- [ ] **Phase 2 — Fuzzy + git + editing**: fzf-lua (all 13 keymaps from extraction §1), gitsigns/diffview/neogit/octo/gitlinker, sessions (obsession/prosession, snacks modules off), mini/nvim-autopairs decisions from §4b. **Resolve KEYMAP-COLLISIONS.md verdicts**: A.1 `<C-h/j/k/l>` tmux-nav restore, A.x `[c/]c` hunks→`]h/[h`, B flash-visual `S` disable, C/D stale + orphan deletions (`<leader>y`, `<Leader>ct`, `<leader>tt`, vimade/matchup/qs/hexokinase/atags blocks), `<leader>a` → swap keeps key, code-action moves (§4d)
- [ ] **Phase 3 — LSP big-bang**: native LSP + blink.cmp + conform/nvim-lint land together; coc + ALE + 25 node extensions die. Full keymap checklist below
- [ ] **Phase 4 — AI**: connect local toshLLM endpoint to blink.cmp for autocomplete; opencode.nvim; omp review-mode integration
- [ ] **Phase 5 — Verification & teardown**: run §6 checklist → dotbot cutover (§7) → delete `~/.supra-vim`, `~/.vimrc*` links, `packages/vim/`, dein bundles. **Tag repo + `tar czf ~/backups/supra-vim-$(date +%F).tgz ~/.supra-vim ~/.vimrc` BEFORE teardown**

### Phase-3 verification checklist

- [ ] `gd` `gy` `gi` `gr` `K` `<leader>rn` `[c` `]c` (definition/type/impl/refs/hover/rename/diag-nav)
- [ ] `<c-space>` completion trigger, `<TAB>` select/expand, `<C-n>/<C-p>` cycle
- [ ] Ruby block snippet expands + jumps
- [ ] `<leader>f` (format/conform), `<leader>a` (resolved conflict from §4d)
- [ ] tslime round-trip: `<leader>tn` sends to tmux pane, test runs
- [ ] dadbod connects to postgresql@18 (`:DB` + dbui), SQL completion via blink.compat
- [ ] fzf-lua: `<c-p>` `<c-t>` `<c-c>` `<leader>ss/sh/sw/sW/sl/ag/m/M` all fire
- [ ] session: `:Prosession` resume + `:Obsession` save
- [ ] colors: railscasts + treesitter highlight look right (R3 pass)

---

## 7. Teardown runbook (phase 5 only — do NOT run early)

`install.conf.yaml` today (lines 35–43):

```yaml
    # ── vim / neovim ────────────────────────────────────────
    ~/.vimrc.before.local: packages/vim/vimrc.before.local
    ~/.vimrc.bundles.local: packages/vim/vimrc.bundles.local
    ~/.vimrc.local: packages/vim/vimrc.local
    ~/.config/nvim:
        create: true
        path: ~/.vim
    ~/.config/nvim/init.vim: ~/.vimrc
    ~/.config/nvim/coc-settings.json: packages/coc/coc.json
```

- [ ] Replace that block with: `~/.config/nvim: {path: packages/nvim}` (+ optionally `~/.config/nvim2` cleanup)
- [ ] Manually `rm` supra-created symlinks NOT managed by dotbot: `~/.vimrc`, `~/.vimrc.before`, `~/.vimrc.bundles` (all → `~/.supra-vim/…`)
- [ ] `rm -rf ~/.supra-vim ~/.vimrc.fork 2>/dev/null` (no fork files exist today)
- [ ] `rm -rf ~/.vim/bundle` (dein repos, ~75 plugin trees) — keep `~/.vim/session*` until satisfied, then move to `~/.local/state/nvim/`-equivalent for nvim2/nvim
- [ ] Delete `packages/vim/` (3 files) and `packages/coc/` from repo; run `./install`; dotbot `clean` sweeps dead links
- [ ] Old config is untouched until this moment = full rollback available

---

## 8. Risks

- **R1 — AI stack design**: ~~Intel iMac = CPU-only local models, benchmark gate~~ **RESOLVED 2026-09-04**: a toshLLM + llama.cpp server already runs at `http://127.0.0.1:8080/v1` — migration consumes it as-is (user: no research, no benchmark). Only unknown is FIM latency on Intel CPU; note tokens/s in this file when first wired
- **R2 — Parallel-run mechanism**: `~/.config/nvim` is symlinked to `~/.vim` until teardown day → new config MUST live at `~/.config/nvim2` via `NVIM_APPNAME=nvim2`
- **R3 — Colors break first**: railscasts fork styles legacy groups (`Keyword`, `String`); treesitter emits `@keyword`/`@string` captures. Budget a capture-mapping pass in phase 1 — the "migration looks broken" moment is planned for
- **R4 — treesitter main-branch rewrite** drops `incremental_selection` (gnn/grn/grc/grm), `indent`, `playground` modules; textobjects is a separate repo with its own rewrite; `ensure_installed` becomes explicit installs; `comment` parser removed upstream. Port each module deliberately, not wholesale
- **R5 — blink + noice/notify float styling**: custom `winhighlight` (vimrc.local:897) needs a pass against blink menus (cosmetic, noticed first)

---

## 9. Open items

- [ ] Where does `vimade` actually load from? (§4a)
- [ ] nvim-recorder & force-cul: commented-out in setup — port or drop?
- [ ] omp review-mode docs reading (JS page) — do in phase 4
- [ ] `<leader>a` final owner + ALL other collisions: resolve per [`KEYMAP-COLLISIONS.md`](./KEYMAP-COLLISIONS.md) audit (keep plugin → fix mapping; deleted plugin → auto-resolves)
- [ ] mini.ai / coerce.nvim optional swaps (§4b)
- [ ] nvim-tree has NO toggle keymap today → define `<leader>e` in phase 2 (discovered writing NEOVIM-USAGE.md)
- [ ] Stale USAGE.md entries already dropped in NEOVIM-USAGE.md: vim-grepper (fzf-lua took over `<leader>ag`), ember-tools, zoomwintab, vim-select-replace, sort-motion (deleted) — verify none are silently expected during phase 2 keymap port
