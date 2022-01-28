alias ll='ls -la'
alias git-log='git log --date=short --pretty="%h  %cd  %s"'
alias git-out='git commit --amend --no-edit; git push --force'
alias gs='git status'
alias watch="watch "
alias pipes="pipes.sh"

if [[ ${HOSTNAME: -9} == 'mac.local' ]]; then
    export PS1="\[\e[1;33m\]\u\[\e[m\]:\[\e[1;32m\]\w\[\e[m\]: "
else
    export PS1="\[\e[1;33m\]\u\[\e[1;37m\]@\[\e[1;32m\]\h\[\e[m\]:\[\e[1;37m\]\w\[\e[m\]: "
fi

export GOPATH=$HOME/go
export PATH="$PATH:$GOPATH/bin"
alias go-here='export GOPATH=$GOPATH:$(pwd)'

export PATH="/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"

if command -v pyenv &> /dev/null; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

if command -v cargo &> /dev/null; then
    source "$HOME/.cargo/env"
fi
source $HOME/.files/k8s
