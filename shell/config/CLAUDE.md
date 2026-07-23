# Working conventions

Applies across all repositories and machines. (Source of truth:
`~/.files/shell/config/CLAUDE.md`, symlinked to `~/.claude/CLAUDE.md`.)

## Branches & worktrees
- Do feature work on a branch checked out as a git worktree under
  `~/worktrees/<repo>/<branch>`, rather than committing on the primary checkout.
- Create one with: `git worktree add ~/worktrees/<repo>/<branch> -b <branch>`.

## Committing & pushing
- **`gitea.zen.lofi` repos** — commit and push as work progresses. Do NOT wait
  for confirmation. Prefer clear, incremental commits.
- **Any other remote (e.g. `github.com`)** — default behavior: stage changes and
  leave the commit/push to the user unless explicitly asked.

## Pull requests
- On `gitea.zen.lofi` repos, open a PR early with the `tea` CLI and keep it
  updated as the branch evolves (`tea pr create`, `tea pr list`, ...).
- Update the PR description when pushing commits so that reviewers can see
  the current state up front.

