#!/bin/bash

set -o vi

export HOMEBREW_NO_ENV_HINTS=true

if [[ ${HOSTNAME} == *mac* || ${HOSTNAME} == *V-* || ${HOSTNAME} == *DESKTOP* ]]; then
    export PS1="\[\e[1;33m\]\u\[\e[m\]:\[\e[1;32m\]\w\[\e[m\]: "
else
    export PS1="\[\e[1;33m\]\u\[\e[1;37m\]@\[\e[1;32m\]\h\[\e[m\]:\[\e[1;37m\]\w\[\e[m\]: "
fi

export EDITOR='nvim'
export VISUAL='nvim'

export GOPATH=$HOME/go
export PATH="$PATH:$GOPATH/bin"
export PATH="/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"
mkdir -p "$HOME/.config"

alias azl='az login --use-device-code'
alias cat='bat -p'
alias less='bat'
alias ls='exa -la'
alias lt='exa -lDTL 2'
alias grep='rg'
alias get='git'
alias git-log='git log --date=short --pretty="%h  %cd  %s"'
alias gl='git-log'
alias git-out='git commit --amend --date="$(date -R)" --no-edit; git push --force'
alias git-fetch-checkout='git fetch; git checkout'
alias git-fetch-rebase='git fetch; git rebase -i'
alias gs='git status'
alias gfs='git fetch; git status'
alias gfc='git-fetch-checkout'
alias gfr='git-fetch-rebase'
alias gl='git-log'
alias grc='git rebase --continue'
alias watch="watch "
alias pipes="pipes.sh"
alias neofetch="neofetch --config ~/.files/neofetch.conf"
alias gm="create-rg; dev64"
alias bslog="ssh rack1-control-node-01 -- sudo tail -f /var/log/cloud-init-output.log"
alias bskc="merge-kubeconfig ~/.kube/bootstrap-kubeconfig.yaml"
alias uckc="merge-kubeconfig ~/.kube/undercloud-kubeconfig.yaml"
alias vim="nvim"

if command -v pyenv &> /dev/null; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path --no-rehash)"
    eval "$(pyenv init - --no-rehash)"
    eval "$(pyenv virtualenv-init - --no-rehash)"
fi

if command -v cargo &> /dev/null; then
    alias cargo-watch='cargo watch -q -c -w src/ -x run'
fi

if command -v just &> /dev/null; then
    source <(just --completions bash)
fi

if command -v fzf &> /dev/null; then
    if [ ! -f "$HOME/.fzf.bash" ]; then
        $(brew --prefix)/opt/fzf/install --all
    fi
    source $HOME/.fzf.bash
fi

if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
    if [ ! -f "$HOME/.config/starship.toml" ] ; then
        ln -s $HOME/.files/starship.toml $HOME/.config/starship.toml
    fi
fi

. $(brew --prefix)/etc/profile.d/z.sh || true

source $HOME/.files/k8s
source $HOME/.files/functions

