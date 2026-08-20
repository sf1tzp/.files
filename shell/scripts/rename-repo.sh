#!/usr/bin/env bash
# Rename a local repo checkout after its remote repository was renamed.
#
# Handles everything a rename touches on one machine:
#   1. origin remote URL (derived from the new name, or given explicitly)
#   2. the main checkout directory (renamed in place, same parent)
#   3. the per-repo worktree directory under $WORKTREE_DIR, plus
#      `git worktree repair` so main checkout and worktrees relink
#   4. Claude Code project dirs (~/.claude/projects/<path-slug>) so
#      per-project memory and history follow the new paths
#
# Usage: rename-repo.sh [-y] <repo-dir> <new-name> [new-remote-url]
#
#   rename-repo.sh ~/PrimeTime moment-tally
#   rename-repo.sh ~/primetime-website moment-tally-website \
#       ssh://git@gitea.zen.lofi:30022/sfi/moment-tally-website.git
#
# The remote URL is derived by swapping the old directory name for the new
# one in origin's last path component; pass the URL explicitly when the
# repo name and directory name differ. Run once per repo per machine.
set -euo pipefail

: "${WORKTREE_DIR:="$HOME/worktrees"}"
: "${CLAUDE_PROJECTS_DIR:="$HOME/.claude/projects"}"

usage() {
    cat >&2 << 'EOF'
Usage: rename-repo.sh [-y] <repo-dir> <new-name> [new-remote-url]

Renames a local checkout after its remote repo was renamed: origin URL,
checkout directory, $WORKTREE_DIR/<repo> worktrees (with repair), and
Claude Code project dirs. Pass the remote URL explicitly when the repo
name and directory name differ. -y skips the confirmation prompt.
EOF
    exit 1
}

die() {
    echo "Error: $*" >&2
    exit 1
}

# Claude Code names project dirs after the absolute path with every
# non-alphanumeric character replaced by '-'.
slug() {
    printf '%s' "$1" | sed 's#[^a-zA-Z0-9]#-#g'
}

assume_yes=false
if [[ ${1:-} == "-y" || ${1:-} == "--yes" ]]; then
    assume_yes=true
    shift
