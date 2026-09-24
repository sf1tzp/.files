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
   is bigger than the PR). Write it in Simplified Technical English — the
   rules are in *The prose* below.

   **One keyword per issue.** Gitea matches a closing keyword only where it
   sits immediately before the reference, so `Closes #49 and #51` closes #49
   and quietly leaves #51 open (sfi/gotea#50 did exactly that). Write each
   one out — `Closes #49. Closes #51.` — and keep them in the description:
   it is also what the gitea→dotpm sync reads to move an issue to *review*,
   so a reference the keyword missed is both an issue nobody closes and a
   status that never moves.
5. **Stop when it is a PR** — one that passes the checks and whose
   description stands on its own. Do not wait for review, and do not merge:
   the PR waits for a teammate, by branch protection.
6. **Report** — your last message names the PR link and what, if anything,
   needs a teammate's decision. That message is what `herdr --remote sfi-dev`
   shows on the workspace.

## The prose

The reviewer reads the description before the diff, so write it — and every
comment you leave on the issue — in **Simplified Technical English**
(ASD-STE100), the controlled English of aircraft maintenance manuals. It makes
the description answerable in one pass, and it leaves a vague claim nowhere to
hide. Full STE needs the approved-word dictionary, which the fort does not
have, so apply the rules that need no lookup:

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
