README
======

M custom zsh, tmux and vim setup across my multiple machines (works
very well on OSx, not sure on other OS).

Requirements
============

- Ohmyzsh 

- Neovim
```
brew tap neovim/neovim             # only on first time
brew install neovim/neovim/neovim  # to install last STABLE version
```
- install this theme for zsh:

```
cd ~/.oh-my-zsh/custom
git clone https://github.com/bhilburn/powerlevel9k.git themes/powerlevel9k
git clone git://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
```

- Install patched fonts from:

https://github.com/ryanoasis/nerd-fonts/releases/tag/v1.0.0

or simple download and install fonts from directory fontpatched in this project

- install silver search and ripgrep

```
brew install the_silver_searcher
brew install ripgrep
```

- install syntax highlighting (this is added by default in last versions of zsh)

```
brew install zsh-syntax-highlighting 
brew install highlight
```

- install reattach-to-user-namespace

http://evertpot.com/osx-tmux-vim-copy-paste-clipboard/
https://gist.github.com/burke/5960455

```
brew install reattach-to-user-namespace
```

Install dotfiles
================

```
cd ~
git clone https://github.com/carakan/dotfiles ~/.dotfiles
cd ~/.dotfiles
./install
```

Install tmux with 24 bits support
---------------------------------
Only needs install tmux >= 2.2

to test run this script in a tmux panel:
```
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


I use NeoVim because I have a lot of problems switching from insert mode
to normal using vim, I researching a lot and I not found a valid solution for that, the
only solution for now is change using neovim, looks pretty well.

you need install python3:

```
brew install python3
pip3 install --upgrade pip setuptools
```

Install neovim plugin for python3 and ruby
---------------------------------

```
pip3 install neovim
# to upgrade
pip3 install --upgrade neovim

#ruby
gem install neovim
```

Install supra-vim
=============
run this on a terminal:

```
" Still working on some awesome installer
```

Update vim plugins
====================
call into vim:

```
:call dein#update()
" if you added/removed some plugins you need to run this
:call map(dein#check_clean(), "delete(v:val, 'rf')")
```

Install linters
===============
```
npm install -g jscs
npm install -g jshint
npm install -g eslint
npm install -g stylelint
npm install -g csslint
npm install -g typescript 
```

Install some Gems
=================

```
rvm @global do gem install reek rubocop
```

Notes
=====

- I patched or adjust Iterm2 to enable Crtl-h over neovim using this: https://github.com/neovim/neovim/issues/2048#issuecomment-98307896

- From MacOS Sierra ssh keys no longer added by default, I added a simple solution from https://github.com/lionheart/openradar-mirror/issues/15361 also you need to run this command for first time:

```
ssh-add -K
```

- if you install my dotfiles you HAVE TO read this link to ensure all is working well:

https://github.com/neovim/neovim/wiki/FAQ

also, you can run `:CheckHealth` into your neovim to check the health of this dotfiles

- sometimes when install new versions of neovim or change plugins you need do a *Hard Reset*
```
rm -rf ~/.vim/bundle/.cache
rm -rf ~/.vim/bundle/state_nvim.vim
rm -rf ~/.vim/bundle/cache_nvim
```
