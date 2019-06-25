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

### tpope/vim-surround

It's easiest to explain with examples. Press `cs"'` inside

    "Hello world!"

to change it to

    'Hello world!'

Now press `cs'<q>` to change it to

    <q>Hello world!</q>

To go full circle, press `cst"` to get

    "Hello world!"

To remove the delimiters entirely, press `ds"`.

    Hello world!

Now with the cursor on "Hello", press `ysiw]` (`iw` is a text object).

    [Hello] world!

Let's make that braces and add some space (use `}` instead of `{` for no
space): `cs]{`

    { Hello } world!

Now wrap the entire line in parentheses with `yssb` or `yss)`.

    ({ Hello } world!)

Revert to the original text: `ds{ds)`

    Hello world!

Emphasize hello: `ysiw<em>`

    <em>Hello</em> world!

Finally, let's try out visual mode. Press a capital V (for linewise
visual mode) followed by `S<p class="important">`.

    <p class="important">
      <em>Hello</em> world!
    </p>

### janko/vim-test

<leader>tn :TestNearest
<leader>tf :TestFile
<leader>ta :TestSuite
<leader>tl :TestLast
<leader>tv :TestVisit

### tslime

<C-c><C-c> <Plug>SendSelectionToTmux
<C-c><C-c> <Plug>NormalModeSendToTmux
<C-c>r <Plug>SetTmuxVars

### FZF

<C-c> :Commands
<C-p> :Files
<C-t> :Buffers
<leader>; :BLines
<leader>? :History
<leader>A :Windows
<leader>O :BTags
<leader>a :Buffers
<leader>ft :Filetypes
<leader>ga :BCommits
<leader>gl :Commits
<leader>m :Maps
<leader>o :Tags
F :call SearchWordWithRg()
F :call SearchVisualSelectionWithRg()
<leader>M :FZFMru
<C-x><C-f> <plug>(fzf-complete-file-ag)
<C-x><C-l> <plug>(fzf-complete-line)

### tpope/vim-projectionist

Projectionist provides `:A`, `:AS`, `:AV`, and `:AT` to jump to an "alternate" file.

## Write Unicode chars on Vim

- First option is to write in the form: `"\u{HEXCODE}"`
- Second option is: press `Crtl + v` next press `u` and finally the `HEXCODE`
