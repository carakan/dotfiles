# Keymap Collision Audit

Generated: 2026-09-04 · auditor: M3
inputs:
- `/Users/carakan/.dotfiles/packages/vim/vimrc.local` (1341 lines)
- `/Users/carakan/.dotfiles/packages/vim/vimrc.before.local` (33 lines)
- `/Users/carakan/.dotfiles/packages/vim/vimrc.bundles.local` (86 lines, dein manifest)
- `/Users/carakan/.supra-vim/.vimrc` (519 lines, spf13 base)
- `/Users/carakan/.supra-vim/.vimrc.bundles` (152 lines, spf13 bundle groups)
- `/Users/carakan/.dotfiles/NEOVIM-USAGE.md` (keymap contract)
- `/Users/carakan/.dotfiles/packages/nvim/MIGRATION.md` (§4 disposition)

## Load order (verified)

Per `/Users/carakan/.supra-vim/.vimrc:5-7, 11-13, 510-512, 516-518` and `/Users/carakan/.supra-vim/.vimrc.bundles:142-145`:

1. `~/.vimrc.before` → `vimrc.before.local` (sets `g:spf13_leader = ' '` → `<leader>` = **space**)
2. `~/.vimrc.bundles` (spf13 base — sources `~/.vimrc.bundles.local` at line 142, then `~/.vimrc.bundles.fork` if exists)
3. entry `.vimrc` continues — keymaps (lines 144-303), `~/.vimrc.fork` if exists, then **sourced last**: `~/.vimrc.local`

**Conclusion: `vimrc.local` WINS on every same-key redefinition.** Plugin defaults
loaded via `dein#add` run during bundle source (between steps 2 and 3) — they
are OVERRIDDEN by `vimrc.local`'s later maps. The lua heredoc at `vimrc.local:252-945`
runs in source order, so any `require(...).setup{}` inside it precedes any
vimscript maps that follow line 945.

`<leader>` is verified as **space** (vimrc.before.local:16 — `let g:spf13_leader = ' '`).
spf13 default is `,` (`.vimrc:151`) but is overridden by the local.

---

## Verdict legend

