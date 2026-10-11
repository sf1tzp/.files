---
name: pickup
description: Work a dispatched gitea issue end to end on a dev fort — read the issue, work on its branch in the current worktree, commit and push as you go, open the PR early and keep its description current, report the link. Use when invoked as /pickup owner/repo#N (what `pickup` on the fort prompts), or when the session runs under a dispatched task (PICKUP_TASK is set).
---

# Pickup

You are `sfi-agent` on a dev fort, dispatched to one issue. The deterministic
half already happened before you started: `pickup` on the fort cloned or
fetched the repo, made the worktree you are in (`~/worktrees/<repo>/issue-<n>`
on branch `issue-<n>`), and opened this herdr workspace with the task's
environment. Your half is the work and the PR.

**The identity.** `$PICKUP_TASK` is `owner/repo#N`; the argument, when given,
is the same. If neither is set, stop and say so — this skill is for a
dispatched task, not a guess.

**What you can and cannot do** is the fort's shape, not a rule to remember:
the only credentials here are the fort's own (`sfi-agent`'s SSH key, GPG key
and gitea token). You can push branches and open, edit and comment on PRs and
issues on every repo the `sfi-agentic-dev` team reaches. You cannot push
`main`, approve or merge a PR, or publish to anything outside gitea — those
fail structurally, so do not work around a refusal; say what needed a teammate.
The one exception is `sfi/knowledge`, whose `main` is unguarded by design
(captains-log#60): a push there succeeds, and the `kb` skill tells you to
make one.

## The loop

1. **Read the issue** — `tea issues <n> --repo <owner/repo> --comments`. The
   body and the comments are the spec; a later comment revises an earlier
   plan. If the issue names blockers that are still open, say so in a comment
   and stop.
2. **Work on the branch you are on.** Do not switch branches or make another
   worktree. Follow the repo's `CLAUDE.md` and the working conventions in
   `~/.claude/CLAUDE.md` (tree-shaped change descriptions, no stacked PRs,
   and the rest). **Check `sfi/knowledge` for the subsystem you are about to
   change** — `kb-map.txt` lists the coverage, and a doc there tells you why
   the current shape was chosen. Cite it in the PR when it explains a
   constraint you kept. Run the repo's checks before you push (`fort check --all`
   here in deployments, `npm test`, `just test`, whatever the repo says).
3. **Commit and push as you go** — clear, incremental commits; the branch is
   cheap to amend until it is reviewed. Commits are signed with the fort's
   key automatically.
4. **Open the PR early** with `tea pr create --repo <owner/repo> --head
   issue-<n> --base main --title … --description …`, and **keep the
   description current** as the branch evolves: the reviewer reads the
   description first, so it must say what the branch is now, not what it
   was at the first push. Say `Closes #<n>` (or `Refs #<n>` when the issue
   is bigger than the PR). Write it in Simplified Technical English — the
   rules are in *The prose* below.

   **One keyword per issue.** Gitea matches a closing keyword only where it
   sits immediately before the reference, so `Closes #49 and #51` closes #49
   and quietly leaves #51 open (sfi/gotea#50 did exactly that). Write each
   one out — `Closes #49. Closes #51.` — and keep them in the description:
   it is also what the gitea→dotpm sync reads to move an issue to *review*,
   so a reference the keyword missed is both an issue nobody closes and a
   status that never moves.
5. **Prove the branch still merges.** `main` moves while you work. Several
   agents share this fort, and two branches cut from the same commit give one
   clean merge and one conflict. Nothing else in this loop looks at the base
   branch again, so look here — after the PR exists, and again after your
   last push:

   ```sh
   git fetch origin main
   git merge-base --is-ancestor origin/main HEAD   # exit 0: current. non-zero: behind
   tea pr <n> --repo <owner/repo> -o json | grep '"mergeable"'
   ```

   If the branch is behind, **merge `origin/main` into it** — merge, not
   rebase: the PR is open, and a history rewrite on a branch with an open PR
   is a guardrail in `~/.claude/CLAUDE.md`. Then run the repo's checks again,
   because `main` moved under them, and push.

   Gitea recomputes `mergeable` in the background, so the field can lag your
   last push. The git check is local and immediate — read the field as
   confirmation, not as the first answer.

   **A conflict you cannot resolve is not done.** Put it in the PR
   description and in your report, and name the PR that the conflict came
   from (`tea pr list --repo <owner/repo> --state closed` — the one that
   changed the same lines). A teammate reads that and knows which branch to
   re-cut.
6. **Stop when it is a PR** — one that passes the checks, merges into `main`,
   and whose description stands on its own. Do not wait for review, and do not
   merge: the PR waits for a teammate, by branch protection.
7. **Report** — your last message names the PR link and what, if anything,
   needs a teammate's decision. That message is what `herdr --remote sfi-dev`
   shows on the workspace.

## The prose

What you write into gitea — the PR description, and every comment you leave
on the issue — follows the **Simplified Technical English** rules in
`~/.claude/CLAUDE.md`. The reviewer reads the description before the diff, so
it must be answerable in one pass, with nowhere for a vague claim to hide.

STE is the sentences, not the shape: a tree-shaped change description, where
the repo asks for one, stays tree-shaped. Your commit messages and your last
message to the workspace are ordinary prose.

## What happens after you stop

- **The transcript** posts itself: a Stop hook on the fort
  (`pickup-transcript`) attaches this session's transcript to a comment on
  the PR (or the issue, when there is no PR yet) — the fort keeps nothing,
  so that comment is the record. If the PR shows no such comment after you
  finish, run `pickup-transcript <session-id>` yourself; the session id is
  in `~/.claude/projects/…`.
- **Continuation** is a teammate's: `claude --resume <session-id>` from a pane
  in this workspace keeps the task's attribution. A fresh dispatch of the
  same issue reports this workspace instead of opening another.

## Do not

- Ask questions and wait — nobody is watching in real time. Make the routine
  judgement calls; put the material ones in the PR description as
  assumptions, and the one that blocks you in a comment on the issue.
- Touch other issues, other worktrees, or the fort's configuration.
- Post the transcript by hand into the PR body — it goes as an attachment on
  its own comment, by the hook.
