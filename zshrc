export ZSH_DISABLE_COMPFIX=true

# Zsh History
# (Save History to Dropbox if already set up)
export PSY_HISTORY_FILE="$HOME/Dropbox/Apps/zsh/.zsh_history"
[[ -f $PSY_HISTORY_FILE ]] && export HISTFILE=$PSY_HISTORY_FILE
export HISTSIZE=500000
export SAVEHIST=$HISTSIZE

# setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
# setopt SHARE_HISTORY             # Share history between all sessions.
# setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
# setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
# setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
# Another powerful theme
# ZSH_THEME="clean"
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#8e8a70,bold,italic"
export ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd history completion)
export ZSH_AUTOSUGGEST_USE_ASYNC=true

export DISABLE_UPDATE_PROMPT=true

export ZSH_THEME="powerlevel10k/powerlevel10k"

export ZSH_TMUX_DEFAULT_SESSION_NAME=main
export ZSH_TMUX_AUTOCONNECT=true
export ZSH_TMUX_AUTOSTART=true

# export TERM=xterm-256color-italic
# Let kitty set TERM=xterm-kitty (its terminfo is installed in ~/.terminfo).
# Only force tmux-256color as a fallback for other terminals.
if [[ -z "$KITTY_WINDOW_ID" && -z "$TMUX" ]]; then
  export TERM="tmux-256color"
fi
# export TERM="xterm-kitty"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=( zsh-interactive-cd bgnotify history gem mix rails alias-tips node npm bun git 
          brew tmux asdf zsh-autosuggestions macos zsh-completions copypath safe-paste)

# User configuration

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_TYPE=en_US.UTF-8

# history
setopt HIST_IGNORE_SPACE

# directory navigation (zsh 5.9)
setopt AUTO_CD                 # `dir` == `cd dir`
setopt AUTO_PUSHD              # cd pushes onto the dir stack (`cd -<tab>` to browse)
setopt PUSHD_IGNORE_DUPS       # no duplicate entries in the stack
setopt PUSHD_SILENT            # don't print the stack on every cd
setopt INTERACTIVE_COMMENTS    # allow # comments in interactive shells

# Compilation flags
# export ARCHFLAGS="-arch x86_64"
if [ -r /usr/local/opt/mcfly/mcfly.zsh ]; then
  . /usr/local/opt/mcfly/mcfly.zsh
fi

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

export EDITOR="nvim"
export BUNDLER_EDITOR="nvim"

# enable control-s and control-q
stty start undef
stty stop undef
setopt noflowcontrol

# load aliases
[[ -f ~/.aliases ]] && source ~/.aliases

# 10ms for key sequences
KEYTIMEOUT=1

# neovim as default man reader
if [ -n "${NVIM_LISTEN_ADDRESS+x}" ]; then
  export MANPAGER="/usr/local/bin/nvr -c 'Man!' -o -"
elif command -v nvim >/dev/null; then
  export MANPAGER="nvim +Man!"
fi

# Erlang elixir
export ERL_AFLAGS="-kernel shell_history enabled -kernel shell_history_file_bytes 1024000"

# this add every time the keys only for SIERRA MacOS
if [[ -o login && -t 0 && -z "$SSH_AUTH_SOCK" ]]; then
  eval "$(ssh-agent)" >/dev/null
  ssh-add -A &>/dev/null
fi

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
nomatch:dim"

# Modern fzf (0.74+) full style. All flags are literal; only vars expand.
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
  --preview-window=right:60%:wrap
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
  --bind="ctrl-/:change-preview-window(down|hidden|)"
  --bind="ctrl-a:toggle-all"
  --bind="ctrl-s:toggle-sort"
  --bind="alt-w:toggle-wrap-word"
  '"--color='$FZF_COLORS' --popup='center,60%,60%' --history='$HOME/.local/state/fzf'"

# File walker (Ctrl-T source)
export FZF_DEFAULT_COMMAND="rg --files --no-ignore-vcs --hidden --follow --ignore-file $HOME/.ignore"
export BAT_CONFIG_PATH="$HOME/.bat.conf"

# Completion (tab-completion in shell)
export FZF_COMPLETION_OPTS="--preview-window=border-none --preview '(bat {} || cat {} || tree -C {}) 2> /dev/null | head -200'"
export FZF_COMPLETION_PATH_OPTS="--walker=file,dir,hidden"
export FZF_COMPLETION_DIR_OPTS="--walker=dir,hidden"
export FZF_COMPLETION_TRIGGER='**'

# Ctrl-T: file picker. Multi-select + file-type header + named labels.
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--multi
  --keep-right
  --border-label=' Files '
  --preview-window='right:60%:wrap'
  --preview '(bat {} || cat {} || tree -C {}) 2> /dev/null | head -200'
  --bind='focus:+transform-header:file --brief {} 2>/dev/null || echo \"No file selected\"'"

# Alt-C: directory jumper (tree preview)
export FZF_ALT_C_OPTS="--walker=dir,hidden
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
  --bind='ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --bind='ctrl-v:execute(echo {2..} | nvim -R --clean - > /dev/tty)'
  --bind='ctrl-t:track+clear-query'
  --footer=' Enter: run · C-y: copy · C-v: view · C-/: preview · C-t: jump to latest '"

export RIPGREP_CONFIG_PATH=~/.config/.ripgreprc

eval "$(direnv hook zsh)"

function update_brach(){
  git checkout master && git pull && git checkout - && git rebase master
}

export TERMINFO="$HOME/.terminfo"

# Consolidated PATH — single mutation, no `brew --prefix` subprocess
path=(~/.cargo/bin
      /usr/local/bin /usr/local/sbin
      ~/.local/bin
      /usr/local/opt/python@3.13/libexec/bin
      /usr/bin /bin /usr/sbin /sbin)
typeset -U path; export PATH

export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

export HOMEBREW_AUTO_UPDATE_SECS=600000

# Change open files limit and user processes limit.
# See: https://gist.github.com/tombigel/d503800a282fcadbee14b537735d202c
ulimit -n 200000
ulimit -u 2048

# autostart tmux (only in interactive login TTY, never inside VS Code / scripts / SSH)
if [[ -o login && -t 0 && -z "$TMUX" \
   && -z "$VSCODE_PID" && -z "$SSH_CONNECTION" \
   && -z "$INSIDE_EMACS" && -z "$VIM" ]]; then
  local n=${1-Main}
  if tmux has-session -t $n 2>/dev/null; then
    exec tmux a -t $n
  else
    exec tmux new -s $n
  fi
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

eval "$(atuin init zsh)"

# zsh-patina (syntax highlighting) — guard if binary is missing
command -v zsh-patina >/dev/null && eval "$(zsh-patina activate)"

# Conda: NOT auto-initialized (saves ~580ms per shell).
# Use direnv's `layout python` in project .envrc, or `conda activate` explicitly.

