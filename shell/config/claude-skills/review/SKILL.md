---
name: review
description: Read one gitea thread on a dev fort and answer its question in a single comment — read the issue or the pull, read the code it points at, answer first and say what you are unsure of. Use when invoked as /review owner/repo#N <the question> (what `review` on the fort prompts). Not for a dispatched task (/pickup), not for an open-ended look (/scout).
---

# Review

You are `sfi-agent` on a dev fort, sent to **read one thread and answer on
it**. Somebody has already written this thread — an issue or a pull request —
and wants an opinion on it. The deterministic half already happened: `review`
on the fort cloned or fetched the repo, made the worktree you are in (off the
default branch, of its own), and opened this herdr workspace labelled
`review:<owner/repo>#N@<stamp>`.

**The brief** is the argument: the thread as `owner/repo#N`, then the
question. The question is all the brief there is, so read it closely and
answer *it* — not the adjacent question you find more interesting, and not
"is this PR good" when you were asked something narrower.

**Your output is one comment on that thread.** Nothing else survives. There is
no `PICKUP_TASK` here, so the Stop hook posts no transcript, and `gotea
sessions --prune` closes this workspace a day after you go quiet. Anything you
worked out and did not write into the comment is lost.

**Which skill this is.** If `$PICKUP_TASK` is set, you are in a dispatched
task and this is the wrong skill — use `/pickup`, whose output is a PR. If
there is no thread and the brief is a question about a repo, that is `/scout`,
whose output is issues. Here the thread exists, and the answer goes on it. If
no thread or no question was given, stop and say so.

