#!/bin/bash

set -o vi
if [ ! -L ~/.inputrc ]; then
	ln -s ~/.files/.inputrc ~/.inputrc
fi

export HOMEBREW_NO_ENV_HINTS=false

if [[ ${HOSTNAME} == *mac* || ${HOSTNAME} == *V-* || ${HOSTNAME} == *DESKTOP* ]]; then
	export PS1="\[\e[1;33m\]\u\[\e[m\]:\[\e[1;32m\]\w\[\e[m\]: "
else
	export PS1="\[\e[1;33m\]\u\[\e[1;37m\]@\[\e[1;32m\]\h\[\e[m\]:\[\e[1;37m\]\w\[\e[m\]: "
fi
export GOPATH=$HOME/go
export PATH="$PATH:$GOPATH/bin"

export PATH="${PATH:+${PATH}:}/usr/local/go/bin"
export PATH="${PATH:+${PATH}:}/usr/local/bat"
export PATH="${PATH:+${PATH}:}/usr/local/eza/bin"
export PATH="${PATH:+${PATH}:}/usr/local/nvim/bin"
export PATH="${PATH:+${PATH}:}/usr/local/nodejs/bin"

alias cim=vim
alias get='git'
alias git-log='git log --date=short --pretty="%h  %cd  %s"'
alias git-out='git commit --amend --date="$(date -R)" --no-edit; git push --force-with-lease'
alias git-fetch-checkout='git fetch; git checkout'
alias gl='git-log'
alias git-fetch-rebase='git fetch; git rebase -i'
alias gd='git diff'
alias gs='git status'
alias gfs='git fetch; git status'
alias gfc='git-fetch-checkout'
alias gfr='git-fetch-rebase'
alias grc='git rebase --continue'
alias repo='git rev-parse --show-toplevel'
alias branch='git branch --show-current'
alias gum='git checkout main && git reset --hard origin/main'
alias gtfo='git-out'

alias clera="clear"
alias watch="watch "
alias pipes="pipes.sh"
alias azl='az login --use-device-code'

if [ -d ~/.pyenv ]; then
	export PYENV_ROOT="$HOME/.pyenv"
	export PATH="$PYENV_ROOT/bin:$PATH"
	eval "$(pyenv init --path --no-rehash)"
	eval "$(pyenv init - --no-rehash)"
	eval "$(pyenv virtualenv-init - --no-rehash)"
fi

if command -v cargo &>/dev/null; then
	alias cargo-watch='cargo watch -q -c -w src/ -x run'
fi

if command -v just &>/dev/null; then
	source <(just --completions bash)
	alias j='just'
	alias jsut='just'
fi

if command -v starship &>/dev/null; then
	eval "$(starship init bash)"
fi

if command -v nvm &>/dev/null; then
	export NVM_DIR="$HOME/.nvm"
	[ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"                                       # This loads nvm
	[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/usr/local/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion
fi

if command -v nvim &>/dev/null; then
	export EDITOR='nvim'
	export VISUAL='nvim'

	alias vim='nvim'
fi

if command -v bat &>/dev/null; then
	alias cat='bat -p --paging=never'
	alias b='bat_in_language'
fi

if command -v eza &>/dev/null; then
	alias ls='eza -la --group-directories-first'
	alias lt='eza -lDTL 2'
	alias tree='eza -T'
fi

if command -v pacman &>/dev/null; then
	alias p='pacman'
	alias packman='pacman'
fi

if command -v rg &>/dev/null; then
	alias grep='rg'
fi

if command -v fzf &>/dev/null; then
	[ -f ~/.files/fzf.bash ] && source ~/.files/fzf.bash
	alias branches='git checkout $(git branch -a | fzf)'
fi

if command -v glow &>/dev/null; then
	alias glow='PAGER=bat glow -p'
fi

if [ -f /usr/local/bin/z.sh ]; then
	source /usr/local/bin/z.sh
fi

if [ ! -L ~/.config/alacritty.yml ]; then
	mkdir -p ~/.config
	ln -s ~/.files/alacritty.yml ~/.config/alacritty.yml
fi

if command -v kubectl &>/dev/null; then
	source $HOME/.files/k8s
	source $HOME/.files/k8s-logs.sh
fi

if command -v tmux &>/dev/null; then
	alias tumx='tmux'
fi

if command -v shellcheck &>/dev/null; then
	if [ ! -L ~/.shellcheckrc ]; then
		ln -s ~/.files/shellcheckrc ~/.shellcheckrc
	fi
fi

source $HOME/.files/functions
source $HOME/.files/worktrees.sh

