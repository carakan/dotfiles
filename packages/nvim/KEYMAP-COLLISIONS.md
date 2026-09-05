# Keymap Collision Audit

> **STATUS 2026-09-04:** step-0 fixes APPLIED to the legacy config (coc demoted;
> A/B/C/D verdicts fixed or scheduled — see MIGRATION.md §6 step 0). Remaining:
> E behavior notes + F prefix hazards, resolved during phases 1–3.

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
| `vim-hexokinase` (`RRethy/vim-hexokinase`) | `vimrc.local:973-989` (entire `g:Hexokinase_*` block) | LOADED (`vimrc.bundles.local:7`) — §4a deletes hexokinase (unmaintained + Go build step; ccc.nvim covers colors). | **~~DISCARD~~ RESTORED 2026-09-04** — user overruled: plugin is ACTIVE in the manifest, so its config stays until migration phase 1. Rule recorded in MIGRATION.md §1: only commented-out/absent plugins lose their config. |
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
- All `g:vimade_*` / `g:matchup_*` / `g:qs_highlight_on_keys` / `:YankCode` / `atags#generate()` orphans — see D. (`g:Hexokinase_*` was briefly deleted in step-0, RESTORED same day — plugin is active in the manifest.)

---

## Phase-3 checklist delta (proposed add-ons)

Building on `MIGRATION.md:163-171`:

- [ ] **FIX A.1** — restore vim-tmux-navigator functionality for `<C-h/j/k/l>` (currently broken by vimrc.local:155-158 overriding with plain `<C-W>...`).
- [ ] **FIX A.3** — bind gitsigns hunk nav to a key not shared with diagnostics (e.g. `]h` / `[h`).
- [ ] **FIX B.2** — choose visual `S` owner (flash.nvim vs nvim-surround). Recommendation: disable flash visual `S`, keep nvim-surround wrap; flash has plenty of single `s` + `r` jumps already.
- [ ] **DECIDE A.2** — `<leader>a` final owner per §4d (swap stays, code-action moves).
- [ ] **FIX C.1-C.4** — delete stale bindings (yank, is, ct, tt).
- [ ] **FIX D.1-D.5** — delete orphan config blocks (vimade, matchup, quick-scope, atags; ~~hexokinase~~ restored — active plugin).
- [ ] **UNVERIFIED E.12** — verify `<CR>` in insert with completion menu behaves correctly after blink.cmp port (spf13 `<CR>` map is currently inactive because `g:spf13_map_cr_omni_complete` is unset).

---

# System-layer audit — yabai + skhd + Karabiner + kitty + tmux + zle

> **Scope:** every hotkey that fires before nvim sees the keystroke. nvim's own
> internal maps are already covered in §A–G above; this section handles the
> shell of daemons around it.
>
> **Inputs verified 2026-09-04:**
> `packages/yabai/skhdrc` (150 ln) · `packages/yabai/yabairc` (113 ln) ·
> `~/.config/karabiner/karabiner.json` (99 ln) · `~/.config/karabiner/karabiner_old.json` (317 ln) ·
> `packages/kitty/kitty.conf` (3248 ln) · `packages/tmux/tmux.conf` (226 ln) ·
> `packages/sh/zshrc` (347 ln).
>
> **Layer precedence (verified):**
> 1. **Karabiner** — `virtual_hid_keyboard: ansi` (`karabiner.json:93-95`) → kernel-level remap BEFORE the OS sees the key.
> 2. **macOS** — receives post-Karabiner events; forwards to focused app.
> 3. **kitty** — terminal Cocoa app; explicit `map ...` in `kitty.conf` consumes the event before the TTY sees it.
> 4. **tmux** — when inside a tmux pane, the prefix key (`tmux.conf:18` `prefix C-a`) plus any `bind-key -n` (no-prefix) grabs the event before the child app does.
> 5. **zsh zle** — only active at the shell prompt; hands off to nvim once nvim takes the TTY.
> 6. **nvim** — terminal app; receives everything that survived layers 1–4.
>
> **Modifier visibility for nvim (verified):**
> - `cmd+key` combos are handled by the Cocoa app (kitty) first; they NEVER reach nvim/tmux unless explicitly injected via `send_text` (see `kitty.conf:2458, 2460`).
> - `alt+key` reaches nvim unless kitty grabs it (kitty currently has NO active `alt+letter` map). On macOS, `kitty.conf:2323` `macos_option_as_alt yes` ensures alt acts as alt inside the TTY.
> - `ctrl+key`, plain letters, function keys pass through to nvim unless a higher layer grabs them.
> - `shift+key` — passes through; only collides with kitty/tmux if those layers explicitly bind it.
>
> **nvim `<leader>`** is verified as **space** (`vimrc.before.local:16` — `let g:spf13_leader = ' '`).

---

## H. System layer inventory

### H.1 — skhd (yabai hotkey daemon) · `packages/yabai/skhdrc` (150 ln)

**66 binds total**, all GLOBAL. yabairc (113 ln) defines no keys; it only owns space labels, rules and config.

