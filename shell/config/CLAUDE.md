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
- **Weekly ritual** (the global `/ritual` skill starts it; `/sequence` lays
  a milestone's first schedule down): on the all-projects Gantt ask four
  questions — past due or at risk? stuck in review? unmilestoned but
  priority/high? dates contradicting priorities? Leave every date honest;
  surface decisions, not lists.
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

## Prose that lands in gitea (Simplified Technical English)
Issue bodies, issue and PR comments, PR descriptions and milestone
descriptions are read as a queue by a human who decides what to sequence, so
write them in **Simplified Technical English** (ASD-STE100), the controlled
English of aircraft maintenance manuals. It makes the text answerable in one
pass, and it leaves a vague claim nowhere to hide. Full STE needs the
approved-word dictionary, which no host here has, so apply the rules that
need no lookup:
- **One idea per sentence.** 20 words at most in an instruction, 25 in a
  description; six sentences at most in a paragraph.
- **Active voice, simple tense, named actor.** "The sync overwrites the
  dependency", not "the dependency is overwritten", not "would end up
  overwritten".
- **No `-ing` verb form** as a noun or a modifier: "to parse the label", not
  "label parsing", not "when parsing labels".
- **Imperative for steps**, one step per sentence.
- **The same word for the same thing**, every time. A synonym reached for
  variety reads as a second thing.
- **Common words in one meaning.** No idiom, no metaphor: "after", not
  "following"; "start", not "kick off". Keep the articles — STE is not
  telegram style.
- **Three nouns at most in a row.** Break a longer cluster with a
  preposition: "the timeout of the mirror sync", not "mirror sync timeout
  value".
- **State a negative plainly**: "This does not change the vault." Do not bury
  it in a subordinate clause.
- **"must" for a requirement, "can" for an option** — not "shall", not
  "should".

STE is the sentences, not the shape — a tree-shaped change description stays
tree-shaped (below). Commit messages, knowledge-base documents and messages
to the person in the session are ordinary prose.

## Describe tree changes as a tree
A change that spans several directories reads as a shape, and a flat file
list hides it. Lead the PR description (and the commit body, for a
multi-directory change) with the tree, one line per entry, marked:

```
● new        file or directory this change creates
○ appended   existing file this change adds lines to; never a rewrite —
             if a file is rewritten, say so in words
◆ seeded     generated output, not hand-written; regenerate, never hand-edit
✗ removed    file or directory this change deletes
```

A short "what/why" follows the name, and a directory the reader will wonder
about is listed as ○ "untouched". The marks are stable — `fort add`'s
post-add report prints this shape and deployments' golden-tree tests compare
it. Repo-specific readings of the marks live in that repo's `CLAUDE.md`.

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
- **Production forts are hands-off** — `sfi-prod-439bf72` (Linode, mesh
  10.1.0.54) is the production box; web2 and db2 are decommissioned
  (deployments#340). No SSH or remote command execution on it without an
  explicit same-session go-ahead, including "harmless" read-only checks and
  the `sfi-*` ops verbs. Its state is read through the sanctioned paths:
  the `ops-ro` kubeconfig context on devbox (`kubectl --context
  sfi-prod-439bf72`, the built-in view role) and central monitoring on luxor
  (thanos-query, grafana.luxor.lofi). Changes go through git — the fort's
  tree in sfi/deployments lands via PR and reconciles on its own.
- **WireGuard private keys stay unread.** Rendered configs
  (`/etc/wireguard/*.conf`) contain `PrivateKey` — never read, print, grep,
  or edit them, even with sudo, even for an unrelated line. Config changes go
  through the Ansible template + playbook re-run; live state comes from
  `wg show` (which redacts the private key). Never echo output of
  `wg genkey` or move key files around.

## Agent identity
Who is acting is a property of the host, not a prompt (captains-log#55,
deployments#413/#414/#418; the long form is deployments'
`docs/infra/dev-forts.md` and `docs/forts/dev.md`).
- **On a laptop or devbox you are Steven** — sf1tzp's credentials, the
  conventions above are what bound you.
- **On a dev fort (`sfi-dev-*`, user `agent`) you are `sfi-agent`**: the
  fort's own SSH key, GPG key (every commit signed) and gitea token, and
  nothing else — no github.com, no age keys, no cluster access. You can
  push branches and open, edit and comment on PRs and issues on the repos
  the `sfi-agentic-dev` team reaches; you cannot push `main`, approve or
  merge a PR, or publish outside gitea. Those fail structurally — say what
  needed a human instead of working around a refusal.
- **Escalation is the PR.** A human approves and merges; anything beyond
  the team's grant (a new repo, a secret, a publish) is a sentence in the
  PR description or a comment on the issue, and you stop there.
- **Dispatch (`pickup`)**: `gotea dispatch owner/repo#N` on macmini runs
  `ssh sfi-dev pickup owner/repo N`, which makes the worktree
  (`~/worktrees/<repo>/issue-<n>`), opens a herdr workspace labelled
  `owner/repo#N` with the task's env (`PICKUP_TASK`,
  `OTEL_RESOURCE_ATTRIBUTES`), and prompts `/pickup owner/repo#N` — the
  `pickup` skill is the standing instruction. A Stop hook posts the
  transcript to the PR; the fort keeps nothing. Continue a task with
  `herdr --remote sfi-dev` or `claude --resume <id>` from a pane in its
  workspace.
- **Scouting (`scout`)**: `gotea scout owner/repo "the question"` is the
  other half — a session with no issue behind it, sent to look and expected
  back with *issues*, not a PR (a fix smaller than the issue describing it
  is allowed: file the issue, rename the branch to `issue-<n>`, then PR).
  The workspace is labelled `scout:<owner/repo>@<stamp>`, there is no
  `PICKUP_TASK` and so no transcript, and the sweep closes it a day after
  the agent goes quiet — the filed issues are the only record. The `scout`
  skill is the standing instruction.

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

