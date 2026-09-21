#!/usr/bin/env python3
"""Apply a milestone schedule: Gitea due dates + blocked-by links, then vault start dates.

usage: apply-schedule.py OWNER/REPO PLAN [--milestone ID --due YYYY-MM-DD] [--dry-run]

PLAN lines:  <index>  <start YYYY-MM-DD>  <due YYYY-MM-DD>  [blockers: 1,2,3]
Blank lines and lines starting with # are ignored.

Gitea writes go through `tea api` (already authenticated). Start dates go
through `npm run set-start` in ~/code/gitea-dotpm-sync after a full sync of
the stream that mirrors the repo, so every identity exists before it is stamped.
"""
import json, os, re, subprocess, sys
from datetime import date

SYNC_DIR = os.path.expanduser("~/code/gitea-dotpm-sync")


def die(msg):
    sys.exit(f"error: {msg}")


def tea(method, path, body=None):
    cmd = ["tea", "api", "-X", method, path]
    if body is not None:
        cmd += ["-d", json.dumps(body)]
    p = subprocess.run(cmd, capture_output=True, text=True)
    return p.returncode, (p.stdout + p.stderr).strip()


def parse_plan(path):
    rows = []
    for n, line in enumerate(open(path), 1):
        line = line.split("#", 1)[0].strip() if not line.lstrip().startswith("#") else ""
        if not line:
            continue
        parts = line.split()
        if len(parts) not in (3, 4):
            die(f"{path}:{n}: expected 'index start due [blockers]'")
        idx, start, due = int(parts[0]), date.fromisoformat(parts[1]), date.fromisoformat(parts[2])
        blockers = [int(b) for b in parts[3].split(",")] if len(parts) == 4 else []
        if start > due:
            die(f"#{idx}: start {start} is after due {due}")
        rows.append((idx, start, due, blockers))
    return rows


def stream_for(repo):
    cfg = json.load(open(os.path.join(SYNC_DIR, "config.json")))
    for s in cfg["streams"]:
        if repo in s["repos"]:
            return s["project"]
    die(f"no stream in {SYNC_DIR}/config.json mirrors {repo}")


def main(argv):
    import argparse
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("repo", help="owner/repo, e.g. sfi/sfi-website")
    ap.add_argument("plan", help="plan file: index start due [blockers]")
    ap.add_argument("--milestone", help="milestone id to re-date (with --due)")
    ap.add_argument("--due", help="milestone due date YYYY-MM-DD")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args(argv)
    if bool(a.milestone) != bool(a.due):
        die("--milestone and --due go together")
    repo, plan_path, dry, ms_id, ms_due = a.repo, a.plan, a.dry_run, a.milestone, a.due
    if ms_due:
        date.fromisoformat(ms_due)
    rows = parse_plan(plan_path)
    stream = stream_for(repo)
    tag = "[dry-run] " if dry else ""

    if ms_id:
        print(f"{tag}milestone {ms_id}: due -> {ms_due}")
        if not dry:
            rc, out = tea("PATCH", f"repos/{repo}/milestones/{ms_id}", {"due_on": f"{ms_due}T23:59:59Z"})
            rc == 0 or die(out)

    for idx, start, due, blockers in rows:
        print(f"{tag}#{idx}: due -> {due}" + (f", blocked by {blockers}" if blockers else ""))
        if dry:
            continue
        rc, out = tea("PATCH", f"repos/{repo}/issues/{idx}", {"due_date": f"{due}T23:59:59Z"})
        rc == 0 or die(f"#{idx} due: {out}")
        owner, name = repo.split("/")
        for b in blockers:
            rc, out = tea("POST", f"repos/{repo}/issues/{idx}/dependencies", {"owner": owner, "repo": name, "index": b})
            if rc != 0 and not re.search(r"already|exists|conflict", out, re.I):
                die(f"#{idx} blocked-by #{b}: {out}")

    starts = []
    for idx, start, _, _ in rows:
        starts += [f"{repo}#{idx}", start.isoformat()]
    print(f"{tag}sync stream '{stream}' then set-start for {len(rows)} issue(s)")
    if dry:
        return
    subprocess.run(["npm", "run", "sync", "--", "--stream", stream, "--full"], cwd=SYNC_DIR, check=True)
    subprocess.run(["npm", "run", "set-start", "--"] + starts, cwd=SYNC_DIR, check=True)
    print("done — now append the narrative to the milestone, set the milestone task's start, commit and push planning/")


if __name__ == "__main__":
    main(sys.argv[1:])
