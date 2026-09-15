# fzf.zsh — all fzf configuration, sourced by zshrc.
# Includes: keybindings (fzf --zsh), theme (FZF_COLORS shared with tmux-fzf
# via tmux update-environment), default opts, completion, Ctrl-T / Alt-C / Ctrl-R.

# clipboard used by fzf bindings (platform-agnostic name)
case "$(uname -s)" in
  Darwin) _DOTFILES_CLIP="pbcopy" ;;
  Linux)  command -v wl-copy >/dev/null && _DOTFILES_CLIP="wl-copy" || _DOTFILES_CLIP="xclip -selection clipboard" ;;
esac

# load fzf
source <(fzf --zsh)

# fzf theme — harmonized with the kitty palette (bg #1e1e1e, fg #b8bcb9).
# Typography: bold = interactive, italic = informational, dim = tertiary.
export FZF_COLORS="dark,\
fg:-1,\
hl:italic:#ecb90f,\
bg:-1,\
list-fg:-1,\
list-bg:-1,\
preview-fg:#b8bcb9,\
preview-bg:#202020,\
input-bg:-1,\
header-bg:-1,\
footer-bg:-1,\
selected-fg:#fcffb8,\
selected-bg:#3a3e44,\
hl:bold:#ecb90f,\
selected-hl:bold:#ecb90f,\
fg+:#FEF9E1,\
bg+:#292c31,\
hl+:bold:#f2bd09,\
gutter:#232529,\
alt-bg:#232529,\
alt-gutter:#242629,\
query:bold:-1,\
ghost:italic:dim:#6e7681,\
disabled:dim:#6e7681,\
info:dim:#6e7681,\
prompt:bold:#568ea3,\
pointer:bold:#2cc55d,\
marker:bold:#855b8d,\
spinner:#568ea3,\
border:#6e7681,\
list-border:#6e7681,\
input-border:#6e7681,\
header-border:#6e7681,\
footer-border:#6e7681,\
preview-border:dim:#6e7681,\
separator:dim:#6e7681,\
gap-line:dim:#6e7681,\
scrollbar:#6e7681,\
preview-scrollbar:dim:#6e7681,\
label:italic:#b8bcb9,\
list-label:italic:#b8bcb9,\
input-label:italic:#b8bcb9,\
header-label:italic:#ad9c8b,\
footer-label:italic:#b8bcb9,\
preview-label:italic:#ad9c8b,\
header:italic:#ad9c8b,\
footer:dim:#6e7681,\
nth:italic,\
nomatch:dim:strip"

# Modern fzf full style. Requires fzf >= 0.74 (Homebrew: 0.74.4) for: raw
# mode + toggle-raw + nomatch strip (0.66), word wrap (0.68), --id-nth and
# walker follow (0.71), inline footer border (0.72), next preview position +
# every(N)/FZF_IDLE_TIME (0.73), non-modal floating pane (0.74). All flags
# are literal; only vars expand.
export FZF_DEFAULT_OPTS='--ansi
  --cycle
  --style full
  --layout=reverse
  --info=inline-right
  --border=rounded
  --padding=1,2
  --separator="─"
  --border-label=" fzf "
  --border-label-pos=3
  --input-label=" Input "
  --prompt="❯ "
  --pointer="▶"
  --marker="✓"
  --gutter=" "
  --gutter-raw=" "
  --filepath-word
  --highlight-line
  --preview-window=right:60%:wrap-word
  --footer=" C-a select-all · C-/ preview · C-d/u scroll · C-s sort · Alt-w wrap "
  --footer-border
  --bind="result:transform-list-label:
      if [[ -z $FZF_QUERY ]]; then
        echo \" $FZF_MATCH_COUNT items \"
      else
        echo \" $FZF_MATCH_COUNT matches for [ $FZF_QUERY ] \"
      fi
      "
  --bind="focus:transform-preview-label:[[ -n {} ]] && printf \" Previewing [ %s ] \" {}"
  --bind="ctrl-d:half-page-down"
  --bind="ctrl-u:half-page-up"
  --bind="ctrl-b:page-up"
  --bind="ctrl-f:page-down"
  --bind="pgup:preview-half-page-up"
  --bind="pgdn:preview-half-page-down"
  --bind="shift-up:preview-up"
  --bind="shift-down:preview-down"
  --bind="alt-up:preview-half-page-up"
  --bind="alt-down:preview-half-page-down"
  --bind="ctrl-/:change-preview-window(next:wrap-word|down:50%:wrap-word|hidden|)"
  --bind="ctrl-a:toggle-all"
  --bind="ctrl-s:toggle-sort"
  --bind="alt-w:toggle-wrap-word"
  --bind="alt-r:toggle-raw"
  '"--color='$FZF_COLORS' --popup='center,60%,60%' --history='$HOME/.local/state/fzf'"
# tmux >= 3.7 note: the explicit --border above keeps --popup as the classic
# modal popup with fzf's own rounded border/labels. Drop --border (or pass
# border-native) to get the 0.74 non-modal floating pane instead.

# File walker (Ctrl-T source)
export FZF_DEFAULT_COMMAND="rg --files --no-ignore-vcs --hidden --follow --ignore-file $HOME/.ignore"
export BAT_CONFIG_PATH="$HOME/.bat.conf"

# Completion (tab-completion in shell)
export FZF_COMPLETION_OPTS="--preview-window=border-none --preview '(bat {} || cat {} || tree -C {}) 2> /dev/null | head -200'"
export FZF_COMPLETION_PATH_OPTS="--walker=file,dir,hidden,follow"
export FZF_COMPLETION_DIR_OPTS="--walker=dir,hidden,follow"
export FZF_COMPLETION_TRIGGER='**'

# Ctrl-T: file picker. Multi-select + file-type header + named labels.
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--multi
  --keep-right
  --border-label=' Files '
  --preview-window='right:60%:wrap-word'
  --preview '(bat {} || cat {} || tree -C {}) 2> /dev/null | head -200'
  --bind='focus:+transform-header:file --brief {} 2>/dev/null || echo \"No file selected\"'"

# Alt-C: directory jumper (tree preview)
export FZF_ALT_C_OPTS="--walker=dir,hidden,follow
  --border-label=' Dirs '
  --preview-window='right:60%:nowrap'
  --preview '(eza --icons=always --color=always --tree --level=2 {} 2>/dev/null || tree -C {} 2>/dev/null || ls -la {} 2>/dev/null) | head -200'"

# Ctrl-R: history. Wrapped preview, copy, open-in-vim, delete-aware footer.
export FZF_CTRL_R_OPTS="--wrap=word
  --no-sort
  --border-label=' History '
  --preview 'echo {2..} | bat --color=always --plain --language=sh'
  --preview-window='up:30%:nowrap'
  --bind='ctrl-/:toggle-preview'
  --bind='ctrl-y:execute-silent(echo -n {2..} | ${_DOTFILES_CLIP})+abort'
  --bind='ctrl-v:execute(echo {2..} | nvim -R --clean - > /dev/tty)'
  --bind='ctrl-t:track+clear-query'
  --footer=' Enter: run · C-y: copy · C-v: view · C-/: preview · C-t: jump to latest '"
