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

FZF_COLORS="bg:-1,\
bg+:#282828,\
fg:-1,\
fg+:#FEF9E1,\
hl:italic:#a9b665,\
preview-bg:#202020,\
hl+:bold:italic:#a9b665,\
header:#ad9c8b,\
border:#6B503C,\
info:#d4be98,\
prompt:#d4be98,\
pointer:#d4be98,\
marker:#7f61b3,\
spinner:#36c692"

export FZF_DEFAULT_OPTS="--ansi
  --cycle
  --info inline-right
  --color='$FZF_COLORS' \
  --prompt=' '
  --pointer=''
  --height='40%'
  --margin='1,3'
  --layout='reverse'
  --filepath-word
  --highlight-line
  --history '$HOME/.local/state/fzf'
  --bind=ctrl-d:half-page-down,ctrl-u:half-page-up,ctrl-b:page-up,ctrl-f:page-down
  --preview-window='right:60%:wrap'"
export FZF_TMUX=1
export FZF_DEFAULT_COMMAND="rg --files --no-ignore-vcs --hidden --follow --ignore-file $HOME/.ignore"
export BAT_CONFIG_PATH="$HOME/.bat.conf"
export FZF_COMPLETION_OPTS="--preview-window noborder --preview '(bat {} || cat {} || tree -C {}) 2> /dev/null | head -200'"
export FZF_CTRL_T_OPTS="$FZF_COMPLETION_OPTS"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_COMPLETION_PATH_OPTS="--walker=file,dir,hidden"
export FZF_COMPLETION_DIR_OPTS="--walker=dir,hidden"
# Alt-C: directory jumper with tree preview (falls back to ls)
export FZF_ALT_C_OPTS="--walker=dir,hidden --preview '(eza --tree --level=2 --color=always {} || tree -C {} || ls -la {}) 2> /dev/null | head -200'"
# fzf-tab style multi-select for Ctrl-T file picker
export FZF_CTRL_T_OPTS="$FZF_CTRL_T_OPTS --multi"

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

