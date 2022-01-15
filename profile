export PS1="\[\e[1;33m\]\u\[\e[m\]:\[\e[1;32m\]\w\[\e[m\]: "

alias ll='ls -la'
alias git-log='git log --date=short --pretty="%h  %cd  %s"'
alias git-out='git commit --amend --no-edit; git push --force'
alias watch="watch "

alias pipes="pipes.sh"

export GOPATH=$HOME/go
export PATH="$PATH:$GOPATH/bin"
alias go-here='export GOPATH=$GOPATH:$(pwd)'

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

source "$HOME/.cargo/env"
source $HOME/.files/k8s
