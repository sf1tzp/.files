# Sourced by zsh - functions for working with git worktrees

: "${WORKTREE_DIR:="$HOME/worktrees"}"

function create_worktree() {
    repo=$(basename "$(command git rev-parse --show-toplevel)")
    if [[ -z $repo ]]; then
        echo "Not in a git repository"
        return 1
    elif [[ $repo == *$WORKTREE_DIR* ]]; then
        echo "Already in a worktree, please run from the original repository location"
        return 1
    fi

    branch_name=$(command git branch -a |
        fzf --ansi --reverse \
        --border --height=60% \
        --header="Select a branch" \
        --prompt="Search: " |
        sed 's/^[ *+]*//' )

    if [[ -z $branch_name ]]; then
        echo "No branch selected"
        return 1
    fi

    # If branch_name is a remote branch, create a local branch pointing to it (if one does not already exist)
    if [[ $branch_name == remotes/origin/* ]]; then
        branch_name=${branch_name#remotes/origin/}
        if ! command git branch | command grep -q "$branch_name"; then
            command git fetch origin "$branch_name:$branch_name"
        fi
    fi

    local wt_path="$WORKTREE_DIR/$repo/$branch_name"

    if [[ -d "$wt_path" ]]; then
        echo "Switching to worktree $branch_name at $wt_path"
        builtin cd "$wt_path"
    else
        echo "Creating worktree $branch_name at $wt_path"
        command git worktree add "$wt_path" "$branch_name"
        builtin cd "$wt_path"
        command git submodule update --init
    fi
}

function goto_worktree() {
    pushd "$WORKTREE_DIR" &> /dev/null

    worktree=$(fd -H -p -E common-tools .git$ | sort |
        sed 's#/.git##; s#/# > #' |
        fzf --ansi --reverse \
        --border --height=60% \
        --header="Select a worktree" \
        --prompt="Search:  " |
        sed 's# > #/#')

    popd &> /dev/null

    if [[ -z $worktree ]]; then
        echo "No worktree selected"
        return 1
    fi

    local wt_path="$WORKTREE_DIR/$worktree"
    if [[ -d "$wt_path" ]]; then
        echo "Switching to worktree at $wt_path"
        builtin cd "$wt_path"
    fi
}

# Remove a single worktree by absolute path, running git from the main worktree
# so we never try to remove the tree git is currently sitting in.
function _remove_worktree_at() {
    local wt_path="$1"

    if [[ ! -d "$wt_path" ]]; then
        echo "Worktree not found: $wt_path"
        return 1
    fi

    local main_wt
    main_wt=$(command git -C "$wt_path" worktree list --porcelain |
        command head -1 | command awk '{ print $2 }')

    # If we are currently inside the worktree being removed, move out first
    if [[ "$PWD" == "$wt_path"* ]]; then
        builtin cd "$main_wt"
    fi

    echo "Removing worktree at $wt_path"
    command git -C "$main_wt" worktree remove "$wt_path"
}

function remove_worktree() {
    pushd "$WORKTREE_DIR" &> /dev/null

    worktree=$(fd -H -p -E common-tools .git$ | sort |
        sed 's#/.git##; s#/# > #' |
        fzf --ansi --reverse \
        --border --height=60% \
        --header="Select a worktree to remove" \
        --prompt="Search:  " |
        sed 's# > #/#')

    popd &> /dev/null

    if [[ -z $worktree ]]; then
        echo "No worktree selected"
        return 1
    fi

    _remove_worktree_at "$WORKTREE_DIR/$worktree"
}

# Find worktrees whose branch has been squash-merged (via Gitea/tea) and
# prompt to remove each one.
function prune_worktrees() {
    if ! command -v tea &> /dev/null; then
        echo "tea CLI not found - install it via shell/scripts/install.py"
        return 1
    fi

    local toplevel
    toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z $toplevel ]]; then
        echo "Not in a git repository"
        return 1
    fi

    # tea's --state only accepts all|open|closed; "merged" is a value in the
    # state column, so list closed PRs and keep the ones actually merged.
    echo "Fetching merged pull requests from Gitea..."
    local merged
    merged=$(tea pr list --state closed --fields head,state \
        --output tsv --limit 9999 2>/dev/null |
        awk -F'\t' 'tolower($2)=="merged" { print $1 }')
    if [[ -z $merged ]]; then
        echo "No merged pull requests found (is tea configured for this repo?)"
        return 1
    fi

    # Index merged branch names for O(1) lookup without relying on grep.
    local -A merged_set
    local line
    while IFS= read -r line; do
        [[ -n $line ]] && merged_set[$line]=1
    done <<< "$merged"

    # Collect merged worktrees up front. Prompting inside a `while read` loop
    # that is fed by a pipe/here-string would steal the user's keystrokes from
    # the loop's stdin, so gather matches first, then prompt with a free stdin.
    # (Detached worktrees have no branch line and are skipped.)
    local -a to_remove
    local branch path
    while IFS=$'\t' read -r branch path; do
        [[ -z $branch ]] && continue
        [[ -n ${merged_set[$branch]} ]] && to_remove+=("$branch"$'\t'"$path")
    done < <(git -C "$toplevel" worktree list --porcelain |
        awk '
            $1=="worktree" { path=$2 }
            $1=="branch"   { b=$2; sub("refs/heads/","",b); print b "\t" path }
        ')

    if [[ ${#to_remove[@]} -eq 0 ]]; then
        echo "No merged worktrees found"
        return 0
    fi

    local entry reply
    for entry in "${to_remove[@]}"; do
        branch=${entry%%$'\t'*}
        path=${entry#*$'\t'}
        printf "Branch '%s' is merged. Remove worktree %s? (y/N) " "$branch" "$path"
        read -r reply
        if [[ $reply == [yY] ]]; then
            _remove_worktree_at "$path"
        else
            echo "Skipping $branch"
        fi
    done
}

function goto_worktree_repo() {
    if [[ -f .git ]]; then
        local wt_path=$(awk '{ print $2 }' .git | sed 's#.git/.*##')
        echo "Switching to repo at $wt_path"
        builtin cd "$wt_path"
    else
        echo "Not in a worktree"
    fi
}

alias gct='command git fetch; create_worktree'
alias worktrees='goto_worktree'
alias wt='goto_worktree'
alias rmwt='remove_worktree'
alias gwr='goto_worktree_repo'

