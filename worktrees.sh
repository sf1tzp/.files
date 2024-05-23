#! /usr/bin/env bash

# A set of functions for working with git worktrees

: "${WORKTREE_DIR:="$HOME/worktrees"}"


function worktree() {
    repo=$(basename "$(git rev-parse --show-toplevel)")
    if [[ -z $repo ]]; then
        echo "Not in a git repository"
        return 1
    elif [[ $repo == *$WORKTREE_DIR* ]]; then
        echo "Already in a worktree, please run from the original repository location"
        return 1
    fi

    branch_name=$(git branch -a | fzf \
        --height=60% --border --ansi --reverse \
        --header="Select a branch" \
        --prompt="Branch: " | sed 's/^[ *+]*//' )

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
    fi
}
