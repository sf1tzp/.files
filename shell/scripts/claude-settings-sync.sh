#!/bin/sh
# Sync the shared Claude Code settings (shell/config/claude-settings.json)
# into ~/.claude/settings.json.
#
# A symlink won't work here: Claude Code writes settings atomically
# (temp file + rename), which replaces a symlink with a regular file
# (anthropics/claude-code#40857) — so the shared file is deep-merged over
# the local one instead. Shared keys win; machine-local keys Claude Code
# wrote itself (accepted-dialog flags, /config tweaks, herdr's hook
# bookkeeping) survive. One consequence: deleting a key from the shared
# file does not delete it locally — override it with a new value instead.
#
# Runs from the shell profile, gated by a checksum stamp so it only does
# work when the shared file's content has actually changed.
set -eu

canonical="$HOME/.files/shell/config/claude-settings.json"
target="$HOME/.claude/settings.json"
stamp="$HOME/.claude/.settings-sync-stamp"

[ -f "$canonical" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
sum="$(cksum <"$canonical")"
if [ -f "$stamp" ] && [ "$(cat "$stamp")" = "$sum" ]; then
    exit 0
fi

mkdir -p "$HOME/.claude"
if [ -f "$target" ] && jq -e . "$target" >/dev/null 2>&1; then
    merged="$(jq -s '.[0] * .[1]' "$target" "$canonical")"
    printf '%s\n' "$merged" >"$target"
else
    # No local file yet, or local JSON is corrupt: start from the shared one.
    cp "$canonical" "$target"
fi
printf '%s\n' "$sum" >"$stamp"