- **FIX** — current behavior is wrong (silently broken or duplicates a deleted
  plugin's binding); action required during migration.
- **DISCARD** — bound to a plugin on MIGRATION §4a/§4b's DELETE list; the
  collision auto-resolves when that plugin is removed.
- **DECIDE** — competing active owners, no load-order winner; needs an explicit
  owner choice before migration lands.
- **AUTO-RESOLVE** — collision exists in source but later-loaded mapping already
  wins; no code change needed, just document.
- **UNVERIFIED** — could not be confirmed from inputs alone (e.g. requires runtime).

---

## A. Hard collisions (same key + mode, competing active mappings)

| Key(s) | Mode | Competing owners (file:line) | Winner today (and why) | MIGRATION.md §4 disposition | Verdict | Proposal |
|---|---|---|---|---|---|---|
| `<C-h>` | n | (a) `vim-tmux-navigator` default `<C-h>` Plug (loaded via `vimrc.bundles` line 53 — `christoomey/vim-tmux-navigator`) · (b) `.vimrc:186` `map <C-H> <C-W>h<C-W>_` (maximize) · (c) `vimrc.local:155` `nnoremap <C-H> <C-W><C-H>` (plain) | `vimrc.local` (later source). NB: `<C-h>` and `<C-H>` are the **same Vim key code** — vim normalizes Ctrl+shift state. | KEEP tmux-navigator (§4c). | **FIX** | In `lua/config/keymaps.lua` (phase 2) re-map `<C-h/j/k/l>` to **call vim-tmux-navigator's `<Plug>`** so both panes and splits work; or `nnoremap <C-h> <C-W>h` and let tmux-navigator's autocmd/wrap handle the rest. The current setup silently kills tmux nav — NEOVIM-USAGE.md claims it works. |
| `<C-j>` | n | (a) `vim-tmux-navigator` `<C-j>` · (b) `.vimrc:183` `map <C-J> <C-W>j<C-W>_` (maximize) · (c) `vimrc.local:156` `nnoremap <C-J> <C-W><C-J>` | `vimrc.local` (later). Same key-code collision as `<C-h>`. | KEEP tmux-navigator (§4c). | **FIX** | Same as `<C-h>` above. |
| `<C-k>` | n | (a) `vim-tmux-navigator` `<C-k>` · (b) `.vimrc:184` `map <C-K> <C-W>k<C-W>_` (maximize) · (c) `vimrc.local:157` `nnoremap <C-K> <C-W><C-K>` | `vimrc.local` (later). | KEEP tmux-navigator (§4c). | **FIX** | Same. Note: `<C-K>` collides with digraph input (commented in `.vimrc:178` — `g:spf13_no_easyWindows` opt-out). |
| `<C-l>` | n | (a) `vim-tmux-navigator` `<C-l>` · (b) `.vimrc:185` `map <C-L> <C-W>l<C-W>_` (maximize) · (c) `vimrc.local:158` `nnoremap <C-L> <C-W><C-L>` | `vimrc.local` (later). | KEEP tmux-navigator (§4c). | **FIX** | Same. |
| `<leader>a` | n | (a) treesitter swap_parameter `['<leader>a'] = '@parameter.inner'` (`vimrc.local:671` — inside lua block) · (b) `vimrc.local:1043` `nmap <leader>a <Plug>(coc-codeaction)` | `vimrc.local:1043` (later in same source). | DEFERRED — §4d: "pick one (proposal: swap stays, code-action moves)". | **DECIDE** | Honor §4d: keep treesitter swap on `<leader>a` / `<leader>A`; remap coc code-action to `<leader>ca` (or wherever blink.cmp's native LSP code-action lands in phase 3). |
| `<leader>a` | v | (a) treesitter swap (visual is unaffected — swap is normal-mode-only per nvim-treesitter-textobjects `swap_next` keymaps) · (b) `vimrc.local:1042` `vmap <leader>a <Plug>(coc-codeaction)` | `vimrc.local:1042` — coc wins for visual too. | §4d same decision. | **DECIDE** | If swap wins: drop `vmap <leader>a` line. If code-action wins: drop treesitter swap config. |
| `[c` | n | (a) gitsigns default `<Plug>(gitgsigns_prev_hunk)` (`lewis6991/gitsigns.nvim`, KEEP per §4c — loaded at `vimrc.bundles.local:41`) · (b) `vimrc.local:1033` `nmap <silent> [c <Plug>(coc-diagnostic-prev)` | `vimrc.local:1033` (later source). | Both KEPT (§4c). | **FIX** | Phase 3 replaces coc with native LSP; keep `[c`/`]c` for **diagnostics**. Bind gitsigns hunk nav explicitly (e.g. `]h` / `[h` or gitsigns' default `<leader>hu/hs/hr` already works). Document in phase-3 checklist. |
| `]c` | n | (a) gitsigns default next_hunk · (b) `vimrc.local:1034` `nmap <silent> ]c <Plug>(coc-diagnostic-next)` | `vimrc.local:1034`. | Both KEPT. | **FIX** | Same as `[c`. |

---

## B. Plugin-default collisions (no explicit map needed)

| Key(s) | Mode | Competing owners | Winner today | MIGRATION.md §4 disposition | Verdict | Proposal |
|---|---|---|---|---|---|---|
| `s` | n / v / o | (a) vim built-in `s` = `cl` (normal/visual), substitution (visual) · (b) flash.nvim default (`vimrc.local:906` — `require('flash').setup({})` provides `s` 1-char jump) | flash.nvim (loaded via lua block). | KEEP flash (§4c). | **AUTO-RESOLVE** | Documented in NEOVIM-USAGE.md line 117. No change. |
| `S` | n / v | (a) vim built-in `S` = `cc` (normal), nvim-surround `S` wrap-selection (visual) — nvim-surround setup at `vimrc.local:254` · (b) flash.nvim default `S` 2-char jump (visual) | flash.nvim (line 906 loaded **after** nvim-surround at line 254 — later `require` wins for visual `S`). | KEEP both (§4c). | **FIX** | flash.nvim config accepts `modes = { norm = ..., vis = false }` (or similar) to free visual `S` for nvim-surround wrap. Or set flash `S` to a different key (`<leader>S`?). Verify flash.nvim docs in phase 1. |
| `gx` | n | (a) nvim 0.12 built-in `gx` (opens URL under cursor) · (b) gx.nvim default `gx` + handlers (`vimrc.local:564-575` — `require('gx').setup({plugin=true, github=true, brewfile=true, package_json=true, search=true})`) | gx.nvim (provides `<Plug>(gx)` + default `gx` map; loaded after nvim core maps). | KEEP gx (§4c). | **AUTO-RESOLVE** | gx.nvim wins as intended. No change. |
| `<C-M-n>` / `<C-M-p>` | n | multicursor-nvim defaults (`vimrc.local:583` — `require('multicursor-nvim').setup({})`). No other binding. | multicursor (alone). | KEEP (§4c). | **AUTO-RESOLVE** | No change. Verify nvim 0.12 still recognises `<C-M-n>` as Alt-Ctrl-n (multicursor-nvim's documented key). |
| `<leader>h*` | n | gitsigns defaults: `<leader>hp` preview, `<leader>hb` blame, `<leader>hd` diff, `<leader>hs` stage, `<leader>hu` undo stage, `<leader>hr` reset (`vimrc.local:439` setup; defaults not overridden). | gitsigns alone (no conflict yet). | KEEP (§4c). | **AUTO-RESOLVE** | No conflict today, but `<leader>pd`/`pr` (vimrc.local:139-140) duplicate `<leader>hp` / `<leader>hr` semantics. After migration, prefer the user's mnemonic `<leader>p*` (preview/reset) and disable gitsigns defaults via `map_defaults = false` in setup, or pick one set. |
| `<leader>t*` | n | vim-test defaults (`vim-test/vim-test` loaded `vimrc.bundles.local:16`) typically use `<leader>tn/tf/ta/tl/tv` — same as explicit maps at `vimrc.local:172-176`. | Explicit maps (no real conflict, but redundant). | KEEP vim-test (§4c). | **AUTO-RESOLVE** | Identical targets — explicit maps and defaults reinforce each other. Fine. |

---

## C. Stale bindings (target plugin not loaded or being deleted)

| Key | Mode | Target | Evidence | Verdict |
|---|---|---|---|---|
| `<leader>y` | v | `:YankCode` (`vimrc.local:250` — `vmap <leader>y :YankCode<CR>`) | `yank-code` commented out: `vimrc.bundles.local:1` `" call dein#add('AaronLasseigne/yank-code')` | **FIX** — delete line. `<space>y` (`vimrc.local:1061`) is the live equivalent (coc-yank → fzf-lua `registers` per §4d). |
| `<leader>is` | n | `:TSHighlightCapturesUnderCursor` (`vimrc.local:966`) | `nvim-treesitter/playground` is on the §4a DELETE list ("archived upstream"). The command may still exist if treesitter main branch keeps it, but the playground module is gone. | **FIX** — NEOVIM-USAGE.md already replaced this with `:Inspect` (line 131). Drop the line in phase 1. |
| `<Leader>ct` | n | `:call atags#generate()` (`vimrc.local:198`) | `vim-easytags` is NOT in either manifest. `vim-gutentags` (loaded `vimrc.bundles.local` indirectly via spf13 `general`/`programming`? — actually only via `.vimrc.bundles:54`) is being deleted per §4a ("vim-gutentags + atags custom command"). | **FIX** — delete line. |
| `<leader>tt` | n | `:TagbarToggle` (`.vimrc:353`) | `majutsushi/tagbar` NOT in either manifest. The map is guarded by `if isdirectory(expand(...))` so it's a no-op today, but the dead line should be removed. | **FIX** — delete `.vimrc:353` and the guard. |

---

## D. Orphan config (g: vars set, plugin absent from manifests)

| Plugin | Config lines | Loaded? | Verdict |
|---|---|---|---|
| `vimade` | `vimrc.local:968-971` (`g:vimade = {...}`, `g:vimade.fadelevel`, `g:vimade.enablesigns`, `g:vimade.enablefocusfading`) | NOT in `vimrc.bundles.local` or spf13 `vimrc.bundles`. §4a says "expect DELETE (unmaintained)". | **DISCARD** — open item §9 row 1 already asks where it loads; it doesn't. Delete the block. |
| `vim-matchup` (`andymass/vim-matchup`) | `vimrc.local:991-994` (`g:matchup_matchparen_offscreen`, `g:matchup_matchparen_deferred`, `g:matchup_matchparen_hi_surround_always`, `:hi MatchParen`) | COMMENTED OUT in `.vimrc.bundles:25` (`" call dein#add('andymass/vim-matchup')`). vim's built-in matchparen + treesitter highlighter cover this. | **DISCARD** — delete `vimrc.local:991-994`. Keep the `:hi MatchParen` line if you want the styling; move it to a theme file or statusline group. |
| `quick-scope` (`unblevable/quick-scope`) | `vimrc.local:997` (`g:qs_highlight_on_keys = ['f', 't', 'T']`) | NOT in either manifest. | **DISCARD** — flash.nvim + hlslens cover this. Delete line. |
| `vim-hexokinase` (`RRethy/vim-hexokinase`) | `vimrc.local:973-989` (entire `g:Hexokinase_*` block) | LOADED (`vimrc.bundles.local:7`) — but §4a deletes hexokinase (unmaintained + Go build step; ccc.nvim covers colors). | **DISCARD** — delete `vimrc.local:973-989`. |
| `vim-easytags` (xolox) | `vimrc.local:198` (`atags#generate()`) | NOT loaded. | **DISCARD** — covered under C above. |
| `yank-code` (`AaronLasseigne/yank-code`) | `vimrc.local:250` (`:YankCode`) | NOT loaded (`vimrc.bundles.local:1` commented). | **DISCARD** — covered under C above. |
| `zoomwintab` | (not present in vimrc.local) | n/a | **n/a** — false-positive in the audit brief; no orphan code. |

---

## E. Behavior changes worth documenting

| Key(s) | Mode | What changed | Source | MIGRATION.md cross-ref |
|---|---|---|---|---|
| `s` | n / v / o | vim's `cl` / substitute → flash.nvim 1-char jump (type 1 char + label) | `vimrc.local:906` (flash.setup) | §4c KEEP flash. Documented in NEOVIM-USAGE.md:117. |
| `S` | n / v | vim's `cc` / nvim-surround `S` wrap (visual) → flash.nvim 2-char jump | `vimrc.local:254` + `:906` | See A row (`S` visual collision with nvim-surround). |
| `Q` | n | vim's Ex-mode (deprecated in nvim) → `:Bdelete menu` (close-buffers picker) | `vimrc.local:244` | §4c KEEP close-buffers. Documented in NEOVIM-USAGE.md:34. |
| `K` | n | vim's `!keyword` man-page lookup → LSP hover (`CocAction('doHover')` / `<SID>show_documentation()`) | `vimrc.local:1048-1056` | §4c KEEP coc (phase 3 → native LSP). Documented in NEOVIM-USAGE.md:67. |
| `<Up>` `<Down>` `<Left>` `<Right>` | n | → NOP (disabled) | `vimrc.local:43-46` | (no migration action — keep) |
| `0` `$` `^` `<Home>` `<End>` | n / o / v | → wrap-relative motion (`gj`/`gk` style) | `.vimrc:190-229` | (no migration action — keep; this is the spf13 contract) |
| `Y` | n | `yy` → `y$` (yank to EOL) | `.vimrc:233` | (no migration action — keep) |
| `<bs>` | n | → `<c-^>` (alternate buffer) | `vimrc.local:49` | (no migration action — keep) |
| `J` `K` | v | vim's `J` join → `:m '>+1<CR>gv=gv` (move lines) | `vimrc.local:208-209` | (no migration action — keep) |
| `<` `>` | v | vim's indent → `<gv` / `>gv` (keep selection) | `.vimrc:267-268` | (no migration action — keep) |
| `<Up>` `<Down>` | i (insert, coc pum visible) | vim's cursor move → `<C-n>`/`<C-p>` (cycle completion menu) | `vimrc.local:1065-1066` | Phase 3: port to blink.cmp behaviour. |
| `<TAB>` | i | → coc snippet jump / completion confirm / completion refresh | `vimrc.local:1069-1079` | Phase 3: same UX in blink.cmp (`<Tab>` mapping already standard). |
| `<CR>` | i (pum visible) | vim's newline → `<C-y>` (accept completion) | `.vimrc:376-377` (spf13, guarded by `g:spf13_map_cr_omni_complete` which is **not** set in `vimrc.before.local` → the map is **not** installed) | UNVERIFIED — spf13 code path skipped because `g:spf13_map_cr_omni_complete` doesn't exist. Insert `<CR>` behaves as default. Phase 3 port: blink.cmp's `<CR>` mapping. |

---

## F. Prefix/timeout hazards

| Prefix | Children | Risk | Mitigation |
|---|---|---|---|
| `<leader>f` | `<leader>f0..f9` (foldlevel, `.vimrc:236-245`) | `<leader>f` alone (vimrc.local:95 → `<Plug>(ale_fix)`) only fires after `timeoutlen` (default 1000ms). Fast typers may accidentally fold to level 0. Also: `<leader>fc` (`.vimrc:259` — git conflict marker) is a sibling prefix. | Phase 3: ALE → nvim-lint + conform; new conform key lives elsewhere (commonly `<leader>lf`). Remove the prefix conflict by giving fold its own key. |
| `<leader>m` | `<leader>mf` (markdownlint, `vimrc.local:1045`) | `<leader>m` (fzf-lua keymaps, `vimrc.local:232`) only fires after timeout. | Harmless — both targets are useful. Consider renaming the keymaps picker to `<leader>?k` or similar (the bare `<leader>?` is already taken by `:History`). |
| `<leader>s*` | `ss` `sh` `sw` `sW` `sl` (vimrc.local:218-224) | No bare `<leader>s` mapping exists today. Safe. | n/a |
| `<leader>w*` | `wtc` `wts` `wtd` (worktrees, `vimrc.local:931-935`) | No bare `<leader>w`. Safe. | n/a |
| `<leader>p*` | `pd` `pr` (gitsigns preview/reset, `vimrc.local:139-140`) | No bare `<leader>p`. Safe. | n/a |
| `<leader>g*` | `ga` `gl` (fzf-lua BCommits/Commits, `vimrc.local:230-231`) | No bare `<leader>g`. Safe. | n/a |
| `<C-c>` | `<C-c><C-c>` (tslime normal+visual, `vimrc.local:190-191`) and `<C-c>r` (tslime set vars, `vimrc.local:192`) | `<C-c>` alone (fzf-lua commands, `vimrc.local:215`) is the longest-no-match winner. Vim waits `timeoutlen` (1000ms) to disambiguate. Tslime's `<C-c><C-c>` requires a fast double-press; fzf-lua's `<C-c>` requires patience. **Behaviour depends on typing speed.** | Phase 2: fzf-lua commands is fine on `<C-c>`. For tslime, document the double-tap. Alternative: remap tslime to `<C-x><C-x>` so they can't fight. |
| `<leader>c` | `<Leader>ct` (atags — stale, see C) | Once `<leader>ct` is removed, the prefix is free. | Delete line in C. |
| `<leader>a` | `<leader>a` (single, swap or code-action) and `<leader>A` (swap_previous, `vimrc.local:674`) | No conflict — `a` vs `A` are different keys. | n/a (resolved by §4d decision) |

---

## G. Recommended final keymap table (the "after migration" state)

Keys below should be wired in `lua/config/keymaps.lua` (phase 1) and `lua/plugins/*.lua`
(per-plugin remaps). Listed in the order they appear in NEOVIM-USAGE.md for parity.

| Key | Mode | Action | Plugin owner (post-migration) |
|---|---|---|---|
| `<C-s>` | n / i / v | Save file | core (no plugin) |
| `<bs>` | n | Alternate buffer | core |
| `J` / `K` | v | Move selection down / up | core (custom vnoremap, port vimrc.local:208-209) |
| `<` / `>` | v | Indent, keep selection | core (port `.vimrc:267-268`) |
| `.` | v | Repeat last normal change | core (port `.vimrc:272`) |
| `j` `k` | n | Wrapped-line motion (`gj`/`gk`) | core (port `.vimrc:190-191`) |
| `0` `$` `^` `<Home>` `<End>` | n / o / v | Screen-line motion when wrap | core (port `.vimrc:214-229` `WrapRelativeMotion`) |
| `Y` | n | `y$` | core (port `.vimrc:233`) |
| `<leader>/` | n | Toggle search highlight | core (port `.vimrc:252-255`) |
| `<leader>fc` | n | Jump to next git conflict marker | `rhysd/conflict-marker.vim` (load via §4c) |
| `<leader>f0..f9` | n | Set foldlevel | core (move off `<leader>f` prefix — see F) |
| `<Leader>=` | n | Equalize windows | core (port `.vimrc:286`) |
| `<C-w>o` | n | Zoom toggle | core (built-in) |
| `zh` / `zl` | n | Horizontal scroll (`zH`/`zL`) | core (port `.vimrc:293-294`) |
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | n | Splits AND tmux panes | **vim-tmux-navigator (FIX from A.1)** — restore Plug-based mapping |
| `<leader>ew` `<leader>es` `<leader>ev` `<leader>et` | n | Edit relative file (same/split/vsplit/tab) | core (port `.vimrc:280-283`) |
| `Q` | n | Close-buffer picker | `Asheq/close-buffers.vim` (port vimrc.local:244) |
| `<C-p>` | n | fzf-lua files | `ibhagwan/fzf-lua` |
| `<C-t>` | n | fzf-lua buffers | fzf-lua |
| `<C-c>` | n | fzf-lua commands | fzf-lua |
| `<leader>ss` / `<leader>sh` / `<leader>sw` / `<leader>sW` / `<leader>sl` / `<leader>ag` / `<leader>M` | n (+ v for ss) | fzf-lua grep family | fzf-lua (port vimrc.local:218-224, 163, 236) |
| `<leader>m` | n | fzf-lua keymaps | fzf-lua |
| `<leader>;` | n | BLines (fzf-lua) | fzf-lua |
| `<leader>?` | n | History (oldfiles) | fzf-lua |
| `<leader>A` | n | Windows (fzf-lua) | fzf-lua |
| `<leader>O` | n | BTags (fzf-lua) | fzf-lua |
| `<leader>ft` | n | Filetypes (fzf-lua) | fzf-lua |
| `<leader>ga` / `<leader>gl` | n | BCommits / Commits (fzf-lua) | fzf-lua |
| `<leader>o` | n | fzf-lua btags / ltags (replaces `fzf-preview.Ctags`) | fzf-lua (port vimrc.local:233) |
| `F` | n | Project grep (migrate `<leader>sw` style) | fzf-lua (port vimrc.local:234) |
| `<space>y` / `<space>h` | n | Yank history → **fzf-lua registers** (§4d swap) | fzf-lua `registers` |
| `gd` / `gy` / `gi` / `gr` | n | LSP def / type-def / impl / refs | nvim native LSP (port vimrc.local:1037-1040) |
| `K` | n | Hover docs (vim/help → `:h`, else LSP) | nvim native LSP (port vimrc.local:1048-1056) |
| `<leader>rn` | n | Rename symbol | nvim native LSP (port vimrc.local:1059) |
| `[c` `]c` | n | Previous / next diagnostic | nvim native LSP (port vimrc.local:1033-1034; gitsigns hunk nav gets new keys — see A.3) |
| `<c-space>` | i | Trigger completion | blink.cmp |
| `<TAB>` | i | Select / snippet jump / refresh | blink.cmp |
| `<C-n>` / `<C-p>` | i | Cycle completion menu | blink.cmp |
| `<leader>a` / `<leader>A` | n | Treesitter swap parameter (next / previous) | nvim-treesitter-textobjects (per §4d decision — code-action moves) |
| `<leader>ca` (NEW) | n / v | LSP code action (moved from `<leader>a`) | nvim native LSP / blink.cmp |
| `]a` `[a` | n | ALE next/prev error → **nvim-lint diagnostics** | nvim-lint (port vimrc.local:93-94) |
| `<leader>f` → **renamed** `<leader>lf` | n | Format / auto-fix buffer | conform.nvim (per §3 D5; ALE → nvim-lint + conform) |
| `<leader>tn` `<leader>tf` `<leader>ta` `<leader>tl` `<leader>tv` | n | vim-test nearest/file/suite/last/visit | `vim-test/vim-test` (port vimrc.local:172-176) |
| `<C-c><C-c>` | n / v | Send selection / line to tmux (tslime) | `jgdavey/tslime.vim` (port vimrc.local:190-191) |
| `<C-c>r` | n | Reset tslime pane target | tslime (port vimrc.local:192) |
| `<leader>pd` / `<leader>pr` | n | Gitsigns preview hunk / reset hunk | `lewis6991/gitsigns.nvim` (port vimrc.local:139-140) |
| `<leader>gy` | n / v | Copy GitHub URL | `ruifm/gitlinker.nvim` |
| `:DiffviewOpen` / `:DiffviewFileHistory` / `:Neogit` / `:Octo` | cmd | Git UI family | `sindrets/diffview.nvim` + `NeogitOrg/neogit` + `pwntester/octo.nvim` |
| `s` (motion) | n / v / o | Flash 1-char jump | `folke/flash.nvim` (intentional override) |
| `S` (motion) | n / v | Flash 2-char jump; **or** nvim-surround visual wrap if remapped (FIX B.2) | flash.nvim + nvim-surround (mutually exclusive today) |
| `cs` `ds` `ys` `yS` `ySS` | n | Surround change / delete / add | `kylechui/nvim-surround` |
| `S` | v | Surround wrap selection | nvim-surround (after FIX B.2 disables flash visual `S`) |
| `ak` `ik` `ac` `ic` `af` `if` `aa` `ia` | n / o / v | Treesitter textobjects | `nvim-treesitter/nvim-treesitter-textobjects` (port vimrc.local:637-646) |
| `]m` `[m` `]]` `[[` | n | Function / class start jumps | treesitter-textobjects move (port vimrc.local:651-666) |
| `gnn` `grn` `grc` `grm` | n | Incremental selection | treesitter-textobjects (port vimrc.local:701-704) — **UNVERIFIED after main-branch rewrite (§R4)** |
| `gS` `gJ` | n | Split one-liner / join block | `AndrewRadev/splitjoin.vim` (KEEP §4c) |
| `ci(` `caq` etc. | n / o | Extended text objects | `wellle/targets.vim` (KEEP §4c; optional mini.ai swap §4b) |
| `f` `t` `T` | n | Highlight on find/till (lens) | `kevinhwang91/nvim-hlslens` (port vimrc.local:364-394 setup) |
| `n` `N` | n | Search with virtual lens | hlslens |
| `:Inspect` | cmd | Treesitter highlight captures | `nvim-treesitter` `Inspect` (replaces deleted `<leader>is` — C.2) |
| `<C-M-n>` `<C-M-p>` | n | Multicursor: start / add / prev | `jake-stewart/multicursor.nvim` |
| `<leader>d` | n | Dash lookup | `rizzatti/dash.vim` (KEEP §4c; port vimrc.local:195) |
| `gx` | n | Open URL / github / brewfile / package.json | `chrishrb/gx.nvim` (port vimrc.local:564-575) |
| `<leader>e` | n | **NEW** — nvim-tree toggle | `nvim-tree/nvim-tree.lua` (§9 open item; currently only `<C-e>` from spf13:347) |
| `<leader>wtc` `<leader>wts` `<leader>wtd` | n | Git worktree create / switch / delete | `afonsofrancof/worktrees.nvim` (port vimrc.local:931-935) |
| `<leader>M` | n | fzf-lua resume last picker | fzf-lua (port vimrc.local:236) |
| `<space>y` `<space>h` | n | **fzf-lua registers** (replaces coc-yank per §4d) | fzf-lua |
| `:DBUI` `:DB` `<LocalLeader>S` (SQL) | cmd / n | dadbod database UI / ad-hoc / run query | `tpope/vim-dadbod` + `kristijanhusak/vim-dadbod-ui` (KEEP §4c) |
| `:Prosession` `:Obsession` | cmd | Sessions | `dhruvasagar/vim-prosession` + `tpope/vim-obsession` (KEEP §4c) |
| `:CccPick` `:CccConvert` | cmd | Color picker | `uga-rosa/ccc.nvim` |
| `:Markview` toggle | cmd | Markdown preview | `OXY2DEV/markview.nvim` |
| `:TailwindSort` etc. | cmd | Tailwind tools | `luckasRanarison/tailwind-tools.nvim` |
| `:A` `:AS` `:AV` `:AT` | cmd | Alternate file (projectionist) | `tpope/vim-projectionist` (KEEP §4c) |
| `:Econtroller` `:Emodel` `:Espec` `:Service` `:Query` | cmd | Rails/Elixir projections | vim-projectionist (KEEP §4c) |
| `<C-M-n>` / `<C-M-p>` | n | Multicursor add next / prev | `jake-stewart/multicursor.nvim` |
| `:MCstart` `:MCvisual` `:MCclear` | cmd | Multicursor | multicursor-nvim |

**Keys that intentionally disappear in the final state** (auto-resolve once their owners die):

- `vmap <leader>y :YankCode<CR>` — yank-code deleted (C.1).
- `nmap <silent> <leader>is :TSHighlightCapturesUnderCursor` — playground deleted (C.2).
- `map <Leader>ct :call atags#generate()` — vim-gutentags/easytags deleted (C.3).
- `nnoremap <silent> <leader>tt :TagbarToggle` — tagbar not loaded (C.4).
- All `g:vimade_*` / `g:matchup_*` / `g:qs_highlight_on_keys` / `g:Hexokinase_*` / `:YankCode` / `atags#generate()` orphans — see D.

---

## Phase-3 checklist delta (proposed add-ons)

Building on `MIGRATION.md:163-171`:

- [ ] **FIX A.1** — restore vim-tmux-navigator functionality for `<C-h/j/k/l>` (currently broken by vimrc.local:155-158 overriding with plain `<C-W>...`).
- [ ] **FIX A.3** — bind gitsigns hunk nav to a key not shared with diagnostics (e.g. `]h` / `[h`).
- [ ] **FIX B.2** — choose visual `S` owner (flash.nvim vs nvim-surround). Recommendation: disable flash visual `S`, keep nvim-surround wrap; flash has plenty of single `s` + `r` jumps already.
- [ ] **DECIDE A.2** — `<leader>a` final owner per §4d (swap stays, code-action moves).
- [ ] **FIX C.1-C.4** — delete stale bindings (yank, is, ct, tt).
- [ ] **FIX D.1-D.5** — delete orphan config blocks (vimade, matchup, quick-scope, hexokinase, atags).
- [ ] **UNVERIFIED E.12** — verify `<CR>` in insert with completion menu behaves correctly after blink.cmp port (spf13 `<CR>` map is currently inactive because `g:spf13_map_cr_omni_complete` is unset).