| Group | Key | Command | Line |
|---|---|---|---|
| Focus window | `alt - h/j/k/l` | `yabai -m window --focus west/south/north/east` | 10-13 |
| Warp window | `shift + alt - h/j/k/l` | `yabai -m window --warp west/south/north/east` | 18-21 |
| Send window to space | `shift + alt - 1..9` | `yabai -m window --space N` | 26-34 |
| Focus space | `ctrl - 1..9` | `yabai -m space --focus N` | 39-47 |
| Resize edge | `ctrl + alt - h/j/k/l` | `yabai -m window --resize left:-30/bottom:30/top:-30/right:30` | 52-55 |
| Resize increase (alt-style) | `shift + alt - a/s/w/d` | `yabai -m window --resize left:-20/bottom:20/top:-20/right:20` | 58-61 |
| Resize decrease (cmd-style) | `shift + cmd - a/s/w/d` | `yabai -m window --resize left:20/bottom:-20/top:20/right:-20` | 64-67 |
| Move floating window | `shift + ctrl - a/s/w/d` | `yabai -m window --move rel:±20/0` | 72-75 |
| Insertion point | `shift + ctrl + alt - h/j/k/l` | `yabai -m window --insert west/south/north/east` | 80-83 |
| Layout switch | `shift + alt - z/x/s` | `yabai -m space --layout bsp/float/stack` | 88-90 |
| Layout balance | `shift + alt - 0` | `yabai -m space --balance` | 91 |
| Toggle split | `alt - e` | `yabai -m window --toggle split` | 94 |
| Mirror layout | `alt - m` | `yabai -m space --mirror x-axis` | 97 |
| Toggle float | `shift + alt - space` | `yabai -m window --toggle float` | 103 |
| Float + center | `shift + alt - c` | `yabai -m window --toggle float --grid 8:6:1:1:4:6` | 106 |
| Sticky + PIP | `ctrl + alt - p` | `yabai -m window --toggle sticky --toggle pip` | 109 |
| Zoom parent / fullscreen | `alt - d / alt - f` | `yabai -m window --toggle zoom-parent / zoom-fullscreen` | 112-113 |
| Native fullscreen | `shift + alt - f` | `yabai -m window --toggle native-fullscreen` | 117 |
| Fill screen grid | `shift + alt - up` | `yabai -m window --toggle float --grid 1:1:0:0:1:1` | 123 |
| Left/right/center third | `shift + alt - left/right/down` | `yabai -m window --toggle float --grid 1:3:{0,2,1}:0:1:1` | 126, 129, 132 |
| Focus display | `ctrl + alt - z` | `yabai -m display --focus recent` | 138 |
| Move to next display + follow | `ctrl + cmd - c` | `yabai -m window --display next; yabai -m display --focus next` | 141 |
| Save layout | `ctrl + alt - s` | `~/.dotfiles/config/yabai/save_layout.sh` | 147 |
| Restore layout | `ctrl + alt - r` | `~/.dotfiles/config/yabai/restore_layout.sh` | 150 |

**No app-launching binds in skhdrc** (grep verified). System launching is via yabai rules (`yabairc:30-37`) which route already-open apps to spaces — not keys.

### H.2 — Karabiner-Elements (kernel-level remap) · `~/.config/karabiner/karabiner.json` (99 ln)

**13 active rules total** (1 complex + 2 simple + 10 fn). UNVERIFIED for runtime behavior — `~/.local/share/karabiner/log/grabber_agent.log` only logs device-open events, NOT per-key captures (verified by tail).

| Layer | From | To | Line | Scope |
|---|---|---|---|---|
| Complex | `caps_lock` (+ optional any) | `left_control` (or `escape` alone) | 8-19 | All keyboards |
| Simple (vendor 2821 / prod 6481) | `left_command` | `left_option` | 38-41 | **Apple keyboard only** |
| Simple (vendor 2821 / prod 6481) | `left_option` | `left_command` | 43-45 | **Apple keyboard only** |
| fn F3 | `f3` | `mission_control` | 50-53 | All keyboards |
| fn F4 | `f4` | `launchpad` | 54-57 | All keyboards |
| fn F5/F6 | `f5/f6` | `rewind/fastforward` | 58-65 | All keyboards |
| fn F7/F8 | `f7/f8` | `play_or_pause/stop` | 66-73 | All keyboards |
| fn F9/F10/F11 | `f9/f10/f11` | `mute/volume_decrement/volume_increment` | 74-85 | All keyboards |
| fn F12 | `f12` | `apple_vendor_keyboard_key_code: mission_control` | 86-89 | All keyboards |

**F1, F2 are NOT remapped in current config** (compare to old: see §K). Vendor 8738 / prod 24 (likely Topre/Realforce) has NO simple mods — only the Apple keyboard swaps cmd/option.

### H.3 — kitty (terminal) · `packages/kitty/kitty.conf` (3248 ln)

**22 active `map` directives** (counted via grep on `^\s*(map|map_)`). All others are commented `#` placeholders.

| Modifiers | Key | Action | Line |
|---|---|---|---|
| `cmd` | `c` | `copy_to_clipboard` | 2454 |
| `cmd` | `v` | `paste_from_clipboard` | 2455 |
| `shift` | `insert` | `paste_from_clipboard` | 2456 |
| `cmd` | `s` | `send_text all \x13` (injects `<C-s>` into TTY) | 2458 |
| `cmd` | `p` | `send_text all \x10` (injects `<C-p>` into TTY) | 2460 |
| `cmd` + `kitty_mod` (= ctrl+alt) | `up` | `scroll_page_up` | 2571-2572 |
| `cmd` + `kitty_mod` | `down` | `scroll_page_down` | 2579-2580 |
| `cmd` + `kitty_mod` | `home` | `scroll_home` | 2594-2595 |
| `cmd` + `kitty_mod` | `end` | `scroll_end` | 2599-2600 |
| `kitty_mod` (= ctrl+alt) | `equal` | `change_font_size all +2.0` | 2904 |
| `kitty_mod` | `plus` | `change_font_size all +2.0` | 2905 |
| `cmd` | `plus` | `change_font_size all +1.0` | 2907 |
| `cmd` | `equal` | `change_font_size all +1.0` | 2908 |
| `kitty_mod` | `minus` | `change_font_size all -2.0` | 2913 |
| `cmd` | `minus` | `change_font_size all -1.0` | 2915 |
| `shift + cmd` | `minus` | `change_font_size all -1.0` | 2916 |
| `cmd` | `0` | `change_font_size all 0` (reset) | 2921 |
| `ctrl + cmd` | `f` | `toggle_fullscreen` | 3036 |

