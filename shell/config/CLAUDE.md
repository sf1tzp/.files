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

## Gitea issues & milestones
- Label issues on creation with scoped labels: exactly one `type/*` (bug,
  feature, ux, docs, chore, planning), any relevant `area/*`, and at most one
  `priority/*` (high/medium/low). Priority is assigned by Steven, not inferred.
- Roadmap phases are milestones, each anchored by an umbrella `type/planning`
  issue. Milestones cannot depend on each other; encode ordering as issue
  dependencies (blocked-by) between the umbrella issues.
- Gitea's Projects/kanban feature has no API (as of 1.25) — don't build
  tracking on it. Labels + milestones are the queryable source of truth.

## Pull requests
- **Internal repos (`gitea.zen.lofi`)** — open a PR early with the `tea` CLI
  and keep it updated as the branch evolves (`tea pr create`, `tea pr list`,
  ...). Update the PR description when pushing commits so that reviewers can
  see the current state up front.
- **Public/external remotes (e.g. `github.com`)** — never open a PR (even a
  draft) without an explicit go-ahead in the current session. Branch pushes
  are fine; a PR is the publish step, and Steven vets branch contents first.

## Guardrails
Hard lines, every host and repo. Anything needing a per-repo exception
doesn't belong here.
- **No publish steps to public/external services without an explicit
  same-session go-ahead** — PRs, issues, releases, package registry pushes.
  Generalizes the PR rule above: pushing a branch is work-in-progress;
  anything that notifies people or gets indexed is a publish step.
- **No force-pushes or history rewrites on shared branches** (main, or any
  branch with an open PR). Own unvetted feature branches are fair game.
- **Mirrors make gitea ops public-facing.** The gitea→GitHub mirrors
  replicate branch deletions and history changes on their own schedule;
  treat destructive git operations on mirrored repos accordingly.
- **No licensed binary assets in mirrored repos** — fonts especially
  (Palm Springs, Morganite). Brand assets live in `~/.sfi/brand-assets`
  and are injected at build/render time, never committed.
- **Branch-guarded mains** (`.files`, `captains-log`): changes land via
  branch + PR, never a direct push to main.

## Machines
Same conventions everywhere; capabilities differ. Check `hostname` before
machine-dependent work.
- **macbook-air** — primary Mac-app dev machine. Full Xcode; the only host
  where the `verify` and `capture` skills auto-run.
- **macmini** — always-on Mac, Command Line Tools only. Compile checks and
  `swift test` are fine (CLT framework flags are documented in the app's
  Package.swift); never auto-run `verify`/`capture` or other heavy
  interactive work — explicit ask only.
- **zen** — homelab server (hosts `gitea.zen.lofi`). Has a Swift toolchain
  for pre-flighting core packages only; not an app-dev machine.
- **devbox** — primary Linux dev machine: services, IAC, website codebases
  (Go/Rust/frontend toolchains).
- **soundship** — Linux host with kubectl access to the `luxor` cluster;
  treat cluster-touching commands as production operations.

