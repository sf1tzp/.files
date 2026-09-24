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
fail structurally, so do not work around a refusal; say what needed a human.

## The loop

1. **Read the issue** — `tea issues <n> --repo <owner/repo> --comments`. The
   body and the comments are the spec; a later comment revises an earlier
   plan. If the issue names blockers that are still open, say so in a comment
   and stop.
2. **Work on the branch you are on.** Do not switch branches or make another
   worktree. Follow the repo's `CLAUDE.md` and the working conventions in
   `~/.claude/CLAUDE.md` (tree-shaped change descriptions, no stacked PRs,
   and the rest). Run the repo's checks before you push (`fort check --all`
   here in deployments, `npm test`, `just test`, whatever the repo says).
3. **Commit and push as you go** — clear, incremental commits; the branch is
   cheap to amend until it is reviewed. Commits are signed with the fort's
   key automatically.
4. **Open the PR early** with `tea pr create --repo <owner/repo> --head
   issue-<n> --base main --title … --description …`, and **keep the
   description current** as the branch evolves: the reviewer reads the
   description first, so it must say what the branch is now, not what it
   was at the first push. Say `Closes #<n>` (or `Refs #<n>` when the issue
   is bigger than the PR).
5. **Stop when it is a PR** — one that passes the checks and whose
   description stands on its own. Do not wait for review, and do not merge:
   the PR waits for a human, by branch protection.
6. **Report** — your last message names the PR link and what, if anything,
   needs a human decision. That message is what `herdr --remote sfi-dev`
   shows on the workspace.

## What happens after you stop

- **The transcript** posts itself: a Stop hook on the fort
  (`pickup-transcript`) attaches this session's transcript to a comment on
  the PR (or the issue, when there is no PR yet) — the fort keeps nothing,
  so that comment is the record. If the PR shows no such comment after you
  finish, run `pickup-transcript <session-id>` yourself; the session id is
  in `~/.claude/projects/…`.
- **Continuation** is a human's: `claude --resume <session-id>` from a pane
  in this workspace keeps the task's attribution. A fresh dispatch of the
  same issue reports this workspace instead of opening another.

## Do not

- Ask questions and wait — nobody is watching in real time. Make the routine
  judgement calls; put the material ones in the PR description as
  assumptions, and the one that blocks you in a comment on the issue.
- Touch other issues, other worktrees, or the fort's configuration.
- Post the transcript by hand into the PR body — it goes as an attachment on
  its own comment, by the hook.