**Kitty settings that affect layer behavior:**

| Setting | Value | Effect | Line |
|---|---|---|---|
| `kitty_mod` | `ctrl+alt` | Modifier alias used by the 4 scroll + 3 font maps | 2471 |
| `macos_option_as_alt` | `yes` | Option key sent to kitty = Alt in TTY | 2323 |
| `copy_on_select` | `yes` | Mouse-select auto-copies to clipboard | 711 |
| `paste_actions` | `quote-urls-at-prompt,confirm-if-large,confirm` | Safety on paste | 741 |

**NO active kitty map on plain `C-v`, `C-s`, `C-p`, `C-c`, `C-h`, `C-j`, `C-k`, `C-l`** (the commented `# map` lines at 2542, 2547, 2558 etc. do nothing).

### H.4 — tmux · `packages/tmux/tmux.conf` (226 ln)

**~40 binds total** across prefix, root (no-prefix), copy-mode and copy-mode-vi tables.

| Table | Key | Action | Line |
|---|---|---|---|
| (global) | (prefix) | `C-a` (`send-prefix`) | 18, 20 |
| (global) | `Escape-time` | `0` (no prefix-escape delay) | 2 |
| (global) | `mode-keys` | `vi` | 60 |
| root (no-prefix) | `C-h/C-j/C-k/C-l/C-\` | `if-shell $is_vim` forward to nvim; else `select-pane` | 84-88 |
| root (no-prefix) | `S-PageUp` | `copy-mode -eu` (enter copy mode) | 159 |
| root (no-prefix) | `tab` | `tmux-fzf/scripts/pane.sh switch` (fzf pane picker) | 151 |
| copy-mode | `Enter` | enter copy-mode | 59 |
| copy-mode | `WheelUpPane` / `WheelDownPane` | scroll up/down N2 | 63-64 |
| copy-mode | `S-PageUp` / `S-PageDown` | page-up / page-down | 160-161 |
| copy-mode-vi | `C-h/C-j/C-k/C-l/C-\` | `select-pane` | 90-94 |
| copy-mode-vi | `v` | `begin-selection` | 153 |
| copy-mode-vi | `C-v` | `rectangle-toggle` | 154 |
| copy-mode-vi | `Enter` / `y` | `copy-pipe-and-cancel "pbcopy"` | 155-156 |
| copy-mode-vi | `MouseDragEnd1Pane` | `copy-pipe-and-cancel "pbcopy"` | 157 |
| prefix + `h/j/k/l` | (default) | `select-pane L/D/U/R` | 186-189 |
| prefix + `<` / `>` | (repeatable) | `swap-window -d -t ±1` | 192-193 |
| prefix + `H/J/K/L` | (repeatable) | `resize-pane ±5` | 196-199 |
| prefix + `|` `\` `-` `_` | (default) | `split-window -h/-fh/-v/-fv` | 202-205 |
| prefix + `c` | (default) | `new-window` | 208 |
| prefix + `R` | (default) | `respawn-pane -k` | 211 |
| prefix + `x` | (default) | `confirm-before kill-pane` | 212 |
| prefix + `!` | (default) | `break-pane -d` | 213 |
| prefix + `C-f` | (default) | `tmux-fzf` picker (`$TMUX_FZF_LAUNCH_KEY`) | 141 |
| prefix + `C-g` | (default) | `tmux-persist` save (`@persist-save`) | 117 |

**Note `set -sg escape-time 0`** (line 2) — a single C-a fires prefix immediately (no `EscapeTime` delay); to send literal `<C-a>` to the child app, you must press `C-a C-a` quickly (per tmux's `send-prefix` rule on line 20).

### H.5 — zsh / zle · `packages/sh/zshrc` (347 ln)

**0 custom `bindkey` directives** (grep verified — none in `packages/sh/`). ZLE inherits oh-my-zsh defaults, then is patched by:

| Patch | Source | Effect |
|---|---|---|
| oh-my-zsh defaults (`source $ZSH/oh-my-zsh.sh`, line 100) | `oh-my-zsh/lib/key-bindings.zsh` | `<C-r>` history search (REPLACED by atuin below) · `<C-a>` beginning-of-line · `<C-e>` end-of-line · `<C-w>` backward-kill-word · `<C-u>` backward-kill-line · `<C-k>` kill-to-eol · `<C-y>` yank · `<C-d>` delete-char |
| `KEYTIMEOUT=1` | `zshrc:139` | 10 ms for key sequences (instead of default 40) |
| `setopt noflowcontrol` + `stty start undef` + `stty stop undef` | `zshrc:131-133` | Disables XOFF/XON so `<C-s>` and `<C-q>` reach the TTY app (essential for `<C-s>` save in nvim) |
| Atuin (`eval "$(atuin init zsh)"`) | `zshrc:336` | Hijacks `<C-r>` for atuin's history search (replaces oh-my-zsh default) |
| fzf key-bindings (`source <(fzf --zsh)`) | `zshrc:158` | `<C-t>` file picker · `<C-r>` history (now superseded by atuin) · `Alt-C` directory picker |
| zsh-autosuggestions | `zshrc:96` plugin list | `<Up>`/`<Down>` accept suggestion (insert mode at prompt only) |
| zsh-patina (syntax highlighting) | `zshrc:339` | None for keys |

**`<C-c>` is NOT bound in zle** (default). It passes through to the foreground job — meaning when nvim is the foreground process (running in TTY), `<C-c>` reaches nvim as `<C-c>` (interrupt).

---

## I. Collisions WITHIN the system layer

> Same combo bound by two layers from H.1–H.5. Layer precedence column follows
> the chain in this file's intro (Karabiner → macOS → kitty → tmux → shell/nvim).

| Combo | Competing owners (file:line) | Winner (layer order) | Verdict | Proposal |
|---|---|---|---|---|
| `C-a` | (a) tmux prefix `C-a` (`tmux.conf:18`) · (b) zsh default `beginning-of-line` (oh-my-zsh) · (c) `<C-a>` in nvim normal = beginning-of-line | tmux (prefix grabs before zle/nvim see it). Inside tmux, `<C-a>` to nvim requires `prefix C-a` (`bind-key C-a send-prefix`, `tmux.conf:20`). | **KEEP** (tmux prefix is intentional; user chose `C-a` over default `C-b` per `tmux.conf:19`). | Document for nvim: inside tmux, use `<Home>` or `0` for beginning-of-line in normal mode, or `C-a C-a` quickly. See J.5. |
| `C-v` | (a) tmux copy-mode-vi `C-v rectangle-toggle` (`tmux.conf:154`) · (b) nothing in karabiner · (c) nothing active in kitty · (d) nothing in zle · (e) nvim insert `<C-v>` literal char / visual `<C-v>` block | tmux wins **only inside copy-mode-vi** (the bind is in `-T copy-mode-vi`). In nvim normal/insert/visual, tmux passes it through. | **KEEP** (no actual collision for nvim usage — see J.0 for explicit verdict). | None. Document J.0. |
| `C-h/j/k/l` | (a) skhd `alt - h/j/k/l` window focus (`skhdrc:10-13`) · (b) tmux no-prefix nav via `is_vim` guard (`tmux.conf:84-87`) · (c) karabiner no remap · (d) kitty no map · (e) nvim `<C-h/j/k/l>` via vim-tmux-navigator (see §A.1) | skhd wins because it operates at the OS layer when nvim is in the background; but when nvim is foreground inside kitty inside tmux, `C-h/j/k/l` are intercepted by tmux's `is_vim` guard (line 84-87) which forwards to nvim. So the **same combo behaves differently based on whether nvim has focus**. | **KEEP** (intentional multi-layer split — skhd for app focus, tmux+nvim for pane nav). | A.1 fix from existing audit. Document the focus-dependent behavior. |
| `cmd - s` | (a) kitty `map cmd+s send_text \x13` (kitty:2458) · (b) macOS default `cmd-s` (Save…, app-level) · (c) no skhd bind | kitty wins (kitty is the focused app; it consumes the event and synthesizes `<C-s>` into the TTY). macOS Save menu is shadowed for kitty windows. | **KEEP** (intentional passthrough — kitty injects `<C-s>` into TTY so nvim `<C-s>` save fires). | None. |
| `cmd - p` | (a) kitty `map cmd+p send_text \x10` (kitty:2460) · (b) macOS default `cmd-p` (Print) | kitty wins. Inject `<C-p>` → nvim `<C-p>` triggers fzf-lua files (NEOVIM-USAGE.md:39). | **KEEP** (intentional — see `setopt noflowcontrol` enabling this in `zshrc:131-133`). | None. |
| `cmd - c` | (a) kitty `map cmd+c copy_to_clipboard` (kitty:2454) · (b) macOS default copy · (c) no skhd bind | kitty wins. TTY sees nothing (no send_text). | **KEEP** (intentional — selection copy). | None. |
| `cmd - v` | (a) kitty `map cmd+v paste_from_clipboard` (kitty:2455) · (b) macOS default paste · (c) no skhd bind | kitty wins. `paste_actions` filter (`kitty.conf:741`) gates safety. | **KEEP**. | None. |
| `shift + insert` | (a) kitty `paste_from_clipboard` (kitty:2456) · (b) nothing else | kitty wins. | **KEEP**. | None. |
| `F1/F2` | (a) karabiner **OLD** `display_brightness_decrement/increment` (`karabiner_old.json:184-201`) · (b) karabiner CURRENT: **no remap** · (c) no other layer | Current wins (dropped). F1/F2 reach nvim/TUIs as plain F1/F2. | **DISCARD** (old config; see §K). | None — already cleaned up. |
| `C-f` | (a) tmux-fzf launch key (`$TMUX_FZF_LAUNCH_KEY` = `C-f`, `tmux.conf:141`) · (b) nothing else (nvim doesn't bind `C-f`) | tmux wins inside tmux. Outside tmux, nvim sees it (no bind). | **KEEP**. | None. |
| `C-g` | (a) tmux-persist save (`@persist-save 'C-g'`, `tmux.conf:117`) · (b) nothing in nvim/karabiner/kitty | tmux wins inside tmux. | **KEEP**. | None. |
| `S-PageUp / S-PageDown` | (a) tmux no-prefix `S-PageUp → copy-mode` (`tmux.conf:159`) · (b) tmux copy-mode `S-PageUp/Down → page-up/down` (`tmux.conf:160-161`) | tmux wins. nvim doesn't bind these. | **KEEP**. | None. |
| `tab` (no prefix) | (a) tmux `bind-key tab ...` (`tmux.conf:151`, fzf pane switcher) · (b) nvim normal `<Tab>` (no default) · (c) nvim insert `<Tab>` completion jump | tmux wins for `tab` in nvim normal mode (no $is_vim guard for tab). | **KEEP** (harmless — nvim `<Tab>` in normal mode is not in the keymap contract, only insert mode `<Tab>` is documented in NEOVIM-USAGE.md:70). | Document: `<Tab>` inside tmux + nvim normal = pane picker. |
| `ctrl - 1..9` | (a) skhd focus space (`skhdrc:39-47`) · (b) no tmux bind · (c) nvim count prefix `1..9` (unmodified, no ctrl) | skhd wins (OS layer). nvim's count prefix is `1..9` without ctrl — no collision. | **KEEP**. | None. |
| `alt - f` / `alt - d` / `alt - e` / `alt - m` / `alt - h/j/k/l` | skhd window mgmt (`skhdrc:10-13, 94, 97, 112-113`) vs nothing else | skhd wins when OS focus is on any app. Alt doesn't reach nvim unless explicitly sent via TTY. | **KEEP**. | None. |
| `ctrl + alt - h/j/k/l` | (a) skhd resize edge (`skhdrc:52-55`) · (b) kitty `kitty_mod+...` (kitty:2904-2916) — wait, kitty_mod is ctrl+alt but the active kitty_mod binds are on `equal/plus/minus/home/end/up/down`, **not on letters** | skhd wins for the letter binds. No collision. | **KEEP**. | None. |
| `shift + alt - s` | (a) skhd resize increase + layout stack (`skhdrc:59, 90`) · (b) nothing else | skhd wins. | **KEEP**. | None. |
| `shift + cmd - s/w/a/d` | (a) skhd resize decrease (`skhdrc:64-67`) · (b) macOS default shift+cmd+s (Save As) etc. when focused on a Cocoa app; nvim doesn't see this combo | skhd wins when skhd is loaded (it always is, per `yabai -m signal` setup). | **KEEP** (intentional — muscle memory for resize). | None. |
| `caps_lock` (alone, no other key) | (a) karabiner complex → `escape` (`karabiner.json:14-15`) · (b) macOS default caps_lock | karabiner wins (it intercepts before macOS). | **KEEP** (intentional — caps as Esc). | None. |
| `caps_lock` (with other key) | (a) karabiner complex → `left_control` (`karabiner.json:13-14`) · (b) macOS default | karabiner wins. | **KEEP** (intentional — caps as Ctrl). | None. |

**Within-layer sanity check (no actual collisions found):**
- skhd: each combo appears once.
- kitty: `cmd+s` and `cmd+p` are the only `send_text` injections; the rest of cmd+/kitty_mod maps target different actions (copy/paste/scroll/font).
- tmux: `S-PageUp` lives in both root and copy-mode tables, but they activate in different modes — no conflict.

---

## J. System ↔ nvim cross-layer collisions

> Each row: does a system-layer hotkey shadow a key nvim uses (per
> `NEOVIM-USAGE.md`)? Layer precedence is the chain from this file's intro.

### J.0 — `<C-v>` verdict (user's explicit worry) — FIRST ROW BY DESIGN

**`<C-v>` (no modifier):** SAFE. nvim insert/visual/operator-pending `<C-v>` is NEVER grabbed by any system layer.

Evidence:
- **Karabiner** (`karabiner.json`): only `caps_lock` is remapped (lines 8-19). `<C-v>` flows through unchanged.
- **kitty** (`kitty.conf`): the only `v`-keyed map is `map cmd+v paste_from_clipboard` (line 2455) — `cmd+v` is a different modifier combo. Grep over the entire file shows NO active `map ... v` for plain `v` or `C-v` (the only `v` matches are inside `discard_event` and `unicode_input` examples, which are commented). The `mouse_map cmd+left release grabbed,ungrabbed mouse_handle_click link` at line 907 is cmd+left, irrelevant.
- **tmux** (`tmux.conf:154`): `unbind-key -T copy-mode-vi C-v ; bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle` — this fires **only inside the `-T copy-mode-vi` table**, i.e. only after the user has already entered tmux copy mode (typically via `prefix [` or `Enter copy-mode`). It does not bind plain `<C-v>` in the root table. So when nvim is in normal/insert/visual mode inside a tmux pane, `<C-v>` reaches nvim.
- **zsh/zle** (`zshrc`): no `bindkey` for `<C-v>` (grep confirmed); default zle widget is `vi-quoted-insert` but only at the shell prompt, never inside nvim.
- **nvim** (`NEOVIM-USAGE.md` + `vimrc.local`): insert `<C-v>` literal char, visual `<C-v>` block-wise visual, operator `<C-v>` → block selection. All three reach nvim cleanly.

**Verdict: SAFE.** Document the alternates instead of remapping:
- Visual block: `C-v` works directly. From visual char `v`, use `C-v` toggle (`vimrc.local` has treesitter-textobjects swap at `<leader>a`/`<leader>A` for params, not for v→C-v).
- Reselect last visual: `gv`.
- One-shot block from insert: `C-o C-v` (vim normal mode for one cmd, then back to insert).

No action needed. The worry is unfounded given the configs read.

### J.1..J.N — rest of cross-layer

| Combo | nvim key (NEOVIM-USAGE.md / vimrc.local) | System-layer owner (file:line) | Winner for nvim | Verdict | Proposal |
|---|---|---|---|---|---|
| `<C-s>` | save file (n/i/v) — `vimrc.local` save helper | nothing in karabiner · nothing active in kitty · no tmux bind · zsh disables XOFF (`zshrc:131`) | nvim wins (passthrough). `cmd+s` in kitty also injects `<C-s>` (intentional, line 2458). | **KEEP**. | None. |
| `<C-p>` | fzf-lua files (NEOVIM-USAGE.md:39) | `cmd+p` in kitty injects `<C-p>` (line 2460) — same intent | nvim wins (both paths converge). | **KEEP**. | None. |
| `<C-t>` | fzf-lua buffers (NEOVIM-USAGE.md:40) | nothing in skhd/kitty/karabiner · no tmux bind (C-a is prefix, not C-t) | nvim wins. | **KEEP**. | None. |
| `<C-c>` | fzf-lua commands normal (NEOVIM-USAGE.md:41) AND `<C-c><C-c>` tslime prefix (`vimrc.local:190-191`) | no active kitty map · no skhd bind · tmux prefix is `C-a` (different) · zsh default has no `<C-c>` widget | nvim wins. | **KEEP**. | None. |
| `<C-h>/<C-j>/<C-k>/<C-l>` | vim-tmux-navigator (NEOVIM-USAGE.md:31) AND `<C-W>h/j/k/l` window nav (`vimrc.local:155-158` — currently broken per §A.1) | tmux no-prefix `is_vim` guard (`tmux.conf:84-87`) → forwards to nvim when nvim is foreground | nvim wins (when nvim has focus inside tmux). When nvim is NOT focused (any other kitty pane / app), `<C-h/j/k/l>` is unhandled — kitty/tmux/skhd don't bind ctrl+letter. | **FIX A.1** (already in checklist). | See checklist row A.1. |
| `<C-\>` | vim-tmux-navigator last pane (`tmux.conf:88`) | only the tmux no-prefix bind | nvim receives it via tmux forward. | **KEEP**. | None. |
| `<C-x>` | nvim insert completion trigger (built-in, used by coc/blink.cmp) | nothing in any system layer | nvim wins. | **KEEP**. | None. |
| `tab` (insert) | blink/cmp completion select/snippet jump (NEOVIM-USAGE.md:70) | tmux no-prefix `tab` → fzf pane picker (`tmux.conf:151`) — **steals tab in insert mode too** | **tmux wins**. nvim `<Tab>` in insert mode will not fire when inside tmux. | **UNVERIFIED** — but `bind-key -n 'tab'` has no `$is_vim` guard, so this likely fires before nvim sees it. Need a tmux bind-key like `bind-key -n 'tab' if-shell "$is_vim" 'send-keys Tab'` to forward. | Recommend adding `bind-key -n Tab if-shell "$is_vim" 'send-keys Tab'` to `tmux.conf` near the existing vim-tmux-navigator block (line 88 area). |
| `<Tab>` (normal) | unused per keymap contract | tmux no-prefix `tab` pane picker | tmux wins. nvim normal `<Tab>` is not used. | **KEEP** (harmless today). | None until phase 2 if nvim normal `<Tab>` is reassigned. |
| `<C-n>` / `<C-p>` (insert, pum visible) | cycle completion menu (NEOVIM-USAGE.md:71) | nothing in any system layer | nvim wins. | **KEEP**. | None. |
| `<C-Space>` (insert) | blink/cmp trigger (NEOVIM-USAGE.md:69) | macOS Spotlight default (Ctrl-Space) — but inside kitty, `ctrl+space` reaches nvim unless skhd/kitty grab | nvim wins. | **KEEP**. | None. |
| `<C-M-n>` / `<C-M-p>` | multicursor add next/prev (NEOVIM-USAGE.md:131) | nothing in any system layer | nvim wins. | **KEEP**. | Verify nvim 0.12 still recognizes `<C-M-n>` as Alt-Ctrl-n (already flagged in §B.3). |
| `<leader>a` (normal + visual) | treesitter swap-parameter (post-migration) | nothing in skhd/kitty/karabiner/tmux uses `space+a` | nvim wins. | **KEEP** (already in §A.2). | None. |
| `<C-v>` (insert / normal / visual) | literal char / block selection | **NOT grabbed by any layer** (see J.0) | nvim wins. | **SAFE** (J.0). | None. |
| `v` (normal) | visual char mode | tmux copy-mode-vi `v begin-selection` (`tmux.conf:153`) — only inside copy-mode-vi | nvim wins (different layer). | **KEEP**. | None. |
| `y` (visual / normal) | vim yank | tmux copy-mode-vi `y copy-pipe pbcopy` (`tmux.conf:156`) — only inside copy-mode-vi | nvim wins. | **KEEP**. | None. |
| `F1` | vim help (`:h`) | karabiner **OLD** remapped; karabiner **CURRENT** does not (see §K) | nvim wins (current config). | **KEEP**. | None. |
| `F2` | not bound | karabiner old remapped; current doesn't | nvim/TUI sees plain `F2`. | **KEEP**. | None. |
| `F3-F12` | not bound by nvim contract | karabiner live (`karabiner.json:50-89`) → mission_control/launchpad/media keys | karabiner wins. | **KEEP** (intentional — macOS media keys). | None. |
| `S-PageUp / S-PageDown` | not bound | tmux no-prefix / copy-mode (`tmux.conf:159-161`) | tmux wins. | **KEEP**. | None. |
| `cmd+anything` | **NEVER reaches nvim** (Cocoa apps keep cmd combos) | various (see §I cmd rows) | n/a — nvim never sees these. | **KEEP**. | None. |
| `alt+letter` | **NEVER reaches nvim** by default in terminal (Cocoa intercepts alt on macOS for special chars) — UNLESS `macos_option_as_alt yes` is set, which it is (`kitty.conf:2323`). So alt+letter DOES reach nvim as `<A-letter>`. | various skhd alt-binds (§H.1) | n/a — skhd wins when active. But skhd binds have to MATCH the alt+letter combo the user presses. | **UNVERIFIED** — depends on whether user's muscle memory targets the swapped physical keys on Apple kb (see K.3). | If apple kb cmd↔opt swap is causing surprises (see §K.3), either disable the swap or re-train. |
| `caps_lock` alone | n/a | karabiner → escape (`karabiner.json:15`) | n/a (not a vim key). | **KEEP** (intentional). | None. |
| `caps_lock + key` | n/a (treated as ctrl+key) | karabiner → left_control (`karabiner.json:14`) | n/a — reaches nvim as `<C-key>` (after karabiner). | **KEEP**. | None — but be aware: `<C-c>` triggered via caps+c means tmux prefix is NOT invoked (because `C-a` is prefix, not `C-c`). Verified by tmux.conf:18. |
| `<C-a>` (normal) | beginning-of-line | tmux prefix `C-a` (`tmux.conf:18, 20`) | **tmux wins** when nvim is inside tmux. | **KEEP** (documented tmux trade-off). | Use `<Home>` or `0` for beginning-of-line inside tmux; or `C-a C-a` quickly for literal `<C-a>` (per `bind-key C-a send-prefix`, line 20). |
| `<C-c><C-c>` (normal / visual) | tslime send selection / line | nothing in system layers (kitty has no `<C-c>` map; no skhd bind) | nvim wins. | **KEEP**. | None. |
| `<C-c>r` (normal) | tslime reset pane target | nothing in system layers | nvim wins. | **KEEP**. | None. |
| `<leader>fc` (normal) | git conflict marker jump (NEOVIM-USAGE.md:26) | nothing in system layers | nvim wins. | **KEEP**. | None. |
| `gx` (normal) | gx.nvim URL opener (NEOVIM-USAGE.md:190) | nothing in system layers | nvim wins. | **KEEP**. | None. |
| `<leader>e` (normal) | nvim-tree toggle (planned phase 2, NEOVIM-USAGE.md:197) | nothing in system layers | nvim wins. | **KEEP**. | None. |
| `<leader>w*` (normal) | worktrees (NEOVIM-USAGE.md:195) | nothing in system layers | nvim wins. | **KEEP**. | None. |
| `<leader>y` / `<leader>h` (normal) | fzf-lua registers (post-migration) | nothing in system layers | nvim wins. | **KEEP**. | None. |
| `<leader>?` (normal) | fzf-lua History (NEOVIM-USAGE.md:51) | nothing in system layers | nvim wins. | **KEEP**. | None. |

**Layer summary for nvim cross-layer:**
- All nvim `<C-s>`, `<C-p>`, `<C-c>`, `<C-h/j/k/l>`, `<C-v>`, `<leader>...`, `<Tab>` (insert), `<C-M-n/p>`, `<C-a>`, `gx`, `<leader>fc`, `<leader>e`, `<C-x>`, `<C-Space>` reach nvim cleanly given the configs as written — **with three real caveats**:
  1. `<C-a>` is shadowed by tmux prefix (intentional, use `<Home>` or `C-a C-a` quickly).
  2. `<Tab>` in insert mode is shadowed by tmux no-prefix `tab` pane picker — **latent bug for blink/cmp** (recommend adding tmux `if-shell "$is_vim" 'send-keys Tab'` forwarder).
  3. Karabiner's left_cmd ↔ left_option swap on the Apple keyboard (§K.3) means physical-alt presses on that kb fire cmd-targeted skhd binds and vice-versa — silently inverting the entire alt/cmd skhd muscle memory.

---

## K. Karabiner historical delta (old vs current)

`karabiner_old.json` (317 ln, Dec 2023, version 14.12.0) vs `karabiner.json` (99 ln, current, version 15.x). Compared via diff of the two files.

### K.1 — KEPT (identical in both)

| Rule | Both |
|---|---|
| Complex: `caps_lock` → `left_control` (with other) / `escape` (alone) | `karabiner.json:7-19` and `karabiner_old.json:20-46` |
| fn F3 → mission_control | `karabiner.json:50-53`, `karabiner_old.json:204-211` |
| fn F4 → launchpad | `karabiner.json:54-57`, `karabiner_old.json:213-221` |
| fn F5 → rewind | `karabiner.json:58-61`, `karabiner_old.json:223-231` |
| fn F6 → fastforward | `karabiner.json:62-65`, `karabiner_old.json:232-241` |
| fn F7 → play_or_pause | `karabiner.json:66-69`, `karabiner_old.json:242-250` |
| fn F8 → stop | `karabiner.json:70-73`, `karabiner_old.json:252-259` |
| fn F9 → mute | `karabiner.json:74-77`, `karabiner_old.json:262-269` |
| fn F10 → volume_decrement | `karabiner.json:78-81`, `karabiner_old.json:272-280` |
| fn F11 → volume_increment | `karabiner.json:82-85`, `karabiner_old.json:282-290` |
| fn F12 → mission_control (apple_vendor_keyboard_key_code) | `karabiner.json:86-89`, `karabiner_old.json:293-301` |

### K.2 — DROPPED (in old, NOT in current)

| Rule | Old line | Effect today |
|---|---|---|
| fn F1 → `display_brightness_decrement` | `karabiner_old.json:184-191` | F1 reaches the OS unchanged. F1 in vim = help. In TUIs = whatever the app binds. **Muscle-memory trap**: if the user is reaching for brightness-down via F1, it now does nothing on Karabiner's side — but `F1` is also the standard "help" key in vim/nvim (`:h`). If a vim mapping like `<F1>` was ever intended to be brightness-down via F1, it's been lost. The current `<F1>` reaches vim help. |
| fn F2 → `display_brightness_increment` | `karabiner_old.json:193-200` | Same as F1 — dropped. |

### K.3 — ADDED (NOT in old, IS in current)

| Rule | Current line | Effect |
|---|---|---|
| Simple (vendor 2821 / prod 6481): `left_command` → `left_option` | `karabiner.json:38-41` | On the Apple keyboard only, physical left_cmd is reported to macOS as left_option. **Silently inverts cmd/alt for all layers below Karabiner** on that keyboard. |
| Simple (vendor 2821 / prod 6481): `left_option` → `left_command` | `karabiner.json:43-45` | On the Apple keyboard only, physical left_option is reported as left_command. Combined with the above, the two modifiers are swapped. |

### K.4 — Devices delta

| Vendor / Product | In old | In current | Notes |
|---|---|---|---|
| 8738 / 24 | yes | yes | No simple mods in either. |
| 9610 / 58 | yes | no | Dropped from device list (probably a now-disconnected keyboard). |
| 2821 / 6481 | yes | yes | Empty simple_modifications in old; now has the cmd↔option swap (K.3). |
| 1133 / 50489 (kb) | yes | no | Dropped (probably disconnected — it was already `ignore: true` in old). |
| 1133 / 50489 (mouse) | yes | no | Same. |

**Two devices removed from the active device list** between Dec 2023 and now; the Apple keyboard gained the swap. UNVERIFIED whether the removed devices were physically disconnected or simply removed from the Karabiner device list (the old config had them as `ignore: true`).

### K.5 — Muscle-memory traps from K.2 / K.3

| User expectation | Today reality |
|---|---|
| Press F1 to dim the display | F1 reaches the focused app — vim `<F1>` = help, kitty passthrough, etc. Brightness no longer tied to F1. (Was the user's old muscle memory.) |
| Press F2 to brighten | Same — F2 passes through. |
| Press physical-`cmd` on the Apple kb, expect macOS cmd | macOS sees `option`. Spotlight/cmd-tab/cmd-q etc. fire when user presses physical-`option`. **All cmd+key skhd binds (skhdrc) are inverted**: pressing physical-`cmd` triggers the bind on the `alt` slot and vice-versa. |
| Press physical-`alt` on the Apple kb, expect macOS alt | macOS sees `cmd`. **`alt+key` skhd binds fire on physical-`option`** — same inversion. |

**K.3 is the most impactful delta** and is **UNVERIFIED at runtime** (the log files only contain device-open events, not per-key traces). The user should test: open a Terminal, type something, press physical-`cmd` — does it produce `<D->` (cmd) or `<A->` (alt)? Same for physical-`alt`. If the latter, K.3 is active and inverting every cmd/alt skhd bind on the Apple kb.

---

## L. Recommended final system keymap notes

One-liners, no new file. For inclusion in `NEOVIM-USAGE.md` (System appendix) or kept here.

1. **`<C-v>` is SAFE.** Documented in J.0. No remap needed. Document vim built-ins (`gv`, `C-o C-v`) for muscle-memory alternatives.
2. **`<C-a>` inside tmux is shadowed by the prefix.** Use `<Home>` (or `0` in normal mode). For literal `<C-a>`, press `C-a C-a` quickly (`tmux.conf:20` send-prefix + `set -sg escape-time 0` makes this work without delay).
3. **`<Tab>` inside tmux is hijacked by `bind-key -n tab` pane picker.** Recommend adding `bind-key -n Tab if-shell "$is_vim" 'send-keys Tab'` near the vim-tmux-navigator block (`tmux.conf:84-88`) so insert-mode `<Tab>` completion survives inside tmux. Low-risk — does not affect tab behavior outside nvim.
4. **Karabiner Apple-keyboard cmd/option swap (`karabiner.json:38-45`) silently inverts every cmd/alt skhd bind on that kb.** If physical-`cmd`+letter is doing nothing where the user expects "focus window left", verify the swap is actually wanted. Either keep (and re-train muscle memory) or delete both `simple_modifications` entries on vendor 2821.
5. **Karabiner dropped F1/F2 brightness remaps** (`karabiner_old.json:184-200` vs current — absent). If the user still presses F1/F2 expecting brightness, that behavior is gone. Re-add only if needed; otherwise leave F1/F2 to reach apps.
6. **`macos_option_as_alt yes` (`kitty.conf:2323`) ensures alt+letter reaches the TTY** — but it ALSO means alt+letter skhd binds fire only when the skhd-targeted app is in foreground AND the user uses the non-Apple kb (Apple kb is inverted per K.3). Confirm with: focus kitty, press `alt-h`, expected: yabai focus west. If nothing happens, K.3 is biting.
7. **`cmd+s` and `cmd+p` in kitty (`kitty.conf:2458, 2460`) inject `<C-s>` / `<C-p>` into the TTY** — this is the intentional bridge from Cocoa cmd to vim ctrl. Combined with `stty start undef` (`zshrc:131`), nvim `<C-s>` save fires correctly. Do NOT remove.
8. **`kitty_mod = ctrl+alt` (`kitty.conf:2471`)** is reserved for kitty's scroll + font-size maps (lines 2571-2580, 2904-2916). It does NOT collide with tmux prefix (which is `C-a`) or with any active skhd bind on the same letters (kitty binds ctrl+alt on `home/end/up/down/equal/plus/minus` — not letters). Safe.
9. **No app-launching skhd binds exist.** App routing is via yabai rules (`yabairc:30-37`) which only assign apps to spaces on launch — keys do not launch apps. If the user wants cmd-1..9 to "go to space 1..9", that lives in skhd (`ctrl - 1..9`, `skhdrc:39-47`); app launching (e.g., `cmd-shift-L` to open Slack) is not currently wired.
10. **No `bindkey` in `zshrc`.** ZLE runs on defaults + oh-my-zsh + atuin (which hijacks `<C-r>`) + fzf. If a key stops working at the shell prompt and not inside nvim, suspect one of those four layers — not zshrc.

