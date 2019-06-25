# Guide

## Vim common functions

- `<Crtl>-w +` to align all buffers opened.
- `<Crtl>-w o` show buffer in full screen.
- `<Crtl> p` show all files to open.
- `:call dein#update()` update all plugins.

# Plugins

### Asheq/close-buffers.vim

- `Q` close all buffers opened

### mhinz/vim-grepper

- `<leader>ag` search some word

### rizzatti/dash.vim

- `<leader>d` jump to definition on Dash.app

### w0rp/ale

- `]a` next error
- `[a` previous error
- `<leader>f` applies code formater/fixes to current buffer

### ember-tools

- `:Extract` extract to component

### troydm/zoomwintab.vim

- `<C-w>o` zoom buffer tab

### christoomey/vim-sort-motion

- `gs2j` => Sort down two lines (current + 2 below)
- `gsip` => Sort the current paragraph
- `gsii` => Sort the current indentation level (requires text-obj-indent plugin)
- `gsi(` => Sort within parenthesis. (b, c, a) would become (a, b, c)
- `gs` => sort lines selected (visual mode)

### Konfekt/vim-select-replace

Hit c or d followed by `*`, `#`, `g*` or `g#` to replace respectively delete the current word. Now either:

- Hit `c` or `d` followed by `*`, `#`, `g*` or `g#` to replace respectively delete the current word.
  Now either:

  - Press `n/N` to skip the next occurrence of this word, or
  - Press `.` to repeat the previous move and change or deletion.

- Hit `s` or `x` in visual mode to replace respectively delete the selection under the cursor.
  Now either:
  - Press `n/N` to skip the next occurrence of this selection, or
  - Press `.` to repeat the previous move and change or deletion.

## Write Unicode chars on Vim

- First option is to write in the form: `"\u{HEXCODE}"`
- Second option is: press `Crtl + v` next press `u` and finally the `HEXCODE`
