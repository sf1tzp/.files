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
  `priority/*` (high/medium/low). Infer an initial priority from sequencing.
- Roadmap phases are milestones; the phase narrative lives in the milestone
  description. Umbrella issues are retired (2026-09, captains-log#52) — don't
  create them. Cross-milestone ordering lives as dependency arrows on the
  milestone tasks in the planning vault (dotpm); the gitea-dotpm sync treats
  task dependencies as vault-owned and never overwrites them. Intra-milestone
  ordering stays as gitea issue dependencies (blocked-by).
- Gitea's Projects/kanban feature has no API (as of 1.25) — don't build
  tracking on it. Labels + milestones are the queryable source of truth.

## Project management principles
The oversight loop behind captains-log#52 (gitea → dotpm vault mirror).
- **Milestones are promises; backlog is everything else.** Hand-manage only
  membership and dates. If an issue doesn't gate the milestone's headline
  outcome, it stays backlog — that's what keeps due dates honest.
- **Never manage status by hand.** It derives from reality via the sync:
  PR opens → in-progress, live closing keyword → review, issue closed →
  done. If a board card looks wrong, fix the world, not the card.
- **Weekly ritual** (the `/ritual` skill in captains-log starts it): on the
  all-projects Gantt ask four questions — past due or at risk? stuck in
  review? unmilestoned but priority/high? dates contradicting priorities?
  Leave every date honest; surface decisions, not lists.
- **`priority/high` means "do next", fleet-wide, kept rare.** No priority
  label is a valid state: backlog, sequenced later.
- **Narrative lives in milestone descriptions** (append decisions there);
  mechanics go through the agent. Views are for seeing, gitea is the
  record, the agent is the hands.

## Pull requests
- **Internal repos (`gitea.zen.lofi`)** — open a PR early with the `tea` CLI
  and keep it updated as the branch evolves (`tea pr create`, `tea pr list`,
  ...). Update the PR description when pushing commits so that reviewers can
  see the current state up front.
- **No stacked PRs on gitea.** Squash-merge re-applies the base branch's
  hunks, landing duplicate blocks on main (deployments #163/#164 broke nix
  eval this way), and gitea neither displays the stack nor rebases the
  follow-up when its base merges. If a change depends on an open PR, wait
  for the base to merge and branch from main — or fold both into one PR.
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
- **Production VPS are hands-off** — `web2.streetfortress.cloud` and
  `db2.streetfortress.cloud` (mesh 10.1.0.52/.51) are the production boxes.
  No SSH or remote command execution on them without an explicit same-session
  go-ahead, including "harmless" read-only checks. They're slated for k3s
  reprovisioning with SSH access removed; don't build workflows that assume
  shell access to them.
- **WireGuard private keys stay unread.** Rendered configs
  (`/etc/wireguard/*.conf`) contain `PrivateKey` — never read, print, grep,
  or edit them, even with sudo, even for an unrelated line. Config changes go
  through the Ansible template + playbook re-run; live state comes from
  `wg show` (which redacts the private key). Never echo output of
  `wg genkey` or move key files around.

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

