-- ============================================================================
-- LEGACY LUA EXTRACTION — LIVE SOURCE (loaded by the legacy config)
-- ============================================================================
-- vimrc.local no longer embeds the lua block: at the exact point where
-- `lua << EOF … EOF` used to run, it now calls:
--     lua dofile(vim.fn.expand('~/.dotfiles/packages/nvim/legacy-lua-extracted.lua'))
-- Execution order is preserved (same position in the file).
--
-- History:
--   2026-09-04 created as step-0 review artifact (all legacy Lua inventoried)
--   2026-09-04 step-0 collision fixes folded in (flash visual-S restored to nvim-surround)
--   2026-09-04 became the live source — vimrc.local's embedded block deleted
--
-- Sources: ~/.vimrc.local (= dotfiles/packages/vim/vimrc.local)
--   - SECTION 1: inline <cmd>lua keymap expressions (commented reference —
--     these stay as vimscript mappings in vimrc.local)
--   - SECTION 2: the former `lua << EOF` block, verbatim
-- Requires plugin context (fzf-lua, gitsigns, noice, snacks, ...).
-- Migration note: the treesitter block below uses the LEGACY
-- require('nvim-treesitter.configs').setup API (pre-main-branch rewrite);
-- it must be rewritten, not ported verbatim.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- SECTION 1 — inline Lua inside vimscript keymaps (verbatim, commented)
-- These become native vim.keymap.set() calls in the new config.
-- ----------------------------------------------------------------------------
-- :163  nnoremap <leader>ag  <cmd>lua require('fzf-lua').grep()<CR>
-- :215  nnoremap <c-c>       <cmd>lua require('fzf-lua').commands()<CR>
-- :216  nnoremap <c-p>       <cmd>lua require('fzf-lua').files()<CR>
-- :217  nnoremap <c-t>       <cmd>lua require('fzf-lua').buffers()<CR>
-- :218  nnoremap <silent> <leader>ss <cmd>lua require('fzf-lua').live_grep()<cr>
-- :219  vnoremap <silent> <leader>ss <cmd>lua require('fzf-lua').grep_visual()<cr>
-- :220  nnoremap <silent> <leader>sh <cmd>lua require('fzf-lua').live_grep({ rg_opts = '-u', prompt = 'Rg -u❯ ' })<cr>
-- :221  vnoremap <silent> <leader>sh <cmd>lua require('fzf-lua').grep_visual({ rg_opts = 'u', prompt = 'Rg -u❯ ' })<cr>
-- :222  nnoremap <silent> <leader>sw <cmd>lua require('fzf-lua').grep_cword()<cr>
-- :223  nnoremap <silent> <leader>sW <cmd>lua require('fzf-lua').grep_cWORD()<cr>
-- :224  nnoremap <silent> <leader>sl <cmd>lua require('fzf-lua').grep_last()<cr>
-- :232  nnoremap <leader>m   <cmd>lua require('fzf-lua').keymaps()<CR>
-- :236  nnoremap <silent> <leader>M <cmd>lua require('fzf-lua').resume()<cr>

