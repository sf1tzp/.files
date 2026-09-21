---
name: sequence
description: Turn a milestone into an initial delivery schedule — set its due date, order the child issues, write due dates and blocked-by links in Gitea, mirror to the dotpm vault, and stamp start dates so the Gantt shows the order and the bars. Use when the user asks to plan, sequence, schedule or re-date a milestone, or to "make the Gantt show the order".
---

# Sequence a milestone

One milestone, one pass: from "here are the issues and the date" to a Gantt
that reads as a plan. The ritual (`/ritual`) re-dates weekly; this skill
lays the first honest schedule down. Principles are in the global CLAUDE.md
("Project management principles"); the mechanics below are the whole job.

**Where dates live.** Due dates and blocked-by links are Gitea's opinion —
set them there and the sync mirrors them. Start dates are vault-owned — the
sync never writes them, `npm run set-start` does. A bar needs both ends; an
arrow needs both rows dated.

## 1. Gather

Inputs: repo, milestone (id or title), target due date, and any order the
user already has in mind. Then read the current state — never plan from
memory:

```sh
tea milestones list --state all --fields title,id,duedate,description --output json
tea api "repos/sfi/<repo>/issues?milestones=<Title>&state=open&type=issues&limit=50"
tea api repos/sfi/<repo>/issues/<N>/dependencies          # per issue, existing blockers
git -C ~/captains-log/planning log --oneline -5           # a same-day "ritual" commit means Steven set dates hours ago — keep them
```

`tea api` is already authenticated; never go looking for the token file.

## 2. Order

Decide the order before touching a date. Rules that have held so far:

- **Foundations first.** Anything the rest is built on (shared components,
  tokens, provisioning, deletions others would otherwise touch) is the
  first item and blocks everything that consumes it.
- **Words before pages.** Copy issues (positioning, evidence) precede the
  pages that print them.
- **Terminal items last, blocked by everything they gate.** Release,
  cleanup, announcement. Their arrow set is the real gate.
- **One item a week is the default pace; two is the ceiling.** Say which
  weeks carry two, and which other stream's milestone they overlap.
- **Cross-repo inputs are prose, not arrows.** An arrow can't leave the
  project; note the input in the issue body instead.
- **Week granularity.** Start on a Monday, due on a Friday. A successor
  starts the Monday after its predecessor's due. Nothing starts after it is
  due — check this before applying.

Present the plan as one table (issue · start → due · blocked by) and the
weeks that carry two items. Dates are commitments: if the user gave the
milestone date and asked to sequence, apply; if the plan moves a date they
set, say so and wait.

## 3. Apply

Write the plan as a file and run the helper (dry-run first):

```
# plan.txt — one issue per line: index  start  due  [blockers,comma,separated]
99   2026-09-28  2026-10-09
100  2026-10-12  2026-10-23  99,88
105  2026-12-07  2026-12-11  100,101,92
```

```sh
~/.claude/skills/sequence/apply-schedule.py sfi/<repo> plan.txt --milestone <id> --due YYYY-MM-DD --dry-run
~/.claude/skills/sequence/apply-schedule.py sfi/<repo> plan.txt --milestone <id> --due YYYY-MM-DD
```

The helper PATCHes the milestone due, PATCHes each issue's `due_date`,
POSTs each blocked-by link (an existing link is skipped, not an error),
refuses any line whose start is after its due, then runs
`npm run sync -- --stream "<Project>" --full` and `npm run set-start` for
every line. It prints one line per change. Do the narrative by hand:

```sh
tea api -X PATCH repos/sfi/<repo>/milestones/<id> -d @patch.json   # {"description": "<existing> + dated paragraph"}
```

Append a dated paragraph to the milestone description saying what was
sequenced and why, and that the ritual re-dates rather than crams.

## 4. Settle

- The milestone task's own `start:` is vault-owned and not an issue
  identity: edit it in `~/captains-log/planning/<Stream>/_tasks/<milestone>.md`
  so the milestone bar covers its first item.
- Commit and push `~/captains-log/planning` (nested repo, unprotected main
  by design — direct push is correct).
- Close with the week-by-week table, the weeks that carry two items, and
  the reminder that `start` moves when an issue is actually picked up.

## Gotchas

- The sync's "linked" count is per dependent issue, not per arrow.
- Arrows land on the *dependent* task as `customFields.giteaBlockedBy`; the
  blocker's own file shows nothing.
- macOS has no `timeout`; use the Bash tool's timeout instead.
- `npm run set-start` fails on an identity the vault has not mirrored yet:
  run the sync first, then starts.
