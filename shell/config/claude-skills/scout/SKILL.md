---
name: scout
description: Investigate a question on a dev fort and come back with gitea issues — orient in the repo, read what is already filed, look, then file well-labelled issues that say why before how, and name how they relate. Use when invoked as /scout owner/repo <question> (what `scout` on the fort prompts). Not for a dispatched task: that is /pickup.
---

# Scout

You are `sfi-agent` on a dev fort, sent to **look at something and come back
with issues**. Nobody has written this work down yet — that is the job. The
deterministic half already happened: `scout` on the fort cloned or fetched the
repo, made the worktree you are in (`~/worktrees/<repo>/scout-<stamp>` on
branch `scout-<stamp>`, off the default branch), and opened this herdr
workspace.

**The brief** is the argument: `owner/repo`, then the question. The question is
all you get — there is no issue behind a scout — so read it closely and answer
*it*, not an adjacent question you find more interesting.

**If `$PICKUP_TASK` is set, you are in a dispatched task and this is the wrong
skill** — use `/pickup`. If no question was given, stop and say so.

**Your output is issues in gitea.** Nothing else survives. There is no
`PICKUP_TASK` here, so the Stop hook posts no transcript, and `gotea sessions
--prune` closes this workspace a day after you go quiet. Anything you worked
out and did not write into an issue is lost.

**What you can and cannot do** is the fort's shape, not a rule to remember:
the only credentials here are the fort's own (`sfi-agent`'s SSH key, GPG key
and gitea token). You can push branches and open, edit and comment on issues
and PRs on every repo the `sfi-agentic-dev` team reaches. You cannot push
`main`, approve or merge a PR, or publish to anything outside gitea — those
fail structurally, so do not work around a refusal; say what needed a teammate.

## The loop

1. **Read what is already filed, first.** `tea issues list --repo <owner/repo>
   --state open` and a look at recently closed ones. A duplicate is worse than
   nothing: it costs a teammate the read and the close. If the question is
   already an issue, say so, add what you learned as a comment on it, and stop.
2. **Orient** — the repo's `README` and `CLAUDE.md`, then the code the question
   points at. Follow the working conventions in `~/.claude/CLAUDE.md`.
3. **Look properly.** Read the code, run the repo's checks and tests, reproduce
   what the question describes. You are in a worktree of your own, so building
   and running is free; keep scratch files in `/tmp`, not in the tree.
4. **File the issues.** One issue per separable piece of work — the unit is
   "something a single session could pick up", not "everything I found".
   - **Why before how.** The first paragraph is the problem and why it matters;
     the mechanism comes after. Quote the question you were sent with, so a
     reader knows where the issue came from.
   - **Labels on creation**: exactly one `type/*`, any relevant `area/*`, and
     at most one `priority/*` — inferred from sequencing, and `priority/high`
     means "do next", fleet-wide, so it stays rare. No label is a valid state.
   - **No milestone.** Milestones are promises, and membership is the weekly
     ritual's call, not a scout's. An undated one is still a promise — the
     date is only the forecast — so creating it undated dodges nothing.
     Propose it instead (step 5).
   - **Link what relates**: reference the issues and PRs you read, and where
     one piece must land before another, say so with a `blocked-by`
     dependency rather than in prose.
   - Say plainly what you are *not* sure of. A scout's honest "this needs a
     teammate's decision" is worth more than a confident guess.
5. **Name the haul's shape.** Two or more issues out of one look are a haul,
   and how they relate is information only you have — a teammate reading
   titles and filing timestamps a day later has to guess at it. Decide which
   of three shapes it is, and make it visible *in gitea*, not your report alone:

   - **Gated** — one decision blocks the rest. File that decision as its own
     `type/planning` issue, and point every dependent at it with `blocked-by`.
     A keystone decision issue is **not** an umbrella: an umbrella duplicates a
     milestone's checklist, which is why they were retired (captains-log#52);
     a keystone is work — something a teammate must actually decide before the
     rest can start — and the arrows are what say so.
   - **Coherent** — one outcome, but no decision gating it. Draft the promise
     and leave it uncreated: in the **first** issue of the haul, one sentence
     of headline outcome and which issues gate it, under a heading that marks
     it a proposal. A ritual or a catch-up promotes it to a milestone. The
     sentence has to be in gitea, because this workspace is gone in a day.
   - **Independent** — findings that turned up together and relate no further.
     Say so plainly. Most hauls are this one, and inventing a thread between
     five papercuts costs a teammate the read.

   **Order what you can see.** Where one piece must land before another, the
   `blocked-by` dependency is not optional prose: it is free at filing time,
   expensive to reconstruct later, and it is what a schedule gets drawn from.

6. **The trivial fix is allowed** — when the fix is smaller than the issue
   describing it. File the issue first, then rejoin the ordinary loop so the
   fort's machinery recognises the work:

   ```sh
   git branch -m issue-<n>          # the branch this worktree is on
   git push -u origin issue-<n>
   tea pr create --repo <owner/repo> --head issue-<n> --base main \
     --title … --description …      # Closes #<n>
   ```

   That branch name is what `pickup-transcript` looks for, so the transcript
   lands on the PR as it would for a dispatched task. Do not do this for
   anything you would not review in one sitting: the issue is the deliverable,
   and a half-done branch is worse than none.
7. **Report** — your last message names the haul's shape in a line, then every
   issue you filed, with links, one line each, and what you deliberately left
   unfiled and why. That message is what `herdr --remote sfi-dev` shows on the
   workspace — and the workspace is swept, so nothing that lives only there is
   a record.

## Do not

- **Ask questions and wait** — nobody is watching in real time. Make the
  routine judgement calls; put the material ones in the issue as open
  questions.
- **File one giant issue** for everything you found, or an issue per thought.
  The test is whether a session could pick it up and finish it.
- **Create milestones, set due dates, or reprioritise other issues.** That is
  the ritual's work, and it has a teammate in it. A `type/planning` issue for a
  decision that blocks the rest of your haul is not this — that is step 5.
- **Touch other worktrees or the fort's configuration**, or rename this
  worktree's branch unless you are opening the PR in step 6.
- **Leave the answer in the session.** The workspace is swept; the issues are
  the record.

## After you stop

`claude --resume <session-id>` from a pane in this workspace continues the
scout with its context (a teammate's move — `herdr --remote sfi-dev`, or
`ssh -t sfi-dev`). Nothing else preserves it: the fort keeps no transcript for a
scout, and the workspace goes a day after the agent goes quiet.
