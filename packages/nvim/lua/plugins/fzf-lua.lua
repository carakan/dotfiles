-- plugins/fzf-lua.lua
-- Legacy config (extracted from legacy-lua-extracted.lua:268-344), enhanced
-- against upstream doc/fzf-lua-opts.txt (ibhagwan/fzf-lua main).
-- Keymaps live in lua/keymaps.lua; this file owns config only.

return {
  setup = function()
    require('fzf-lua').setup({
      -- setup-only options
      nbsp = '\xc2\xa0',        -- NBSP delimiter: terminal/font safe (doc: setup.nbsp)
      ui_select = {},            -- fzf-lua as vim.ui.select backend

      -- global
      height = 0.95,
      width = 0.80,
      formatter = 'path.filename_first',
      prompt = '❯ ',

      -- options passed to the fzf binary (doc: globals.fzf_opts)
      fzf_opts = {
        ['--cycle'] = true,      -- wrap at list ends
        ['--keep-right'] = true, -- keep path tails intact with filename_first
        ['--pointer'] = '▌',
        ['--marker'] = '▌',
      },

      -- fzf colors harmonized with the kitty/shell palette
      -- (gold #ecb90f, teal #568ea3, green #2cc55d, purple #855b8d, dim #6e7681)
      fzf_colors = {
        true,                              -- inherit fzf-lua defaults, override below
        ['fg']       = { 'fg', 'CursorLine' },
        ['bg']       = { 'bg', 'Normal' },
        ['hl']       = '#ecb90f',
        ['fg+']      = { 'fg', 'CursorLine' },
        ['bg+']      = { 'bg', 'CursorLine' },
        ['hl+']      = '#f2bd09',
        ['info']     = '#6e7681',
        ['prompt']   = '#568ea3',
        ['pointer']  = '#2cc55d',
        ['marker']   = '#855b8d',
        ['spinner']  = '#568ea3',
        ['header']   = '#6e7681',
        ['border']   = '#6e7681',
        ['gutter']   = '-1',
      },

      winopts = {
        height = 0.95,
        width = 0.85,
        row = 0.25,
        col = 0.55,
        backdrop = 40,          -- darken background behind the float (0-100)
        cursorline = true,      -- highlight selection line in the list
        preview = {
          layout = 'flex',
          horizontal = 'right:55%',
          vertical = 'down:40%',
          scrollbar = 'border',
          scrolloff = -2,       -- keep 2 lines of context around scroll
          title_pos = 'center',
          winopts = { number = true },
        },
      },

      defaults = {},
      hls = {
        border = 'LineNr',
        title = 'Normal',
        preview_border = 'LineNr',
        preview_title = 'Normal',
      },

      keymap = {
        builtin = {
          ['<F1>'] = 'toggle-help',
          ['<F2>'] = 'toggle-fullscreen',
          ['<F3>'] = 'toggle-preview-wrap',
          ['<C-/>'] = 'toggle-preview',
        },
        fzf = {
          ['ctrl-/'] = 'toggle-preview',
          ['alt-w'] = 'toggle-preview-wrap',
        },
      },

      files = {
        file_icons = true,
        color_icons = true,
        ignore_current_file = true,  -- hide the file you're editing from results
        cwd_prompt = true,           -- show CWD as prompt, type-to-narrow
      },

      grep = {
        color_icons = false,
        rg_glob = true,              -- per-query glob filter (rg pattern -- glob)
        ignore_current_file = true,
        input_prompt = 'Grep For> ',
      },

      buffers = {
        sort_lastused = true,        -- MRU ordering, most recent on top
        show_unloaded = true,
      },

      oldfiles = {
        include_current_session = true,
        stat_file = true,            -- size/mtime info for each entry
      },

      diagnostics = {
        diag_icons = true,
        icon_padding = ' ',          -- breathing room between icon and text
      },

      git = {
        icons = {
          ['M'] = { icon = '★', color = '#C643C6' },
          ['D'] = { icon = '✗', color = 'red' },
          ['A'] = { icon = '+', color = 'green' },
          ['?'] = { icon = '?', color = 'red' },
        },
        stash = {
          preview = 'git --no-pager stash show --patch --color {1} | delta --side-by-side --width 200',
        },
      },

      previewers = {
        bat = {
          cmd = 'bat',
          args = '--style=numbers,changes --color always',
          theme = 'Coldark-Dark',
          config = nil,
        },
        git_diff = {
          pager = 'delta --width $FZF_PREVIEW_COLUMNS',
        },
        builtin = {
          treesitter = { enabled = false },
          snacks_image = { enabled = true, render_inline = true },
          extensions = {
            ['gif']  = { 'chafa', '{file}' },
            ['bmp']  = { 'chafa', '{file}' },
            ['webp'] = { 'chafa', '{file}' },
            ['avif'] = { 'chafa', '{file}' },
            ['tif']  = { 'chafa', '{file}' },
            ['tiff'] = { 'chafa', '{file}' },
            ['svg']  = { 'chafa', '{file}' },
          },
        },
      },
    })
  end,
}