-- ----------------------------------------------------------------------------
-- SECTION 2 — the former `lua << EOF` block, verbatim (now executed via dofile)
-- ----------------------------------------------------------------------------
vim.g.colors_name = 'new-railscasts';
require("nvim-surround").setup({});
require("bufferline").setup({
        options = {
          numbers = "none",
          buffer_close_icon = "",
          modified_icon = "",
          close_icon = "󱎘",
          left_trunc_marker = "",
          right_trunc_marker = "",
          max_name_length = 25,
          tab_size = 25,
          diagnostics = "nvim_lsp",
          show_tab_indicators = true,
          show_buffer_close_icons = true,
          separator_style = "slant",
          always_show_bufferline = true,
          sort_by = 'relative_directory',
          modified_icon = "",
          hover = {
            enabled = true,
            delay = 200,
            reveal = { 'close' }
          },
          diagnostics_indicator = function(count, level, diagnostics_dict, context)
            local icon = level:match("error") and "" or ""
            return " " .. icon .. count
          end
        },
        highlights = {
          background = {
            fg = "#3e4451",
            bg = "#181621",
          },
          fill = {
            fg = "#c9a35c",
            bg = "#160a00",
          },
          buffer_selected = {
            fg = "#d6d1c7",
            bg = "#282c34",
            bold = true,
          },
          buffer_visible = {
            fg = "#564b3a",
            bg = "#181621",
            italic = true,
            bold = true,
          },
          close_button_visible = {
            fg = "#3e4451",
            bg = "#181621",
          },
          close_button = {
            fg = "#3e4451",
            bg = "#181621",
          },
          close_button_selected = {
            fg = "#a53726",
            bg = "#282c34",
          },
          separator = {
            fg = "#160a00",
            bg = "#181621",
          }, 
          separator_visible = {
            fg = "#160a00",
            bg = "#181621",
          },
          separator_selected = {
            fg = "#160a00",
            bg = "#282c34",
          },
          indicator_selected = {
            fg = "#ccaaff",
            bg = "#282c34",
          },
          modified_selected = {
            fg = "#ffffff",
            bg = "#282c34",
          },
          warning = {
            fb = "#4f4a3c",
            bg = "#181621",
          },
          warning_visible = {
            fb = "#4f4a3c",
            bg = "#181621",
          },
          warning_selected = {
            fg = "#d3c28f",
            bg = "#282c34",
          },
          warning_diagnostic_selected = {
            fg = "#f9b145",
            bg = "#282c34",
            italic = false,
            bold = false,
          },
          error_selected = {
            fg = "#d6b39e",
            bg = "#282c34",
          },
          error_diagnostic_selected = {
            fg = "#F47454",
            bg = "#282c34",
            italic = false,
            bold = false,
          },
        }
})
require('hlslens').setup({
  calm_down = true,
  virt_priority = 2,
  nearest_only = true,
  override_lens = function(render, posList, nearest, idx, relIdx)
    local sfw = vim.v.searchforward == 1
    local indicator, text, chunks
    local absRelIdx = math.abs(relIdx)
    if absRelIdx > 1 then
      indicator = ('%d%s'):format(absRelIdx, sfw ~= (relIdx > 1) and ' ▲' or '▼')
    elseif absRelIdx == 1 then
      indicator = sfw ~= (relIdx == 1) and ' ▲' or '▼'
    else
      indicator = ''
    end
    local lnum, col = unpack(posList[idx])
    if nearest then
      local cnt = #posList
      if indicator ~= '' then
        text = ('[%s %d/%d]'):format(indicator, idx, cnt)
      else
        text = ('[%d/%d]'):format(idx, cnt)
      end
      chunks = {{' ', 'Ignore'}, {text, 'HlSearchLensNear'}}
    else
      text = ('[%s %d]'):format(indicator, idx)
      chunks = {{' ', 'Ignore'}, {text, 'HlSearchLens'}}
    end
    render.setVirt(0, lnum - 1, col - 1, chunks, nearest)
  end
})
vim.cmd [[highlight IndentBlanklineIndent1 guibg=#332717 gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent2 guibg=#332b36 gui=nocombine]]
local highlight = {
    "IndentBlanklineIndent1",
    "IndentBlanklineIndent2",
}
require("ibl").setup {
    indent = { highlight = highlight, char = " " },
    --whitespace = {
    --    highlight = highlight,
    --    remove_blankline_trail = false,
    --},
    scope = { enabled = false },
}

require("smartcolumn").setup(
  {
    colorcolumn = { "80", "120", "150" },
    disabled_filetypes = { 
      'help', 'dashboard', 'noice', 'NvimTree', 'fugitive', 'git', 'fzf', 'ccc-ui'
    },
    scope = "window",
  }
)
require('bqf').setup({
    auto_enable = true,
    preview = {
        win_height = 12,
        win_vheight = 12,
        delay_syntax = 80,
        border_chars = {'│', '│', '─', '─', '╭', '╮', '╰', '╯', '█'}
    },
    func_map = {
        vsplit = '',
        ptogglemode = 'z,',
        stoggleup = ''
    },
    filter = {
        fzf = {
            action_for = {['ctrl-s'] = 'split'},
            extra_opts = {'--bind', 'ctrl-o:toggle-all', '--prompt', '> '}
        }
    }
})
require('gitsigns').setup({
  signs = {
    add          = { text = '▍' },
    change       = { text = '▍' },
    delete       = { text = '▸' },
    topdelete    = { text = '◂' },
    changedelete = { text = '◂' },
    untracked    = { text = '│' },
  },
  signs_staged = {
    add          = { text = '▍' },
    change       = { text = '▍' },
    delete       = { text = '▸' },
    topdelete    = { text = '◂' },
    changedelete = { text = '◂' },
    untracked    = { text = '│' },
  },
  signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
  numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
  linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
  word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
  current_line_blame = true,
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = 'eol',
    delay = 100,
    ignore_whitespace = false,
  },
  current_line_blame_formatter = ' <author>, <author_time:%Y-%m-%d> - <summary> <abbrev_sha>',
  preview_config = {
    border = 'single',
    style = 'minimal',
    relative = 'cursor',
    row = 1,
    col = 1
  },
  signs_staged_enable = true,
})
local custom_onedark = require'lualine.themes.onedark'
custom_onedark.normal.b.bg = '#444444'
custom_onedark.normal.c.bg = '#444444'
custom_onedark.normal.c.fg = '#bfbbae'
custom_onedark.normal.c.gui = 'bold'
custom_onedark.inactive.b.bg = '#353535'
custom_onedark.inactive.c.bg = '#353535'
custom_onedark.inactive.c.fg = '#a8a494'

require('fzf-lua').setup({
  -- fzf_bin         = 'fzf-tmux',
  nbsp = '\xc2\xa0',
  --file_icon_padding = ' ',
  height           = 0.95,            -- window height
  width            = 0.80,
  formatter = "path.filename_first",
  winopts = {
    height           = 0.95,            -- window height
    width            = 0.85,            -- window width
    row              = 0.25,            -- window row position (0=top, 1=bottom)
    col              = 0.55,            -- window col position (0=left, 1=right)
  },
  defaults = {
    -- git_icons = true,
  },
  hls = {
    border = 'LineNr',
    title = 'Normal', 
  },
  winopts = {
    preview = {
      horizontal = 'right:55%',  -- image previews get the right pane
    },
  },
  files = {
    -- multiprocess      = false,
    -- debug             = true,
    file_icons        = true,
    color_icons       = true,
  },
  grep = {
    color_icons       = false,
  },
  git = {
    icons = {
      ["M"] = { icon = "★", color = "#C643C6" },
      ["D"] = { icon = "✗", color = "red" },
      ["A"] = { icon = "+", color = "green" },
      ["?"] = { icon = "?", color = "red" },
    },
    stash = {
      preview = "git --no-pager stash show --patch --color {1} | delta --side-by-side --width 200",
    }
  },
  previewers = {
    bat = {
      cmd             = "bat",
      args            = "--style=numbers,changes --color always",
      theme           = 'Coldark-Dark', -- bat preview theme (bat --list-themes)
      config          = nil,            -- nil uses $BAT_CONFIG_PATH
    },
    git_diff = {
      pager        = "delta",
    },
    builtin = {
      treesitter = { enabled = false },
      -- snacks.image renders via the kitty graphics protocol (works through
      -- tmux thanks to `allow-passthrough on` in tmux.conf) and converts
      -- svg/tiff/pdf via magick on the fly. Takes precedence over
      -- `extensions` whenever the terminal supports it.
      snacks_image = { enabled = true, render_inline = true },
      -- shell fallback when snacks.image can't take over (unsupported term).
      -- chafa renders raster AND svg, auto-selecting kitty protocol under
      -- kitty/tmux-passthrough, sixel on sixel terms, block symbols otherwise.
      extensions = {
        ["gif"]  = { "chafa", "{file}" },
        ["bmp"]  = { "chafa", "{file}" },
        ["webp"] = { "chafa", "{file}" },
        ["avif"] = { "chafa", "{file}" },
        ["tif"]  = { "chafa", "{file}" },
        ["tiff"] = { "chafa", "{file}" },
        ["svg"]  = { "chafa", "{file}" },
      },
    },
  },
})

require("gx").setup({
  handlers = {
    plugin = true, -- open plugin links in lua (e.g. packer, lazy, ..)
    github = true, -- open github issues
    brewfile = true, -- open Homebrew formulaes and casks
    package_json = true, -- open dependencies from package.json
    search = true, -- search the web/selection on the web if nothing else is found
  },
  handler_options = {
    search_engine = "google", -- you can select between google, bing, duckduckgo, and ecosia
  },
})

require("diffview").setup({
  enhanced_diff_hl = true,
})
require('neogit').setup({
  graph_style = "kitty"
})
require('multicursor-nvim').setup({})
-- require("force-cul").setup();

-- require('multicursors').setup {
--     hint_config = {
--         float_opts = {
--             border = 'rounded',
--         },
--         position = 'bottom-right',
--     },
--     generate_hints = {
--         normal = true,
--         insert = true,
--         extend = true,
--         config = {
--             column_count = 1,
--         },
--     },
-- }
require("markview").setup({});

require('lualine').setup({
  options = {
    icons_enabled = true,
    theme = custom_onedark,
    disabled_filetypes = {},
    always_divide_middle = true,
    globalstatus = false,
  },
  sections = {
    lualine_a = {'mode', 'searchcount'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {{'filename', path = 1, shorting_target = 80}, {'filetype', icon_only = true}},
    lualine_x = {'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress', 'tabs'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {"%=", 'diff', {'filename', path = 1, color = { gui = 'italic,bold' }}},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  extensions = {'fzf', 'fugitive', 'nvim-tree', 'quickfix'},
})
require('nvim-treesitter.configs').setup({
    textobjects = {
      select = {
        enable = true,
        lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
        keymaps = {
          -- You can use the capture groups defined in textobjects.scm
            ["ak"] = { query = "@block.outer", desc = "around block" },
            ["ik"] = { query = "@block.inner", desc = "inside block" },
            ["ac"] = { query = "@class.outer", desc = "around class" },
            ["ic"] = { query = "@class.inner", desc = "inside class" },
            ["af"] = { query = "@function.outer", desc = "around function " },
            ["if"] = { query = "@function.inner", desc = "inside function " },
            ["aa"] = { query = "@parameter.outer", desc = "around argument" },
            ["ia"] = { query = "@parameter.inner", desc = "inside argument" },
        },
      },
      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          [']m'] = '@function.outer',
          [']]'] = '@class.outer',
        },
        goto_next_end = {
          [']M'] = '@function.outer',
          [']['] = '@class.outer',
        },
        goto_previous_start = {
          ['[m'] = '@function.outer',
          ['[['] = '@class.outer',
        },
        goto_previous_end = {
          ['[M'] = '@function.outer',
          ['[]'] = '@class.outer',
        },
      },
      swap = {
        enable = true,
        swap_next = {
          ['<leader>a'] = '@parameter.inner',
        },
        swap_previous = {
          ['<leader>A'] = '@parameter.inner',
        },
      },
    },
  matchup = {
    enable = true,  -- mandatory, false will disable the whole extension
    disable_virtual_text = false,
    -- [options]
  },
  ensure_installed = {
    'bash', 'css', 'comment', 'diff', 'dockerfile', 'eex', 'elixir', 'embedded_template', 'erlang', 
    'git_rebase', 'git_config', 'gitattributes', 'gitcommit', 'gitignore', 'glimmer', 'gpg', 
    'graphql', 'html', 'http', 'heex', 'javascript', 'json', 'json5', 'jsonc', 'lua', 
    'markdown', 'markdown_inline', 'pem', 'php', 'python', 'readline', 'regex', 'ruby', 'rust', 
    'scss', 'ssh_config', 'sql', 'toml', 'tsx', 'typescript', 'vim', 'vue', 'xml', 'yaml'
  },
  highlight = {
    enable = false,
    additional_vim_regex_highlighting = false,
  },
  playground = {
    enable = true,
    disable = {},
    updatetime = 25, -- debounced time for highlighting nodes in teh playground from source code
    persist_queries = false, -- Whether the query persists across vim sessions
  },
  autotag = {
    enable = false,
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "gnn",
      node_incremental = "grn",
      scope_incremental = "grc",
      node_decremental = "grm",
    },
  },
  indent = {
    enable = true
  },
  folding = { enable = true }
})
require("nvim-web-devicons").set_icon({
  ["config.ru"] = {
    icon = "",
    color = "#e84e4e",
    name = "ConfigRu"
  };
  erb = {
    icon = "ﴜ",
    color = "#e84e4e",
    name = "Erb",
  };
  ["Gemfile$"] = {
    icon = "",
    color = "#e84e4e",
    name = "Gemfile"
  };
  haml = {
    icon = "",
    color = "#e84e4e",
    name = "Haml",
  };
  md = {
    icon = "",
    color = "#519aba",
    name = "Md",
  };
  rake = {
    icon = "",
    color = "#e84e4e",
    name = "Rake"
  };
  rakefile = {
    icon = "",
    color = "#e84e4e",
    name = "Rakefile"
  };
  rb = {
    icon = "",
    color = "#e84e4e",
    name = "Rb"
  };
})
require('nvim-web-devicons').setup({
  -- globally enable different highlight colors per icon (default to true)
  -- if set to false all icons will have the default icon's color
  color_icons = true;
  -- globally enable default icons (default to false)
  -- will get overriden by `get_icons` option
  default = true;
})
require('nvim-tree').setup({
  view = {
    width = 35,
  },
  update_focused_file = {
    enable = true
  },
  renderer = {
    highlight_opened_files = 'all',
    indent_markers = {
      enable = true,
    },
  },
  filters = {
		custom = { ".bundle",
                 ".elixir_ls",
                 ".git",
                 ".beam",
                 ".swo$",
                 ".swp$",
                 ".vim$",
                 "^ctags$",
                 "^tmp",
                 "_build",
                 "deps",
                 "node_modules",
                 "tags",
               },
	}
})

local ccc = require("ccc")
require('ccc').setup({
  inputs = {
    ccc.input.cmyk,
  }
})
-- config = function()
--   vim.o.winwidth = 20
--   vim.o.winminwidth = 20
--   vim.o.equalalways = false
--   require('windows').setup(  { autowidth = {
--       enable = true,
--       winwidth = 5,	
--       filetype = {
--          help = 2,
--       },
--    }})
-- end
require('scrollbar').setup({
  show = true,
  show_in_active_only = false,
  set_highlights = true,
  folds = 1000, -- handle folds, set to number to disable folds if no. of lines in buffer exceeds this
  max_lines = false, -- disables if no. of lines in buffer exceeds this
  handle = {
    text = " ",
    color = '#6f6f6f',
    cterm = nil,
    hide_if_all_visible = true, -- Hides handle if all lines are visible
    blend = 40,
  },
  handlers = {
    diagnostic = true,
    search = true, -- Requires hlslens to be loaded
    gitsigns = true, -- Requires gitsigns.nvim
    ale = false, -- Requires ALE
  },
  marks = {
    Cursor = { color = '#afafaf', text = '◂', priority = 3 },
    Search = { color = '#0095CB', text = { "-", "=" } },
    Error = { color = '#FF5D4F', text = { "-", "=" } },
    Warn = { color = '#FABD2F', text = { "-", "=" } },
    Info = { color = '#458599', text = { "-", "=" } },
    Hint = { color = '#689D6A', text = { "-", "=" } },
    Misc = { color = '#B16286', text = { "-", "=" } },
    GitAdd = { color = '#a4d2a2', text = '┃' },
    GitChange = { color = '#5b1f5b', text = '┃' },
    GitDelete = { color = '#ff8378', text = '┃' },
  },
})
require("gitlinker").setup({});
require("octo").setup({
  picker = 'fzf-lua',
  picker_config = {
    use_emojis = true,
  },
  suppress_missing_scope = {
    projects_v2 = true,
  }
});
-- require("recorder").setup({});
-- require('dressing').setup({})
-- require('nvim-treeclimber').setup()

local builtin = require("statuscol.builtin")
require("statuscol").setup({
  ft_ignore = {
    'help', 'dashboard', 'noice', 'NvimTree', 'fugitive', 'git', 'fzf', 'ccc-ui'
  },
  segments = {
    { text = { builtin.lnumfunc }, click = "v:lua.ScLa", },
    {
      text = { builtin.foldfunc },
      hl = "FoldColumn",
      click = "v:lua.ScFa",
    },
    { text = { ' ', "%s" }, condition = { builtin.not_empty, true }, click = "v:lua.ScSa" },
  }
});

require("noice").setup({
  lsp = {
    -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
      ["cmp.entry.get_documentation"] = true,
    },
  },
  presets = {
    bottom_search = false, -- use a classic bottom cmdline for search
    command_palette = false,
    long_message_to_split = true, -- long messages will be sent to a split
    inc_rename = false, -- enables an input dialog for inc-rename.nvim
    lsp_doc_border = false, -- add a border to hover docs and signature help
  },
  views = {
    cmdline_popup = {
      border = {
        style = "none",
        padding = { 2, 3 },
      },
      filter_options = {},
      win_options = {
        winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
      },
    },
  },
  messages = {
    view_search = false, -- view for search count messages. Set to `false` to disable
  },
})

