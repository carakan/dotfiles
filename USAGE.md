# Guide

## Vim

- `<Crtl> w` to aline all buffers opened.
- `<Crtl> o` show in full screen.
- `<Crtl> p` show all files to open.
- `:call dein#update` update all plugins.
- `Q` show all buffers and show options to close that buffers.

# Plugins:

Asheq/close-buffers.vim

- `Q` close all buffers opened

mhinz/vim-grepper

- `<leader>ag` search some word

rizzatti/dash.vim

- `<leader>d` jump to definition on Dash.app

w0rp/ale

- `]a` next error
- `[a` previous error
- `<leader>f` applies code formater/fixes to current buffer

ember-tools

- `:Extract` extract to component

troydm/zoomwintab.vim

- `<C-w>o` zoom tab

christoomey/vim-sort-motion

- `gs2j` => Sort down two lines (current + 2 below)
- `gsip` => Sort the current paragraph
- `gsii` => Sort the current indentation level (requires text-obj-indent plugin)
- `gsi(` => Sort within parenthesis. (b, c, a) would become (a, b, c)
- `gs` => sort lines selected (visual mode)

## Write Unicode chars on Vim

- First option is to write in the form: `"\u{HEXCODE}"`
- Second option is: press `Crtl + v` next press `u` and finally the `HEXCODE`
