export ZSH_DISABLE_COMPFIX=true
# Path to your oh-my-zsh installation.
export ZSH=/home/carakan/.oh-my-zsh
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
export TERM="tmux-256color"

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
plugins=( zsh-interactive-cd bgnotify dnf history github gem mix rails vscode alias-tips sudo 
          node npm git brew tmux asdf zsh-autosuggestions macos zsh-completions )

# User configuration

export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
# export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

setopt HIST_IGNORE_SPACE

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

# android
# export JAVA_HOME=$(/usr/libexec/java_home)
# export ANDROID_HOME=/usr/local/share/android-sdk
# export ANDROID_SDK_ROOT="/usr/local/share/android-sdk"

# Erlang elixir
export ERL_AFLAGS="-kernel shell_history enabled -kernel shell_history_file_bytes 1024000"

# this add every time the keys only for SIERRA MacOS
{ eval `ssh-agent`; ssh-add -A; } &>/dev/null

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS='--no-bold --color=fg:#FEF9E1,bg:#282828,hl:bold:italic:#a9b665 --color=fg+:#FEF9E1,hl+:bold:italic:#a9b665,bg+:#282828,preview-bg:#202020 --color=pointer:#d4be98 --prompt=" "'
# Palette for fzf >= 0.48 and for the tmux-fzf popups (single source of the
# popup colors below; FZF_DEFAULT_OPTS above keeps its own --color spelling and
# its bold:italic highlights, so edit colors in whichever block you care about).
export FZF_COLORS='fg:#FEF9E1,bg:#282828,hl:#a9b665,fg+:#FEF9E1,bg+:#282828,hl+:#a9b665,pointer:#d4be98,preview-bg:#202020,gutter:#282828,info:#a9b665,query:#d4be98'
export FZF_TMUX=1
export FZF_DEFAULT_COMMAND="rg --files --no-ignore-vcs --hidden --follow --ignore-file $HOME/.ignore"
export BAT_CONFIG_PATH="/home/carakan/.bat.conf"
export FZF_COMPLETION_OPTS="--preview-window noborder --preview '(bat {} || cat {} || tree -C {}) 2> /dev/null | head -200'"
export FZF_CTRL_T_OPTS="$FZF_COMPLETION_OPTS"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# --- tmux-fzf: hand the shell's fzf settings to the pickers ---------------
# The pickers run in the tmux server (run-shell), which does not see this
# shell's environment — so TMUX_FZF_OPTIONS here is pushed into the session and
# global stores below. The plugin evals it, so the literal $FZF_COLORS inside
# expands when the picker starts.
#
# Styling is shared (one palette, one frame definition); only the geometry
# differs per GUI: the desktop popup keeps a preview pane, the narrow/mobile one
# goes near-fullscreen with inline info.
export TMUX_FZF_FRAME="--color=$FZF_COLORS --border=rounded --border-label=' fzf ' --border-label-pos=3 --separator='─'"
export TMUX_FZF_POPUP_FLAGS="-p -w 60% -h 60% -m --layout=reverse"
export TMUX_FZF_COMPACT_FLAGS="-p -w 96% -h 88% -m --info=inline --layout=reverse"
export TMUX_FZF_OPTIONS="$TMUX_FZF_POPUP_FLAGS $TMUX_FZF_FRAME --preview-window=right:50%:wrap"
# Narrow clients (< TMUX_FZF_COMPACT_WIDTH, default 140 — e.g. a phone over
# Termius) use this instead, so pinning TMUX_FZF_OPTIONS does not also pin the
# desktop geometry on the phone. Blank it to keep the built-in compact layout.
export TMUX_FZF_COMPACT_OPTIONS="$TMUX_FZF_COMPACT_FLAGS $TMUX_FZF_FRAME"
# For pickers with *exactly* the shell's options instead:
#     export TMUX_FZF_OPTIONS="$FZF_DEFAULT_OPTS"   (popup loses -p)

