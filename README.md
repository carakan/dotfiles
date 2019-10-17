# README

My custom .dotfiles setup across my multiple machines (works
very well on OSx, not sure on other OS).

# Usage

See the [usage instructions](https://github.com/carakan/dotfiles/blob/master/USAGE.md)

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
bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring

asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf plugin-add yarn https://github.com/twuni/asdf-yarn.git
```

- install this theme for zsh:

```zsh
cd ~/.oh-my-zsh/custom
git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

cd ${ZSH_CUSTOM1:-$ZSH/custom}/plugins
git clone https://github.com/djui/alias-tips.git
git clone https://github.com/zsh-users/zsh-completions
git clone git://github.com/zsh-users/zsh-autosuggestions
```

- Install patched fonts from:

https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/VictorMono

or simple download and install fonts from directory fontpatched in this project

- install ripgrep and ctags

```zsh
brew install ripgrep
brew install --with-jansson universal-ctags/universal-ctags/universal-ctags
```

- install syntax highlighting (this is added by default in last versions of zsh)

```zsh
brew install zsh-syntax-highlighting
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

## Install tmux with 24 bits support

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

I use NeoVim because I have had a lot of problems switching from insert mode
to normal using vim, I researching a lot and I'm not found a valid solution for that, the only solution for now is change
to using neovim and looks more better/modern alternative.

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

# UPGRADE NPM

from npm > 5.4.x npm gets stability, to upgrade only do that:

```
npm i -g npm
```

# Install the bundle Homebrew

```zsh
brew bundle
```

# Notes

- To sync vscode _manually_ do this:

```zsh
# to backup:
code --list-extensions > vscode-extensions.list
# to restore
cat vscode-extensions.list |% { code --install-extension $_}
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
