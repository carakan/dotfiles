# README

My custom .dotfiles setup across my multiple machines (works
very well on OSx, not sure on other OS).

# Usage

See the [usage instructions](https://github.com/carakan/dotfiles/blob/master/USAGE.md)

# Window Management (yabai + skhd)

[yabai](https://github.com/asmvik/yabai) is a tiling window manager for macOS.
[skhd](https://github.com/koekeishiya/skhd) is the keyboard daemon that binds
global shortcuts to yabai commands.

## Setup

```zsh
brew install yabai skhd jq
```

Config lives in `config/yabai/` and is symlinked by dotbot:

| File | Purpose |
|------|---------|
| `yabairc` | yabai config (spaces, rules, layout, signals) |
| `skhdrc` | keyboard shortcuts |
| `update_border_color.sh` | border color by window count |
| `update_fullscreen.sh` | auto fullscreen when only 1 window in a space |
| `save_layout.sh` | snapshot current window layout |
| `restore_layout.sh` | restore saved window layout |

LaunchAgents are at `~/Library/LaunchAgents/com.asmvik.yabai.plist` and
`~/Library/LaunchAgents/com.koekeishiya.skhd.plist`.

## Shortcuts

All shortcuts are **global** (system-wide). skhd must be running.

### Window Navigation

| Shortcut | Action |
|----------|--------|
| `alt - h` | Focus west |
| `alt - j` | Focus south |
| `alt - k` | Focus north |
| `alt - l` | Focus east |

### Window Warp (move window into another container)

| Shortcut | Action |
|----------|--------|
| `shift + alt - h` | Warp west |
| `shift + alt - j` | Warp south |
| `shift + alt - k` | Warp north |
| `shift + alt - l` | Warp east |

### Move Window to Space

| Shortcut | Action |
|----------|--------|
| `shift + alt - 1..9` | Send window to space 1..9 |

### Focus Space

| Shortcut | Action |
|----------|--------|
| `ctrl - 1..9` | Switch to space 1..9 |

### Resize

| Shortcut | Action |
|----------|--------|
| `ctrl + alt - h` | Resize left (expand) |
| `ctrl + alt - j` | Resize bottom (expand) |
| `ctrl + alt - k` | Resize top (expand) |
| `ctrl + alt - l` | Resize right (expand) |
| `shift + alt - a` | Resize left (expand) |
| `shift + alt - s` | Resize bottom (expand) |
| `shift + alt - w` | Resize top (expand) |
| `shift + alt - d` | Resize right (expand) |
| `shift + cmd - a` | Resize left (shrink) |
| `shift + cmd - s` | Resize bottom (shrink) |
| `shift + cmd - w` | Resize top (shrink) |
| `shift + cmd - d` | Resize right (shrink) |

### Move (floating windows)

| Shortcut | Action |
|----------|--------|
| `shift + ctrl - a` | Move left |
| `shift + ctrl - s` | Move down |
| `shift + ctrl - w` | Move up |
| `shift + ctrl - d` | Move right |

### Insertion Point

| Shortcut | Action |
|----------|--------|
| `shift + ctrl + alt - h` | Insert west |
| `shift + ctrl + alt - j` | Insert south |
| `shift + ctrl + alt - k` | Insert north |
| `shift + ctrl + alt - l` | Insert east |

### Layout

| Shortcut | Action |
|----------|--------|
| `shift + alt - z` | BSP layout |
| `shift + alt - x` | Float layout |
| `shift + alt - s` | Stack layout |
| `shift + alt - 0` | Balance windows |
| `alt - e` | Toggle split orientation |
| `alt - m` | Mirror layout (x-axis) |

### Window Toggles

| Shortcut | Action |
|----------|--------|
| `shift + alt - space` | Float / unfloat |
| `shift + alt - c` | Float and center |
| `ctrl + alt - p` | Sticky + picture-in-picture |
| `alt - d` | Zoom parent container |
| `alt - f` | Zoom fullscreen |
| `shift + alt - f` | Native macOS fullscreen |

### Floating Grids

| Shortcut | Action |
|----------|--------|
| `shift + alt - up` | Fill screen |
| `shift + alt - left` | Left third |
| `shift + alt - right` | Right third |
| `shift + alt - down` | Center third |

### Display (multi-monitor)

| Shortcut | Action |
|----------|--------|
| `ctrl + alt - z` | Focus recent display |
| `ctrl + cmd - c` | Send window to next display and follow |

### Layout Save/Restore

| Shortcut | Action |
|----------|--------|
| `ctrl + alt - s` | Save current window layout |
| `ctrl + alt - r` | Restore saved window layout |

## Auto-fullscreen

When a space has exactly **1 window**, yabai automatically removes padding and
gap and hides borders so the window fills the screen like native fullscreen.
When a second window appears, padding/gap and borders are restored.

## Spaces

| Space | Label | Purpose |
|-------|-------|---------|
| 1 | `1_work` | Email clients |
| 2 | `2_webs` | Browsers |
| 3 | `3_email` | Terminal (kitty) |
| 4 | `4_code` | VS Code |
| 5 | `5_temp` | Media/AI tools (float) |
| 6 | `6_temp` | Utilities (float) |
| 7 | `7_temp` | Comms/VPN (float) |
| 8 | `8_temp` | Firefox/Spotify (display 2) |
| 9 | `9_other` | Overflow |

# Requirements

- install [Oh My Zsh](https://github.com/robbyrussell/oh-my-zsh)

- Neovim

```zsh
brew install neovim
```

- install ASDF (package version)

```zsh
brew install asdf
```

register asdf plugins:

```zsh
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf plugin-add yarn
asdf plugin add bun

#install the certificates to install properly nodejs
brew install gpg
bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
```

- install this theme for zsh:

```zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

cd ${ZSH_CUSTOM:-$ZSH/custom}/plugins
git clone https://github.com/djui/alias-tips
git clone https://github.com/zsh-users/zsh-completions
git clone https://github.com/zsh-users/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting
```

- Install patched fonts from:

https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/VictorMono

or simple download and install fonts from directory fontpatched in this project

- install ripgrep and ctags

```zsh
brew install ripgrep
brew install universal-ctags
```


```zsh
brew install bat
brew install htop
```

- install fzf

```zsh
brew install fzf
/usr/local/opt/fzf/install
brew install git-cal
```

# Install dotfiles

```zsh
cd ~
git clone https://github.com/carakan/dotfiles ~/.dotfiles
cd ~/.dotfiles
./install
```

## Install tmux + TPM with 24 bits support

Install TPM

```zsh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Only needs install tmux >= 2.2, this dotfiles is working with tmux 2.4

to test run this script in a tmux panel:

```zsh
awk 'BEGIN{
    s="/\\/\\/\\/\\/\\"; s=s s s s s s s s;
    for (colnum = 0; colnum<77; colnum++) {
        r = 255-(colnum*255/76);
        g = (colnum*510/76);
        b = (colnum*255/76);
        if (g>255) g = 510-g;
        printf "\033[48;2;%d;%d;%dm", r,g,b;
        printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
        printf "%s\033[0m", substr(s,colnum+1,1);
    }
    printf "\n";
}'
```

~~I use NeoVim because I have had a lot of problems switching from insert mode
to normal using vim, I researching a lot and I'm not found a valid solution for
that, the only solution for now is change to neovim and looks more better/modern
alternative.~~

This setup is for NeoVim.

So you need to install python (3):

```zsh
brew install python
pip install --upgrade pip setuptools
```

## Install neovim plugin for python and ruby

```zsh
# To upgrade to new package pynvim
pip3 uninstall neovim
pip3 uninstall pynvim
pip3 install pynvim
# to upgrade
pip3 install --upgrade pynvim
```

- could need to run sometimes this command, to register new plugins

```
:UpdateRemotePlugins
```

# Install supra-vim

run this on a terminal:

```zsh
curl https://raw.githubusercontent.com/carakan/supra-vim/master/bootstrap.sh -L > supra-vim.sh && sh supra-vim.sh
```

# Update vim plugins

call into vim:

```vim
:call dein#update()
" if you added/removed some plugins you need to run this
:call map(dein#check_clean(), "delete(v:val, 'rf')")
```

# Install the bundle Homebrew

```zsh
brew bundle dump # to create/update Brewfile
brew bundle      # to install packages

```

# Notes

- To sync vscode _manually_ do this:

```zsh
# to backup:
code --list-extensions > vscode-extensions.list
# to restore
bat vscode-extensions.list --plain | xargs -L 1 code --install-extension 
```

- From MacOS Sierra ssh keys no longer added by default, I added a simple solution from https://github.com/lionheart/openradar-mirror/issues/15361 also you need to run this command for first time:

```zsh
ssh-add -K
```

- if you install my dotfiles you HAVE TO read this link to ensure all is working well:

https://github.com/neovim/neovim/wiki/FAQ

also, you can run `:checkhealth` into your neovim to check the health of this dotfiles

- Enable sign commits:

```zsh
git config --global commit.gpgsign true
```

- to install android SDK

```zsh
brew cask install android-sdk (--force)
```

- To edit charcoal shades preferences:

```zsh
# decode to xml
plutil -convert xml1 ~/Library/Preferences/com.charcoaldesign.shades.plist
# edit
code ~/Library/Preferences/com.charcoaldesign.shades.plist
# compile to binary
plutil -convert binary1 ~/Library/Preferences/com.charcoaldesign.shades.plist
```

- [upgrade ssh keys](https://blog.g3rt.nl/upgrade-your-ssh-keys.html)

# Spotlight indexing

Spotlight indexing is turned ON by `macos.sh` to build the initial index, then
disabled manually once the build completes. This saves CPU (`mds_stores` stops
watching for file changes) while keeping the existing index searchable — Alfred
and `mdfind` continue to work.

## Disable indexing without losing the index

```zsh
sudo mdutil -i off /System/Volumes/Data
```

The index is preserved and remains searchable. Only the background file-watcher
is paused. Verify:

```zsh
mdutil -s /System/Volumes/Data                    # "Indexing disabled."
mdfind -name 'kMDItemKind == "Application"' | wc -l  # still returns results
```

Newly installed apps won't appear in Alfred/Spotlight until you re-enable
temporarily to refresh.

## Refresh the index on demand

```zsh
sudo mdutil -i on /System/Volumes/Data
# wait for indexing to finish (check with):
mdutil -s /System/Volumes/Data
# once caught up, disable again:
sudo mdutil -i off /System/Volumes/Data
```

## Rebuild from scratch (erases the index)

```zsh
sudo mdutil -i on /System/Volumes/Data
sudo mdutil -E /System/Volumes/Data
# leave indexing ON until the rebuild completes, then disable if desired
```

## Pitfalls

- `killall mds` — can corrupt the index and trigger reindex storms. Never use.
- `mdutil -E` alone — erases the index. Only use when you want a full rebuild.
- `mdutil -X` — disables searching too (Alfred breaks). Use `-i off` instead.
- Only targeting `/` — on APFS, user files live on `/System/Volumes/Data`.
  Always include the data volume.
