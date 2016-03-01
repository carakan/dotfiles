README
======

Repo for my custom zsh, tmux and vim setup across my multiple machines.

Requirements
============

- Ohmyzsh

- vim 
```
brew install vim --with-lua --with-luajit
```
- install this theme:

```
cd ~/.oh-my-zsh/custom
git clone https://github.com/bhilburn/powerlevel9k.git themes/powerlevel9k
```

- Install patched fonts from:

https://g0ithub.com/powerline/fonts direct link:
https://github.com/powerline/fonts/archive/master.zip

unzip and run `./install.sh`

- install ack or silver search

when I used Ack that not found all of ocurrences and I swiched to `ag`

```
brew install the_silver_searcher
brew install reattach-to-user-namespace
```

http://evertpot.com/osx-tmux-vim-copy-paste-clipboard/
https://gist.github.com/burke/5960455

- install reattach-to-user-namespace

```
brew install reattach-to-user-namespace
```

Install tmux with 24 bits support
=================================

```
    brew uninstall tmux
    brew tap choppsv1/term24
    brew install choppsv1/term24/tmux
```


UPDATE
======

I changed to NeoVim because I have a lot of problems switching from insert mode
to normal, I researching a lot and I not found a valid solution for that, the
only solution for now is change using neovim, look pretty well.

for that you need install python3:

```
brew install python3 
pip3 install --upgrade pip setuptools
```

when running nvim
```
:UpdateRemotePlugins
```

Update spf13 plugins
====================

```
cd $HOME/to/spf13-vim/
git pull
vim +BundleInstall! +BundleClean +q
```


Notes
=====

I patched or adjust Iterm2 to enable Crtl-h over neovim using this:
https://github.com/neovim/neovim/issues/2048#issuecomment-98307896
