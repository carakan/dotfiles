README
======

Repo for my custom zsh, tmux and vim setup across my multiple machines (works
very well on OSx, not sure on other OS).

Requirements
============

- Ohmyzsh

- Neovim
```
brew tap neovim/neovim             # only on first time
brew install neovim/neovim/neovim  # to get last STABLE version
brew install --HEAD neovim         # to get master changes
```
- install this theme for zsh:

```
cd ~/.oh-my-zsh/custom
git clone https://github.com/bhilburn/powerlevel9k.git themes/powerlevel9k
```

- Install patched fonts from:

https://g0ithub.com/powerline/fonts direct link:
https://github.com/powerline/fonts/archive/master.zip

unzip and run `./install.sh`

or simple download from this repository and install patched fonts

- install ack or silver search

when I used Ack that not found all of ocurrences and I swiched to `ag`

```
brew install the_silver_searcher
```

- install syntax highlighting

```
brew install zsh-syntax-highlighting 
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

UPDATE Notes
============

I changed to NeoVim because I have a lot of problems switching from insert mode
to normal, I researching a lot and I not found a valid solution for that, the
only solution for now is change using neovim, looks pretty well.

you need install python3:

```
brew install python3
pip3 install --upgrade pip setuptools
```

Install neovim plugin for python3
---------------------------------

```
pip3 install neovim
# to upgrade
pip3 install --upgrade neovim
```

when running nvim
```
:UpdateRemotePlugins
```

Install spf13
=============
run this on a terminal:

```
curl https://j.mp/spf13-vim3 -L > spf13-vim.sh && sh spf13-vim.sh
```

Recently I saw no changes into this great project, so I'm looking migrate to
plug.

Update spf13 plugins
====================

```
nvim +BundleInstall! +BundleClean +qall
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

I patched or adjust Iterm2 to enable Crtl-h over neovim using this:
https://github.com/neovim/neovim/issues/2048#issuecomment-98307896