fi
[[ $# -eq 2 || $# -eq 3 ]] || usage

old_dir=$(cd "$1" 2>/dev/null && pwd) || die "no such directory: $1"
new_name=$2
explicit_url=${3:-}

old_name=$(basename "$old_dir")
new_dir="$(dirname "$old_dir")/$new_name"

[[ $old_name != "$new_name" ]] || die "old and new name are both '$new_name'"
[[ ! -e $new_dir ]] || die "$new_dir already exists"
git -C "$old_dir" rev-parse --git-dir > /dev/null 2>&1 ||
    die "$old_dir is not a git repository"

# Refuse to run from a linked worktree: the moves below assume $old_dir is
# the main checkout that the linked worktrees point back into.
main_wt=$(git -C "$old_dir" worktree list --porcelain |
    head -1 | sed 's/^worktree //')
[[ $main_wt == "$old_dir" ]] ||
    die "$old_dir is a linked worktree; run against the main checkout ($main_wt)"

# Derive the new origin URL unless one was given. Only the last path
# component is swapped, and only when it matches the directory name.
old_url=$(git -C "$old_dir" remote get-url origin 2>/dev/null) ||
    die "no 'origin' remote in $old_dir"
if [[ -n $explicit_url ]]; then
    new_url=$explicit_url
elif [[ $old_url == */"$old_name".git ]]; then
    new_url="${old_url%/*}/$new_name.git"
elif [[ $old_url == */"$old_name" ]]; then
    new_url="${old_url%/*}/$new_name"
else
    new_url=""
fi

# Linked worktrees, with their post-rename paths. Anything under
# $WORKTREE_DIR/<old-name> moves with that directory; worktrees checked out
# elsewhere stay put but still need repair for their back-pointers.
old_wt_root="$WORKTREE_DIR/$old_name"
new_wt_root="$WORKTREE_DIR/$new_name"
new_wt_paths=()
while IFS= read -r wt; do
    case $wt in
        "$old_wt_root"/*) new_wt_paths+=("$new_wt_root${wt#"$old_wt_root"}") ;;
        *)                new_wt_paths+=("$wt") ;;
    esac
done < <(git -C "$old_dir" worktree list --porcelain |
    sed -n 's/^worktree //p' | tail -n +2)

echo "Plan:"
if [[ -n $new_url ]]; then
    echo "  remote:    $old_url"
    echo "         ->  $new_url"
else
    echo "  remote:    origin ($old_url) does not end in '$old_name';"
    echo "             leaving it unchanged (pass a URL as the third argument)"
fi
echo "  checkout:  $old_dir -> $new_dir"
if [[ -d $old_wt_root ]]; then
    echo "  worktrees: $old_wt_root -> $new_wt_root"
fi
if [[ ${#new_wt_paths[@]} -gt 0 ]]; then
    echo "  repair:    ${#new_wt_paths[@]} linked worktree(s)"
fi
old_slug_dir="$CLAUDE_PROJECTS_DIR/$(slug "$old_dir")"
if [[ -d $old_slug_dir ]]; then
    echo "  claude:    $(slug "$old_dir")* -> $(slug "$new_dir")*"
fi

if ! $assume_yes; then
    printf "Proceed? (y/N) "
    read -r reply
    [[ $reply == [yY] ]] || {
        echo "Aborted"
        exit 1
    }
fi

if [[ -n $new_url ]]; then
    git -C "$old_dir" remote set-url origin "$new_url"
fi

mv "$old_dir" "$new_dir"
if [[ -d $old_wt_root ]]; then
    mv "$old_wt_root" "$new_wt_root"
fi

# Moving the main checkout breaks the worktrees' back-pointers, and moving
# the worktrees breaks the main checkout's forward pointers. Repair run from
# the new main checkout with the new worktree paths fixes both directions.
if [[ ${#new_wt_paths[@]} -gt 0 ]]; then
    git -C "$new_dir" worktree repair "${new_wt_paths[@]}"
fi

# Claude Code keys project memory/history off the absolute path; rename the
# project dirs (main checkout plus per-worktree) so they follow the move.
new_slug_dir="$CLAUDE_PROJECTS_DIR/$(slug "$new_dir")"
if [[ -d $old_slug_dir && ! -e $new_slug_dir ]]; then
    mv "$old_slug_dir" "$new_slug_dir"
elif [[ -d $old_slug_dir ]]; then
    echo "Warning: $new_slug_dir already exists; left $old_slug_dir in place" >&2
fi
old_wt_slug=$(slug "$old_wt_root")
new_wt_slug=$(slug "$new_wt_root")
for d in "$CLAUDE_PROJECTS_DIR/$old_wt_slug"-*; do
    [[ -d $d ]] || continue
    target="$CLAUDE_PROJECTS_DIR/$new_wt_slug-${d#"$CLAUDE_PROJECTS_DIR/$old_wt_slug"-}"
    if [[ -e $target ]]; then
        echo "Warning: $target already exists; left $d in place" >&2
    else
        mv "$d" "$target"
    fi
done

echo
echo "Done. Worktrees:"
git -C "$new_dir" worktree list

if [[ -n $new_url ]]; then
    if git -C "$new_dir" ls-remote --exit-code origin HEAD > /dev/null 2>&1; then
        echo "Remote OK: $new_url"
    else
        echo "Warning: could not reach $new_url; check the remote URL" >&2
    fi
fi

others=$(git -C "$new_dir" remote -v | grep -v '^origin' | grep -i "$old_name" || true)
if [[ -n $others ]]; then
    echo "Warning: other remotes still mention $old_name:" >&2
    echo "$others" >&2
fi

echo "Note: open shells still have the old directory as cwd; cd afresh."
