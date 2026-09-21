---
name: ritual
description: Start the weekly PM oversight ritual across the SFI streams — freshen the gitea→dotpm mirror, surface past-due/stuck/unprioritized work, and guide re-dating and promotion decisions. Also the mechanics for sequencing a milestone (due dates + arrows in Gitea, start dates in the vault). Use when the user invokes /ritual, asks to run the weekly planning review, or asks to sequence/re-date a milestone.
---

# The Ritual

The weekly oversight pass over the SFI roadmap. The pipeline behind it is
captains-log#52 (Gitea → dotpm vault mirror); the principles live in the
global CLAUDE.md under "Project management principles". The goal of a ritual
run: **leave every milestone date honest, and surface decisions — not lists.**

Getting started is the hard part; this skill is the starter cord. Run the
steps in order, keep momentum, don't gold-plate.

This skill is global (`~/.files/shell/config/claude-skills`) because none of
it is tied to a checkout: it runs against `~/code/gitea-dotpm-sync` and the
planning vault at `~/captains-log/planning` from whatever repo the session
is in. The dotpm local API needs Obsidian open, which in practice means
macmini.

## 1. Freshen the mirror

```sh
cd ~/code/gitea-dotpm-sync && npm run sync -- --full
```

Requires Obsidian open with the dotpm plugin's local API on. Then commit and
push `~/captains-log/planning` if anything changed. Investigate any
`CONFLICT` or `SKIP` lines before proceeding — they mean the mirror and
Gitea disagree in a way the engine wouldn't resolve on its own.

## 2. Gather the picture

Per stream (Symbology, Moment Tally + moment-tally-website, Deployments),
via unauthenticated Gitea API reads or `tea`:

- Open milestones: due date vs today, open/closed counts, days of runway.
- In-flight work: tasks whose derived status is `in-progress` or `review`
  (grep the vault task frontmatter, or check timelines for open PRs) —
  flag anything in `review` for more than a few days.
- Unmilestoned open issues carrying `priority/high`.
- Contradictions: a far-out milestone whose members are `priority/high`;
  a near-due milestone with nothing in progress.

Open issues of one milestone, with their blocked-by arrows, in one pass:

```sh
tea api "repos/sfi/<repo>/issues?milestones=<Title>&state=open&type=issues&limit=50"
tea api repos/sfi/<repo>/issues/<N>/dependencies
```

## 3. The four questions

Present findings as a short table per question, each with a concrete
proposal and one-line rationale:

1. **Past due / at risk?** Propose re-dates per slow-and-steady pacing:
   in-progress milestones due soonest, everything else spread out,
   preserving relative order. Descope (move members to backlog) when a
   date matters more than the scope — a milestone is a launch checklist,
   not an accumulator.
2. **Stuck in review?** List the open PRs waiting on merge. These finish
   before new work starts.
3. **Unmilestoned but high-priority?** Each one either gets promoted into
   a milestone or has its `priority/high` stripped. No third state.
4. **Dates contradicting priorities?** Pull the date in or relax the
   priority — the signals must agree.

Wait for decisions on anything that changes commitments (dates, scope,
priorities). Mechanical follow-through needs no confirmation.

## 4. Apply and settle

Apply decisions in Gitea, then:

```sh
cd ~/code/gitea-dotpm-sync && npm run sync -- --full
```

Commit and push `planning/`. Close with a two-line summary of what changed
and the next milestone on deck — and if a decision changed strategy (not
just dates), append it to the relevant milestone description.

`tea` covers comments, closes, labels and milestone membership. For what it
has no subcommand for, use `tea api` — it is already authenticated; never go
looking for the token or config file:

```sh
# raw milestone text (tea's default view wraps it) and a narrative append
tea milestones list --state all --fields title,id,description --output json
tea api -X PATCH repos/sfi/<repo>/milestones/<id> -d @patch.json   # {"description": "...", "due_on": "..."}

# clear an issue's milestone; set its own due date
tea api -X PATCH repos/sfi/<repo>/issues/<N> -d '{"milestone": 0}'
tea api -X PATCH repos/sfi/<repo>/issues/<N> -d '{"due_date": "YYYY-MM-DDT23:59:59Z"}'
```

## Sequencing a milestone

The first schedule for a milestone — order, due dates and arrows in Gitea,
start dates in the vault — is its own skill: `/sequence`. It ships a helper
(`apply-schedule.py`) that applies a plan file end to end. The ritual only
re-dates what `/sequence` laid down.

## Conventions that bind the ritual

- Statuses are never edited by hand — fix the world (open the PR, close
  the issue), not the card.
- Umbrella issues are retired; narrative appends to milestone descriptions.
- Ordering arrows come from two places. Issue-to-issue arrows mirror
  Gitea's blocked-by links (set them there; the sync draws them and keeps
  hand-drawn arrows). Milestone-to-milestone arrows are hand-drawn on the
  vault's milestone tasks and never touched by the sync.
- A milestoned issue without a due date of its own is due when its
  milestone is (inherited by the sync). `start` is vault-owned: **set it
  when picking an issue up** — that is what makes the bar, and the arrows
  into it, honest. The Gantt draws an arrow only between dated, visible
  rows; a collapsed milestone hides its members' arrows.
- Task titles in the vault may carry a ` (repo)` suffix — that's the sync
  disambiguating filename slugs across repos; Gitea titles are untouched.
