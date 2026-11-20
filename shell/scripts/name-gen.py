#!/usr/bin/env python3
"""Project-name candidate generator — companion to name-check.py.

Usage: name-gen.py [options] [bank ...]

  bank             word banks to cross (default: all); --list to see them
  --vary NAME      thematic variants: swap each word of NAME for its bank
                   siblings (given alone, emits only variants; add banks or
                   other modes to also get combos)
  --three          also emit three-word combos (one word from each of three banks)
  --blend          also emit portmanteaus (pairs merged on a 2+ letter overlap)
  --sep S          joiner between words (default "" — registries want one token)
  --maxlen N       drop candidates longer than N characters (default 18)
  --max N          seeded random sample down to N candidates (see --seed)
  --seed N         sample seed (default 0, so runs are reproducible)
  --bank NAME=a,b  add a bank (or extend a built-in) for this run
  --list           print the banks and exit

Emits one lowercase candidate per line (count on stderr) — pipe straight
into the checker:

  name-gen.py time record --max 40 | name-check @-

Default banks are tuned for the PrimeTime rename; --bank replaces the
tuning, not the tool.
"""

import argparse
import random
import re
import sys
from itertools import permutations

BANKS = {
    # what the product measures
    "time": ["time", "hour", "day", "chrono", "tempo", "tick", "moment",
             "span", "spell", "epoch", "era"],
    # the dimensional / geometric reading
    "space": ["dimension", "axis", "vector", "plane", "facet", "prism",
              "angle", "orbit", "meridian", "quadrant", "grid", "field",
              "frame", "layer", "depth"],
    # the record / instrument it becomes
    "record": ["atlas", "ledger", "log", "chart", "index", "trace", "tally",
               "map", "gauge", "scope", "dial"],
    # the calm the brand is steering toward
    "calm": ["clear", "lucid", "still", "plain", "true", "even", "quiet"],
}

AWKWARD = re.compile(r"(.)\1\1")  # triple letters at a seam read as typos


def word_pairs(banks, names):
    """Ordered cross-bank word pairs; within-bank pairs if one bank given."""
    if len(names) == 1:
        words = banks[names[0]]
        return [(a, b) for a in words for b in words if a != b]
    return [
        (a, b)
        for x, y in permutations(names, 2)
        for a in banks[x]
        for b in banks[y]
    ]


def blends(pairs):
    """Merge each pair on its longest 2+ letter overlap: tempo+orbit → temporbit."""
    out = []
    for a, b in pairs:
        for k in range(min(len(a), len(b)) - 1, 1, -1):
            if a[-k:] == b[:k]:
                out.append(a + b[k:])
                break
    return out


def variants(banks, name, sep):
    """Swap each word of `name` for its bank siblings, one position at a time."""
    words = [w for w in re.split(r"[\s_-]+", name.lower()) if w]
    out = []
    for i, word in enumerate(words):
        stem = word[:-1] if word.endswith("s") else word
        siblings = {
            w
            for wl in banks.values()
            if word in wl or stem in wl
            for w in wl
            if w not in (word, stem)
        }
        if not siblings:
            print(f"  ({word}: in no bank, kept fixed)", file=sys.stderr)
        out += [sep.join(words[:i] + [s] + words[i + 1:]) for s in sorted(siblings)]
    return out


def parse_args(argv):
    p = argparse.ArgumentParser(add_help=False)
    p.add_argument("banks", nargs="*")
    p.add_argument("--vary")
    p.add_argument("--three", action="store_true")
    p.add_argument("--blend", action="store_true")
    p.add_argument("--sep", default="")
    p.add_argument("--maxlen", type=int, default=18)
    p.add_argument("--max", type=int, dest="cap")
    p.add_argument("--seed", type=int, default=0)
    p.add_argument("--bank", action="append", default=[])
    p.add_argument("--list", action="store_true")
    p.add_argument("-h", "--help", action="store_true")
    return p.parse_args(argv)


def main(argv):
    args = parse_args(argv)
    if args.help:
        sys.exit(__doc__)

    banks = {k: list(v) for k, v in BANKS.items()}
    for spec in args.bank:
        name, _, words = spec.partition("=")
        banks.setdefault(name, [])
        banks[name] += [w.strip().lower() for w in words.split(",") if w.strip()]

    if args.list:
        for name, words in banks.items():
            print(f"{name:8} {' '.join(words)}")
        return

    unknown = [b for b in args.banks if b not in banks]
    if unknown:
        sys.exit(f"unknown bank(s): {', '.join(unknown)} — see --list")

    names = args.banks or list(banks)
    combos = not (args.vary and not args.banks and not args.three and not args.blend)

    cands = []
    if combos:
        pairs = word_pairs(banks, names)
        cands += [f"{a}{args.sep}{b}" for a, b in pairs]
        if args.three:
            if len(names) < 3:
                print("--three needs 3+ banks, skipped", file=sys.stderr)
            cands += [
                f"{a}{args.sep}{b}{args.sep}{c}"
                for x, y, z in permutations(names, 3)
                for a in banks[x]
                for b in banks[y]
                for c in banks[z]
            ]
        if args.blend:
            cands += blends(pairs)
    if args.vary:
        cands += variants(banks, args.vary, args.sep)

    cands = [
        c
        for c in dict.fromkeys(cands)
        if len(c) <= args.maxlen and not AWKWARD.search(c)
    ]
    if args.cap is not None and len(cands) > args.cap:
        cands = random.Random(args.seed).sample(cands, args.cap)

    print("\n".join(cands))
    print(f"{len(cands)} candidates", file=sys.stderr)


if __name__ == "__main__":
    main(sys.argv[1:])