require('flash').setup({})
-- restore nvim-surround's visual-mode S (flash is sourced later and stole it)
pcall(vim.keymap.del, "x", "S")
vim.keymap.set("x", "S", "<Plug>(nvim-surround-visual)", { remap = true, silent = true })
require("tailwind-tools").setup({
  -- your configuration
})

require("snacks").setup({
  bigfile = { enabled = true },
  dashboard = { enabled = false },
  explorer = { enabled = false },
  indent = { 
    enabled = true,    
    char = '█',
    hl = { "IndentBlanklineIndent1", "IndentBlanklineIndent2"}, 
  },
  image = { enabled = true },
  input = { enabled = false },
  picker = { enabled = false },
  quickfile = { enabled = true },
  scope = { enabled = true },
  statuscolumn = { enabled = true },
  words = { enabled = true },
})

require("worktrees").setup({
  base_path = "..",
  mappings = {
    create = "<leader>wtc",
    delete = "<leader>wtd",
    switch = "<leader>wts",
  },
})

local signs = { Error = "", Warn = "", Hint = "", Info = "" }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  local linehl = "DiagnosticUnderline" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = '' })
end

-- nvim 0.12 fix: diagnostic signs are extmark-based and sign_define no longer
-- feeds their text (hence the bare "W"/"E" letters). ALE runs with
-- g:ale_use_neovim_diagnostics_api=1, so its signs flow through here too.
-- Icons are reused from the `signs` table above, byte-for-byte.
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = signs.Error,
      [vim.diagnostic.severity.WARN] = signs.Warn,
      [vim.diagnostic.severity.INFO] = signs.Info,
      [vim.diagnostic.severity.HINT] = signs.Hint,
    },
  },
})


-- sort.nvim (sQVe) — modern replacement for the deleted vim-sort-motion.
-- Reuses its gs operator (gsip / gsii / gs2j / gsi( / visual gs) plus :Sort.
-- Defaults are sane; custom delimiters/presets via setup opts (see :h sort.nvim).
require("sort").setup({})
