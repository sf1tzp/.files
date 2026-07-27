# Sourced by zsh - functions for working with git worktrees

: "${WORKTREE_DIR:="$HOME/worktrees"}"

# List local and remote branches (deduped, remote prefix stripped) in fzf.
# Prints the selection - or, if the typed query matches nothing, the query
# itself so callers can create a branch with that name. Fails on cancel.
function _select_branch() {
    local header="${1:-Select a branch, or type a new name}"
    local out ret
    out=$(command git branch -a --format='%(refname:short)' |
        command sed 's#^origin/##' |
        command grep -vx 'origin' |
        sort -u |
        fzf --print-query --ansi --reverse \
            --border --height=60% \
            --header="$header" \
            --prompt="Branch: ")
    ret=$?
    if [[ $ret -eq 130 ]]; then
        return 1
    fi

    local query selection
    query=$(command head -1 <<< "$out")
    selection=$(command sed -n '2p' <<< "$out")
    if [[ -n $selection ]]; then
        echo "$selection"
    elif [[ -n $query ]]; then
        echo "$query"
    else
        echo "No branch selected" >&2
        return 1
    fi
}

# Make sure a local branch exists for the given name and is attached to its
# remote counterpart when origin has one; otherwise branch off current HEAD.
function _ensure_local_branch() {
    local branch_name="$1"
    if command git show-ref --verify --quiet "refs/heads/$branch_name"; then
        if command git show-ref --verify --quiet "refs/remotes/origin/$branch_name" &&
            [[ -z $(command git for-each-ref --format='%(upstream)' "refs/heads/$branch_name") ]]; then
            command git branch --set-upstream-to="origin/$branch_name" "$branch_name"
        fi
    elif command git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
        command git branch --track "$branch_name" "origin/$branch_name"
    else
        echo "Creating new branch $branch_name"
        command git branch "$branch_name"
    fi
}

# fzf-checkout a local or remote branch (with tracking), or a typed new name.
function checkout_branch() {
    local branch_name
    branch_name=$(_select_branch) || return 1
    _ensure_local_branch "$branch_name" || return 1
    command git checkout "$branch_name"
}

function create_worktree() {
    # Resolve the repo name from the main worktree so this also works when
    # run from inside another worktree.
    local main_wt repo
    main_wt=$(command git worktree list --porcelain 2>/dev/null |
        command head -1 | command awk '{ print $2 }')
    if [[ -z $main_wt ]]; then
        echo "Not in a git repository"
        return 1
    fi
    repo=$(basename "$main_wt")

    command git fetch --prune || echo "Fetch failed; continuing with local refs"

    local branch_name
    branch_name=$(_select_branch) || return 1
    _ensure_local_branch "$branch_name" || return 1

    local wt_path="$WORKTREE_DIR/$repo/$branch_name"

    if [[ -d "$wt_path" ]]; then
        echo "Switching to worktree $branch_name at $wt_path"
        builtin cd "$wt_path"
    else
        echo "Creating worktree $branch_name at $wt_path"
        command git worktree add "$wt_path" "$branch_name" || return 1
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

    # git refuses to remove worktrees with initialized submodules, and --force
    # bypasses the dirty-tree check along with that refusal. Do the clean
    # check ourselves, then force past just the submodule complaint.
    local dirty
    dirty=$(command git -C "$wt_path" status --porcelain --ignore-submodules=none)
    if [[ -n $dirty ]]; then
        echo "Worktree at $wt_path has local changes; not removing:"
        echo "$dirty"
        return 1
    fi

    echo "Removing worktree at $wt_path"
    command git -C "$main_wt" worktree remove --force "$wt_path"
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
    # NB: not named `path` - in zsh that is tied to $PATH, and localizing
    # it empties the search path for the rest of the function.
    local -a to_remove
    local branch wt_path
    while IFS=$'\t' read -r branch wt_path; do
        [[ -z $branch ]] && continue
        [[ -n ${merged_set[$branch]} ]] && to_remove+=("$branch"$'\t'"$wt_path")
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
        wt_path=${entry#*$'\t'}
        printf "Branch '%s' is merged. Remove worktree %s? (y/N) " "$branch" "$wt_path"
        read -r reply
        if [[ $reply == [yY] ]]; then
            _remove_worktree_at "$wt_path"
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

alias branches='checkout_branch'
alias gct='create_worktree'
alias worktrees='goto_worktree'
alias wt='goto_worktree'
alias rmwt='remove_worktree'
alias gwr='goto_worktree_repo'

