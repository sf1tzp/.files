#!/usr/bin/env python3
"""Project-name availability funnel — Tier 1: free, no-auth registry checks.

Usage: name-check.py [--csv] <name|@file> [<name|@file> ...]

  <name>    candidate name (checked lowercase)
  @file     read newline-separated candidates from file
  @-        read candidates from stdin (pipe from name-gen.py)
  --csv     emit CSV to stdout instead of the table + worksheets

Checks: npm, PyPI, crates.io, Homebrew (formula+cask), GitHub user/org,
.com/.app/.dev (RDAP), App Store (iOS + Mac storefronts).

Verdicts:  free / TAKEN / ~N (N keyword matches, no title hit) / ? (check failed)
An all-free sweep is NOT clearance — it feeds the manual worksheet printed for
surviving names (trademark via Justia/USPTO, Google, say-it-out-loud).
"""

import csv
import json
import re
import sys
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import quote

UA = {"User-Agent": "name-check/0.2 (project naming due diligence)"}
TIMEOUT = 15
RETRIES = 3  # transient RDAP rate limits resolve with backoff

FREE, TAKEN, FAIL = "free", "TAKEN", "?"


def fetch(url):
    """Return (status_code, body) — transport errors become (None, str(err))."""
    req = urllib.request.Request(url, headers=UA)
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
            return r.status, r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, ""
    except Exception as e:  # noqa: BLE001 - network soup, report as unknown
        return None, str(e)


def free_if_404(url):
    status, _ = fetch(url)
    if status == 404:
        return FREE
    if status == 200:
        return TAKEN
    return FAIL


def check_npm(name):
    return free_if_404(f"https://registry.npmjs.org/{quote(name)}")


def check_pypi(name):
    # PyPI treats runs of -_. as equivalent; check the normalized form
    norm = re.sub(r"[-_.]+", "-", name).lower()
    return free_if_404(f"https://pypi.org/pypi/{norm}/json")


def check_crates(name):
    return free_if_404(f"https://crates.io/api/v1/crates/{quote(name)}")


def check_brew(name):
    f = free_if_404(f"https://formulae.brew.sh/api/formula/{quote(name)}.json")
    c = free_if_404(f"https://formulae.brew.sh/api/cask/{quote(name)}.json")
    if TAKEN in (f, c):
        return TAKEN
    return FAIL if FAIL in (f, c) else FREE


def check_github(name):
    # users and orgs share one namespace
    return free_if_404(f"https://api.github.com/users/{quote(name)}")


def check_domain(name, tld):
    return free_if_404(f"https://rdap.org/domain/{quote(name)}.{tld}")


def check_appstore(name, entity):
    status, body = fetch(
        f"https://itunes.apple.com/search?term={quote(name)}&entity={entity}&limit=25"
    )
    if status != 200:
        return FAIL
    results = json.loads(body).get("results", [])
    hits = [r for r in results if name.lower() in r.get("trackName", "").lower()]
    if hits:
        return f"{TAKEN}:{len(hits)}"
    return f"~{len(results)}" if results else FREE


CHECKS = {
    "npm": check_npm,
    "pypi": check_pypi,
    "crates": check_crates,
    "brew": check_brew,
    "github": check_github,
    ".com": lambda n: check_domain(n, "com"),
    ".app": lambda n: check_domain(n, "app"),
    ".dev": lambda n: check_domain(n, "dev"),
    "as-ios": lambda n: check_appstore(n, "software"),
    "as-mac": lambda n: check_appstore(n, "macSoftware"),
}


def run_check(fn, name):
    for attempt in range(RETRIES):
        result = fn(name)
        if result != FAIL:
            return result
        time.sleep(2 * (attempt + 1))
    return FAIL


def worksheet(name):
    q = quote(name)
    return "\n".join(
        [
            f"  Manual worksheet for '{name}':",
            f"    Justia (cls 9,42): https://trademarks.justia.com/search?q={q}",
            f"    USPTO search:      https://tmsearch.uspto.gov/search/search-information?q={q}",
            f"    Google:            https://www.google.com/search?q=%22{q}%22+software",
            f"                       https://www.google.com/search?q=%22{q}%22+app",
            "    Say it aloud; search phonetic near-misses in Justia too.",
        ]
    )


def parse_args(argv):
    as_csv, names = False, []
    for arg in argv:
        if arg == "--csv":
            as_csv = True
        elif arg == "@-":
            names += [ln.strip().lower() for ln in sys.stdin if ln.strip()]
        elif arg.startswith("@"):
            with open(arg[1:]) as f:
                names += [ln.strip().lower() for ln in f if ln.strip()]
        else:
            names.append(arg.lower())
    return as_csv, names


def main(argv):
    as_csv, names = parse_args(argv)
    if not names:
        sys.exit(__doc__)

    keys = list(CHECKS)
    with ThreadPoolExecutor(max_workers=16) as pool:
        futures = {
            (n, k): pool.submit(run_check, CHECKS[k], n) for n in names for k in keys
        }
    rows = {n: {k: futures[(n, k)].result() for k in keys} for n in names}

    if as_csv:
        out = csv.writer(sys.stdout)
        out.writerow(["name", *keys])
        for n in names:
            out.writerow([n, *(rows[n][k] for k in keys)])
        return

    w = max(len(n) for n in names) + 2
    print("".ljust(w) + "".join(k.ljust(9) for k in keys))
    for n in names:
        print(n.ljust(w) + "".join(rows[n][k].ljust(9) for k in keys))
    print()
    for n in names:
        if not any(v.startswith(TAKEN) for v in rows[n].values()):
            print(worksheet(n))
            print()


if __name__ == "__main__":
    main(sys.argv[1:])