# update-environment is NOT an alternative: it copies from the *terminal's*
# environment, which never had these values (they are exported later, by the
# interactive shell). One var per call — set-environment takes a single
# name/value pair, even on tmux 3.8.
if [ -n "$TMUX" ]; then
    _tmfzf_session="$(tmux display-message -p '#S')"
    for _tmfzf_var in FZF_COLORS TMUX_FZF_OPTIONS TMUX_FZF_COMPACT_OPTIONS; do
        tmux set-environment -g "$_tmfzf_var" "${(P)_tmfzf_var}"
        tmux set-environment -t "$_tmfzf_session" "$_tmfzf_var" "${(P)_tmfzf_var}"
    done
    unset _tmfzf_session _tmfzf_var
fi

export RIPGREP_CONFIG_PATH=~/.config/.ripgreprc

eval "$(direnv hook zsh)"

function update_brach(){
  git checkout master && git pull && git checkout - && git rebase master
}

export TERMINFO="$HOME/.terminfo"

# homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
export HOMEBREW_AUTO_UPDATE_SECS=600000

# Change open files limit and user processes limit.
# See: https://gist.github.com/tombigel/d503800a282fcadbee14b537735d202c
ulimit -n 200000
ulimit -u 8192

# shared ssh-agent (systemd user service) — passphrase once per boot
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

export HOMEBREW_BAT=1
export HOMEBREW_DISPLAY_INSTALL_TIMES=1
export HOMEBREW_INSTALL_FROM_API=1

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# autostart tmux
if [[ -z "$TMUX" ]]; then
  local n=${1-Main}
  if tmux has-session -t $n 2>/dev/null; then
    exec tmux a -t $n
  else
    exec tmux new -s $n
  fi
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# asdf 0.20 (Go rewrite) ships no asdf.sh; integration is just its shims dir.
[[ -d "$HOME/.asdf/shims" ]] && export PATH="$HOME/.asdf/shims:$PATH"

eval "$(zsh-patina activate)"

# ROCm
export HSA_OVERRIDE_GFX_VERSION=10.3.0

# Python: pin python/python3/pip/pip3 to Homebrew python@3.13 (3.13.14).
# Brew's unversioned `python3` follows the newest python@ keg (3.14), so put
# python@3.13's unversioned shims first on PATH. Covers shebang scripts and
# non-interactive children too (aliases would not). The opt/ path is stable
# across brew upgrades; if the keg is ever removed, PATH falls through.
export PATH="/home/linuxbrew/.linuxbrew/opt/python@3.13/libexec/bin:$PATH"
export HCC_AMDGPU_TARGET=gfx1030

export HIP_VISIBLE_DEVICES=0
export GFX_ARCH=gfx1030
export ROCM_VERSION=10.1.0


export CMAKE_HIP_COMPILER=$(hipconfig -l)/clang++
export HIPCXX=$(hipconfig -l)/clang
export HIP_PATH=$(hipconfig -p)
# HIP_VISIBLE_DEVICES=0 (set above) selects the 6800 XT; do NOT set it to $(hipconfig -R):
# that returns a filesystem path, and an empty/invalid value hides ALL GPUs from PyTorch


# ROCm 10 devel headers/libs (global, hardlink copy of the rocm-sdk-devel wheel).
# Lets ANY project/venv source-build HIP packages (cupy, flash-attn, aiter...);
# survives venv deletion. CPATH/LIBRARY_PATH are compile-time only, no runtime effect.
source "$HOME/rocm-devel/env.sh"

# export PYTORCH_HIP_ALLOC_CONF=expandable_segments:True  # POISON: nondeterministic black/garbage renders on ROCm 10 nightly — proven 2026-09-13, do not enable

# export TORCH_BLAS_PREFER_HIPBLASLT=0
# export TORCH_BLAS_PREFER_CUBLASLT=1
export PYTORCH_ALLOC_CONF=garbage_collection_threshold:0.9,max_split_size_mb:512
export PATH=$PATH:/opt/rocm/bin
export PATH="/home/carakan/.local/bin:$PATH"
export PATH=/opt/rocm/bin:$PATH
export ROCM_HOME=/opt/rocm
export LD_LIBRARY_PATH=/opt/rocm/lib

