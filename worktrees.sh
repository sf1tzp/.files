#! /usr/bin/env bash

# A set of functions for working with git worktrees

: "${WORKTREE_DIR:="$HOME/worktrees"}"

function create_worktree() {
    repo=$(basename "$(git rev-parse --show-toplevel)")
    if [[ -z $repo ]]; then
        echo "Not in a git repository"
        return 1
    elif [[ $repo == *$WORKTREE_DIR* ]]; then
        echo "Already in a worktree, please run from the original repository location"
        return 1
    fi

    branch_name=$(git branch -a |
        fzf --ansi --reverse \
        --border --height=60% \
        --header="Select a branch" \
        --prompt="Search: " |
        sed 's/^[ *+]*//' ) # Using sed here to remove the git indicators

    if [[ -z $branch_name ]]; then
        echo "No branch selected"
        return 1
    fi

    # if brach_name is a remote branch, create a local branch pointin to it (if one does not already exist)
    if [[ $branch_name == remotes/origin/* ]]; then
        branch_name=${branch_name#remotes/origin/}
        if [[ ! $(git branch | grep -q "$branch_name") ]]; then
            git fetch origin "$branch_name:$branch_name"
        fi
    fi

    path="$WORKTREE_DIR/$repo/$branch_name"

    if [[ -d "$path" ]]; then
        echo "Switching to worktree $branch_name at $path"
        cd "$path"
    else
        echo "Creating worktree $branch_name at $path"
        git worktree add "$path" "$branch_name"
        cd "$path"
        git submodule update --init
    fi
}

function goto_worktree() {
    # Go to the worktrees to make the paths shorter in fzf
    pushd "$WORKTREE_DIR" &> /dev/null

    # Using sed here to make the names a little easier to read
    worktree=$(fd -H -p -E common-tools .git$ | sort |
        sed 's#/.git##; s#/# > #' |
        fzf --ansi --reverse \
        --border --height=60% \
        --header="Select a worktree" \
        --prompt="Search:  " |
        sed 's# > #/#')

    # Go back to starting place in case one wasn't selected
    popd &> /dev/null

    if [[ -z $worktree ]]; then
        echo "No worktree selected"
        return 1
    fi

    path="$WORKTREE_DIR/$worktree"
    if [[ -d "$path" ]]; then
        echo "Switching to worktree at $path"
        cd "$path"
    fi
}

function goto_worktree_repo() {
    # If we're in a worktree, look for the .git file.
    if [[ -f .git ]]; then
        path=$(awk '{ print $2 }' .git | sed 's#.git/.*##') # use sed to remove the .git components of the path, eg $repo/.git/worktrees/.../
        echo "Switching to repo at $path"
        cd "$path"
    else
        echo "Not in a worktree"
    fi
}

alias gct='git fetch; create_worktree' # git create worktree
alias worktrees='goto_worktree'
alias gwr='goto_worktree_repo'