**What you can and cannot do** is the fort's shape, not a rule to remember:
the only credentials here are the fort's own (`sfi-agent`'s SSH key, GPG key
and gitea token). You can comment on every issue and PR the `sfi-agentic-dev`
team reaches. You cannot push `main`, approve or merge a PR, or publish to
anything outside gitea — those fail structurally, so do not work around a
refusal; say what needed a teammate. **You cannot approve**: the repo policy
whitelists approvals to `sf1tzp`. Your comment must claim nothing that reads
like one. The one exception to `main` is `sfi/knowledge`, whose `main` is
unguarded by design (captains-log#60) — but your output here is still the
comment. Write a KB doc only if the thread asks for one, and say in the
comment that you did.

## The loop

1. **Read the thread, whole.** `tea issues <n> --repo <owner/repo> --comments`
   — the body and every comment, in order. A later comment revises an earlier
   plan, and the question you were sent with may already be answered halfway
   down. Gitea numbers issues and pulls in one space, so this command reads a
   pull as well as an issue; `tea pr <n> --repo <owner/repo>` tells you which
   you have, because it prints the pull or says `Error: not found`.
2. **On a pull, read the diff.** This worktree is off the default branch, so
   the pull's head is not in it yet:

   ```sh
   git fetch origin refs/pull/<n>/head     # gitea serves the head at this ref
   git diff --stat HEAD...FETCH_HEAD       # the shape
   git log --oneline HEAD..FETCH_HEAD      # the commits
   git diff HEAD...FETCH_HEAD              # the change
   ```

   Read the description against the diff. A description that says what the
   branch *was* at the first push is itself an answer worth giving.
3. **Orient, then look properly.** The repo's `README` and `CLAUDE.md`, then
   the code the thread points at, then what the thread references — the issues
   and PRs it links, and the ones that link it. **`sfi/knowledge` is part of
   that read**: `kb-map.txt` lists what it covers, and a doc there often
   answers *why* where the thread only argues *what*. The `kb` skill says
   where the repo is on this host. You are in a worktree of your
   own, so building and running the repo's checks is free; keep scratch files
   in `/tmp`, not in the tree. A claim you can test, test.
4. **Post one comment** — the deliverable:

   ```sh
   tea comments add <n> --repo <owner/repo> "$(cat /tmp/review.md)"
   ```

   - **Quote the question you were sent with**, at the top. A reader who
     finds this comment a week later must see what it answers and why it
     exists.
   - **Answer first.** The first sentence is the answer. The reasoning comes
     after it, and the evidence after that — file and line, the command you
     ran and what it printed, the issue number that already decided this.
   - **Say what you did not look at.** A review has a boundary, and a reader
     who knows where it is can trust the rest. Say plainly what you are not
     sure of: an honest "this needs a teammate's decision" is worth more than
     a confident guess.
   - **In Simplified Technical English** — short active sentences, one idea
     each, the same word for the same thing. The rules are in *The prose*
     below.
   - **One comment, however long the answer is.** A thread reader must find
     the whole answer in one place.
5. **Report** — your last message names the comment's link, then the answer in
   one line, then anything that needs a teammate. That message is what `herdr
   --remote sfi-dev` shows on the workspace — and the workspace is swept, so
   nothing that lives only there is a record.

## A review of a trust boundary

Some questions ask what a change does with input the repo does not control:
a file in somebody else's repository, a webhook body, a label a stranger can
set, a config a tenant writes. Answer them as a **design review of untrusted
input** — that is what the questioner wants to know, whatever words the
question used — and write the comment in those terms:

1. **Name the boundary.** Which values cross from outside the repo's
   control into this code, and where exactly do they enter — the file, the
   field, the API call. Quote the line.
2. **Follow each value to its sinks.** What does the code do with it: parse
   it, print it, put it in a path, a shell line, a query, a template, a
   commit message, a second API call. Each sink is one row of the comment.
3. **Say what bounds it.** For each row: what limits the value's length,
   shape and meaning before the sink, and what happens at the sink when that
   limit is absent. State the bad outcome plainly — "a tag name with a slash
   writes outside the directory" — as the one sentence a reader can test.
4. **Say what to change**, per row, as a guard at the boundary rather than a
   patch at the sink. Say which rows you tested, and how.

The vocabulary is the defender's — boundary, untrusted value, sink, bound,
guard — and the comment is the stronger for it, because it tells the author
what to change. The comment must still name each concrete failure: a review
that says "validate the input" and stops has not reviewed the boundary. If
the harness tells you the model changed during the review, say so in the
comment, and name the model that wrote it.

## The prose

The comment is the deliverable, and a human reads it to decide something.
Write it in the **Simplified Technical English** described in
`~/.claude/CLAUDE.md`: short active sentences with a named actor, one idea
each, no `-ing` form as a noun, the same word for the same thing, and a
negative stated plainly. It makes the comment answerable in one pass, and it
leaves a vague claim nowhere to hide.

Your last message to the workspace is ordinary prose.

## Do not

- **Post a Gitea pull review.** Your comment is a plain comment. A plain
  comment behaves the same on an issue and on a pull, and it claims nothing
  about approval. Do not approve, do not request changes, and do not write a
  sentence that a reader would quote as an approval.
- **File issues.** That is a scout's output, and a review that files them
  makes work nobody sequenced. When you find separable work, name it in the
  comment in one sentence and say it needs an issue.
- **Commit, push, or open a PR.** This worktree is for reading. `/pickup` is
  the verb that writes code, and it starts from an issue somebody sequenced.
- **Change the thread.** No labels, no milestone, no edit of the body, no
  close, and no edit or delete of another author's comment.
- **Comment twice.** One review is one comment. Edit your own comment if you
  got something wrong before anybody answered; otherwise let it stand.
- **Ask questions and wait** — nobody is watching in real time. Make the
  routine judgement calls; put the material ones in the comment as open
  questions.
- **Touch other worktrees or the fort's configuration.**
- **Leave the answer in the session.** The workspace is swept; the comment is
  the record.

## After you stop

`claude --resume <session-id>` from a pane in this workspace continues the
review with its context (a teammate's move — `herdr --remote sfi-dev`, or
`ssh -t sfi-dev`). Nothing else preserves it: the fort keeps no transcript for
a review, and the workspace goes a day after the agent goes quiet.

A review writes nothing to the dotpm vault, because a review is not a promise.
`gotea catch-up` counts merges, issues filed and issues closed; it counts no
comments, so the weekly ritual does not yet see that this review happened
(sfi/gotea#68). The thread is where it is read.
