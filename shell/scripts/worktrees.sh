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

# $WORKTREE_DIR, absolute and with symlinks resolved - the only directory
# these functions are ever allowed to delete from.
function _worktree_root() {
    if [[ -d "$WORKTREE_DIR" ]]; then
        (builtin cd "$WORKTREE_DIR" && pwd -P)
    else
        echo "$WORKTREE_DIR"
    fi
}

# Delete the local branch a just-removed worktree was holding. Without this
# `git branch` fills up with refs to work that is long gone, each dragging a
# stale [branch "..."] config section behind it - git drops the section along
# with the ref, so deleting the branch is what clears the config too.
#
# `git branch -d` refuses a branch that is not merged into HEAD, and a
# squash-merged branch never is - the shape gitea gives us - so a caller that
# has already confirmed the branch landed passes force to get -D. A caller
# that has not confirmed it asks, and keeps the branch on anything but yes.
function _remove_branch() {
    local branch="$1" main_wt="$2" force="$3"

    # A detached worktree holds no branch; nothing to clean up.
    [[ -z $branch ]] && return 0

    # Never delete the trunk along with a worktree, however merged it looks -
    # a worktree that had main checked out is a mistake to undo, not a branch
    # to delete. origin/HEAD names it when the remote has been queried; not
    # every clone has it, hence the fallbacks.
    local trunk
    trunk=$(command git -C "$main_wt" symbolic-ref --quiet --short \
        refs/remotes/origin/HEAD 2>/dev/null) || trunk=""
    trunk=${trunk#origin/}
    if [[ $branch == "$trunk" || $branch == main || $branch == master ]]; then
        echo "Keeping branch '$branch' - that is the trunk"
        return 0
    fi

    local out
    if out=$(command git -C "$main_wt" branch -d "$branch" 2>&1); then
        echo "$out"
        return 0
    fi

    if [[ -n $force ]]; then
        command git -C "$main_wt" branch -D "$branch"
        return $?
    fi

    # git's own refusal already names the commits at risk and the -D escape
    # hatch, so show it rather than paraphrasing.
    echo "$out"
    local reply
    printf "Delete branch '%s' anyway? (y/N) " "$branch"
    read -r reply
    if [[ $reply == [yY] ]]; then
        command git -C "$main_wt" branch -D "$branch"
    else
        echo "Keeping branch '$branch'"
    fi
}

# Remove a single worktree by absolute path, running git from the main worktree
# so we never try to remove the tree git is currently sitting in. Takes the
# branch with it - forcing the delete only when $2 says the branch has landed.
function _remove_worktree_at() {
    local wt_path="$1"
    local force_branch="$2"

    if [[ ! -d "$wt_path" ]]; then
        echo "Worktree not found: $wt_path"
        return 1
    fi

    # The primary checkout is itself a worktree as far as `git worktree list`
    # is concerned, so a caller can hand us the repo we work out of. Nothing
    # outside $WORKTREE_DIR is ours to delete - compare resolved paths so a
    # symlinked $HOME can't smuggle one past the check.
    local root real
    root=$(_worktree_root)
    real=$(builtin cd "$wt_path" && pwd -P)
    if [[ "$real" != "$root"/* ]]; then
        echo "Refusing to remove $wt_path: outside $root"
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

    # Read the branch while the worktree is still there to ask. A detached
    # worktree has none, and symbolic-ref exits non-zero saying so.
    local branch
    branch=$(command git -C "$wt_path" symbolic-ref --quiet --short HEAD \
        2>/dev/null) || branch=""

    echo "Removing worktree at $wt_path"
    command git -C "$main_wt" worktree remove --force "$wt_path" || return 1

    _remove_branch "$branch" "$main_wt" "$force_branch"
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
    local branch wt_path root
    root=$(_worktree_root)
    while IFS=$'\t' read -r branch wt_path; do
        [[ -z $branch ]] && continue
        # Skip the primary checkout and anything else living outside
        # $WORKTREE_DIR; it is not a worktree we created and not ours to
        # offer up for deletion, however merged its branch looks.
        [[ "$wt_path" == "$root"/* ]] || continue
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
        printf "Branch '%s' is merged. Remove worktree %s and the branch? (y/N) " \
            "$branch" "$wt_path"
        read -r reply
        if [[ $reply == [yY] ]]; then
            # gitea says this one is merged, so -d's refusal is expected noise.
            _remove_worktree_at "$wt_path" merged
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

