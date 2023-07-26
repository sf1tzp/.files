# Welcome to My Dotfiles! 💻

This is a collection of scripts and configuration files I like to keep track of and use.

## Shell Experience 🚀

Most of my development environments are on Ubuntu server. To get the environment set up, I've got [installs](./installs), which quickly grabs a variety of tools I use from day-to-day. For example:
- [tmux](https://github.com/tmux/tmux) for terminal management
- [starship](https://github.com/starship/starship) for an excellent terminal prompt
- [fzf](https://github.com/junegunn/fzf), [bat](https://github.com/sharkdp/bat), [exa](https://github.com/ogham/exa), [rg](https://github.com/BurntSushi/ripgrep), [fd](https://github.com/sharkdp/fd), [z](https://github.com/rupa/z) for interactive, colorful CLI tools
- [jq](https://github.com/jqlang/jq) for JSON scripting superpowers
- [kubectx](https://github.com/ahmetb/kubectx) for kubernetes context switching

I've also got a bunch of aliases and functions sourced in my [profile](./profile).

I still use `bash` as my shell because that's what's on ~~most~~ all of the servers I work on. But with the tools listed above, and [vi mode](https://www.gnu.org/software/bash/manual/html_node/Readline-vi-Mode.html), it doesn't feel like the stone age.

## Neovim 🕹️

Ahhhh [Neovim](https://github.com/neovim/neovim). I spent the first half of 2023 trying to use this exclusively. After a few months of going from scratch, [I adopted](https://github.com/sf1tzp/.files/commit/b8354334c0059891816a438db98f42fa4e71bd4d) [LazyVim](https://github.com/LazyVim/LazyVim) which is awesome.

But my configuration is on the backburner for now, since I was spending a bit too much time working on _it_ rather than getting things done 😅.

I miss the cohesive tmux + vim experience, but [vscode + neovim](https://github.com/vscode-neovim/vscode-neovim) has a pretty good alternative in the meantime.

## Set Up

```
git clone https://github.com/sf1tzp/.files.git
. .files/installs
install_stuff
echo ". ~/.files/profile" >> ~/.bashrc
. ~/.bashrc
```
