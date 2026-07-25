# Working conventions

Applies across all repositories and machines. (Source of truth:
`~/.files/shell/config/CLAUDE.md`, symlinked to `~/.claude/CLAUDE.md`.)

## Branches & worktrees
- Do feature work on a branch checked out as a git worktree under
  `~/worktrees/<repo>/<branch>`, rather than committing on the primary checkout.
- Create one with: `git worktree add ~/worktrees/<repo>/<branch> -b <branch>`.

## Committing & pushing
- Commit and push as work progresses on the feature branch/worktree — do NOT
  wait for confirmation. Prefer clear, incremental commits. This applies to
  all remotes: branch work is cheap to amend or abandon before it's vetted.

## Knowledge base (captains-log)
- `~/captains-log/knowledge/` documents the *why* and *how* of technical topics
  encountered at SFI; it backs the expertise graph on streetfortress.com.
- When a session digs into a notable technique, pattern, or tool that isn't
  documented there yet (check the listing in `~/captains-log/kb-map.txt`),
  say so and offer to write it up — the `kb` skill has the conventions.
  Raise it at a natural pause or wrap-up, not mid-task.

## Pull requests
- **Internal repos (`gitea.zen.lofi`)** — open a PR early with the `tea` CLI
  and keep it updated as the branch evolves (`tea pr create`, `tea pr list`,
  ...). Update the PR description when pushing commits so that reviewers can
  see the current state up front.
- **Public/external remotes (e.g. `github.com`)** — never open a PR (even a
  draft) without an explicit go-ahead in the current session. Branch pushes
  are fine; a PR is the publish step, and Steven vets branch contents first.

