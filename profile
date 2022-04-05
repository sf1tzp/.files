alias ll='ls -la'
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
alias watch="watch "
alias pipes="pipes.sh"
alias tf="fuck"

if [[ ${HOSTNAME} == *mac* ]]; then
    export PS1="\[\e[1;33m\]\u\[\e[m\]:\[\e[1;32m\]\w\[\e[m\]: "
else
    export PS1="\[\e[1;33m\]\u\[\e[1;37m\]@\[\e[1;32m\]\h\[\e[m\]:\[\e[1;37m\]\w\[\e[m\]: "
fi

export EDITOR='vim'
export VISUAL='vim'

export GOPATH=$HOME/go
export PATH="$PATH:$GOPATH/bin"
alias go-here='export GOPATH=$GOPATH:$(pwd)'

export PATH="/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"

if command -v pyenv &> /dev/null; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path --no-rehash)"
    eval "$(pyenv init - --no-rehash)"
    eval "$(pyenv virtualenv-init - --no-rehash)"
fi

if command -v cargo &> /dev/null; then
    source "$HOME/.cargo/env"
fi
source $HOME/.files/k8s
