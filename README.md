# README

My custom .dotfiles setup across my multiple machines (works
very well on OSx, not sure on other OS).

# Usage

See the [usage instructions](https://github.com/carakan/dotfiles/blob/master/USAGE.md)

# Requirements

- Ohmyzsh

- Neovim

```zsh
brew install neovim
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

https://github.com/ryanoasis/nerd-fonts/releases/tag/v1.0.0

or simple download and install fonts from directory fontpatched in this project

- install ripgrep and ctags

```zsh
brew install ripgrep
brew install --HEAD universal-ctags/universal-ctags/universal-ctags
```

- install syntax highlighting (this is added by default in last versions of zsh)

```zsh
brew install zsh-syntax-highlighting
brew install bat # for preview files
```

- install fzf

```zsh
brew install fzf
# Install shell extensions
/usr/local/opt/fzf/install
brew install git-cal
```

- install yarn (No option for that)
```
brew install yarn --without-node
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
pip install --upgrade pynvim
#ruby
gem install neovim
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

```
:call dein#update()
" if you added/removed some plugins you need to run this
:call map(dein#check_clean(), "delete(v:val, 'rf')")
```

# UPGRADE NPM

from npm > 5.4.x npm gets stability, to upgrade only do that:

`npm i -g npm`

# Install linters & LSP

```zsh
npm i -g eslint stylelint tslint typescript prettier neovim
npm i -g javascript-typescript-langserver
npm i -g vscode-html-languageserver-bin
npm i -g vscode-css-languageserver-bin
npm i -g vue-language-server
gem install solargraph
```

# Install Gems

```zsh
gem install reek rubocop
```

# Notes

- I patched or adjust Iterm2 to enable Crtl-h over neovim using this: https://github.com/neovim/neovim/issues/2048#issuecomment-98307896

- From MacOS Sierra ssh keys no longer added by default, I added a simple solution from https://github.com/lionheart/openradar-mirror/issues/15361 also you need to run this command for first time:

```zsh
ssh-add -K
```

- if you install my dotfiles you HAVE TO read this link to ensure all is working well:

https://github.com/neovim/neovim/wiki/FAQ

also, you can run `:checkhealth` into your neovim to check the health of this dotfiles

- Sometimes when install new versions of neovim or change plugins you need do a _Hard Reset_

```zsh
rm -rf ~/.vim/bundle/.cache
rm -rf ~/.vim/bundle/state_nvim.vim
rm -rf ~/.vim/bundle/cache_nvim
```

- Enable sign commits:

```zsh
git config --global commit.gpgsign true
```

- to install android SDK

```zsh
brew cask install android-sdk (--force)
```

- Remap caps lock to esc and Crtl
  I've used karabiner elements version 0.90.90 with this instructions https://github.com/tekezo/Karabiner-Elements/issues/8#issuecomment-251142033 new versions isn't working.~~
  This dotfiles work with last version of karabiner elements.

- [upgrade ssh keys](https://blog.g3rt.nl/upgrade-your-ssh-keys.html)
