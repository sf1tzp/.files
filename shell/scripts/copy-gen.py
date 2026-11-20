#!/usr/bin/env python3
"""Copy candidate generator — companion to name-gen.py, backed by lab inference.

Usage: copy-gen.py [options] BRIEF...

  BRIEF            natural-language brief; "-" reads it from stdin
  --kind KIND      shape of copy to emit (default statement); --list to see them
  --n N            candidates to ask for per round (default 8)
  --rounds R       ask R times at different seeds and merge (default 1)
  --context FILE   prepend a file to the brief — a milestone description, a
                   style-guide excerpt, the page's existing copy (repeatable)
  --avoid WORDS    comma-separated words the copy must not use
  --maxlen N       drop candidates longer than N characters (default per kind)
  --temperature T  sampling temperature (default 0.9)
  --max-tokens N   completion budget (default 4096 — reasoning models spend
                   most of it thinking before the JSON comes out)
  --model M        model id (default $LLM_MODEL, else the first chat model served)
  --endpoint URL   OpenAI-compatible base URL (default $LLM_ENDPOINT, else
                   http://10.0.0.99:11434/v1 — LM Studio on win11)
  --voice FILE     replace the built-in house voice with this file's text
  --raw            print the model's raw reply instead of parsed candidates
  --list           print the kinds and exit

Emits one candidate per line (count on stderr) — pipe into a file, or into
the checker when scouting names:

  copy-gen.py --kind name "a calm, local-first time tracker" | name-check @-
  copy-gen.py --kind statement --context brand-study.md --n 12 - < brief.txt

The built-in voice is the captains-log knowledge-base style guide: direct,
declarative, no marketing language. Swap it with --voice for other work.
"""

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.request

DEFAULT_ENDPOINT = "http://10.0.0.99:11434/v1"

# The house voice forbids these; small models ignore the instruction often
# enough that they are also a hard filter (--voice FILE turns the filter off,
# --avoid adds to it).
BANNED = [
    "revolutionary", "blazing", "best-in-class", "seamless", "seamlessly",
    "leverage", "leverages", "leveraging", "empower", "empowers", "empowering",
    "unlock", "unlocks", "cutting-edge", "next-generation", "world-class",
    "robust", "synergy", "game-changing", "state-of-the-art", "elevate",
]

# kind: (instruction, default maxlen)
KINDS = {
    "statement": (
        "positioning statements: one or two sentences saying what the company "
        "or product is and what proves it. Concrete nouns, no adjectives doing "
        "the work.",
        240,
    ),
    "oneliner": (
        "one-line versions for a masthead or bio: under twelve words, no "
        "trailing period, no colon constructions.",
        80,
    ),
    "tagline": (
        "taglines: two to six words, no punctuation, no puns unless they are "
        "actually good.",
        40,
    ),
    "headline": (
        "page headlines: a short sentence fragment that names the idea, not "
        "the feature. Title case is not required.",
        70,
    ),
    "eyebrow": (
        "eyebrow labels: two to four words, lowercase, the kind that sits in "
        "mono type above a headline.",
        32,
    ),
    "paragraph": (
        "paragraphs of body copy: three to five sentences, active voice, one "
        "idea per sentence, no filler openers.",
        600,
    ),
    "cta": (
        "call-to-action labels: two to four words, a verb first, no exclamation "
        "marks.",
        28,
    ),
    "name": (
        "product or project names: one or two words, lowercase, pronounceable, "
        "no numerals, plausible as a domain or a registry token.",
        18,
    ),
    "custom": (
        "pieces of copy matching the brief's own description of what is wanted.",
        400,
    ),
}

HOUSE_VOICE = """\
Write like you're explaining something to a sharp colleague who hasn't met this
topic before. Direct, precise, confident, never condescending. Inspirations are
Apple and Anthropic: clear, considered prose that respects the reader's time.
No filler, no hedging, every sentence earns its place.

Do: active voice, declarative statements, say what a thing is and does, name
tradeoffs plainly.
Don't: marketing language, buzzwords or hype ("revolutionary", "blazing fast",
"best-in-class", "seamless", "leverage", "empower", "unlock"), excessive
hedging, padding, emoji, exclamation marks.
"""


def request(endpoint, path, payload=None, timeout=180):
    url = endpoint.rstrip("/") + path
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(
        url, data=data, headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.load(r)
    except urllib.error.URLError as e:
        sys.exit(
            f"{url}: {e.reason}\n"
            "  is the inference server up? LM Studio on win11 is started by "
            ".files/windows/services/lmstudio-server.ps1; set --endpoint or "
            "$LLM_ENDPOINT for another server."
        )


def pick_model(endpoint):
    models = [m["id"] for m in request(endpoint, "/models").get("data", [])]
    chat = [m for m in models if "embed" not in m.lower()]
    if not chat:
        sys.exit(f"no chat model loaded at {endpoint} (served: {', '.join(models) or 'none'})")
    return chat[0]


def build_messages(voice, kind, brief, context, n, avoid):
    instruction, _ = KINDS[kind]
    rules = [
        f"Produce exactly {n} distinct candidates. They are {instruction}",
        "Each candidate stands alone; do not number them or comment on them.",
        "Vary the angle across candidates, not just the wording.",
    ]
    if avoid:
        rules.append("Never use these words: " + ", ".join(avoid) + ".")
    rules.append(
        'Reply with JSON only: {"candidates": ["...", "..."]} — no prose around it.'
    )
    user = ""
    if context:
        user += "Context:\n\n" + "\n\n---\n\n".join(context) + "\n\n---\n\n"
    user += "Brief:\n\n" + brief.strip()
    return [
        {"role": "system", "content": voice.strip() + "\n\n" + "\n".join(rules)},
        {"role": "user", "content": user},
    ]


def parse_candidates(text):
    """The model was asked for JSON; take it if it's there, else fall back to lines."""
    m = re.search(r"\{.*\}", text, re.S)
    if m:
        try:
            obj = json.loads(m.group(0))
            cands = obj.get("candidates") if isinstance(obj, dict) else obj
            if isinstance(cands, list):
                return [str(c) for c in cands]
        except json.JSONDecodeError:
            pass
    lines = []
    for line in text.splitlines():
        line = re.sub(r"^\s*(?:[-*•]|\d+[.)])\s*", "", line).strip().strip('"“”')
        if line and not line.startswith(("{", "}", "[", "]")):
            lines.append(line)
    return lines


def clean(cands, kind, maxlen, avoid):
    out, seen = [], set()
    avoid_re = re.compile(
        r"\b(?:" + "|".join(re.escape(w) for w in avoid) + r")\b", re.I
    ) if avoid else None
    for c in cands:
        c = " ".join(c.split()).strip().strip('"“”')
        if kind == "name":
            c = c.lower()
        key = c.lower()
        if not c or key in seen or len(c) > maxlen:
            continue
        if avoid_re and avoid_re.search(c):
            continue
        seen.add(key)
        out.append(c)
    return out


def parse_args(argv):
    p = argparse.ArgumentParser(add_help=False)
    p.add_argument("brief", nargs="*")
    p.add_argument("--kind", default="statement")
    p.add_argument("--n", type=int, default=8)
    p.add_argument("--rounds", type=int, default=1)
    p.add_argument("--context", action="append", default=[])
    p.add_argument("--avoid", default="")
    p.add_argument("--maxlen", type=int)
    p.add_argument("--temperature", type=float, default=0.9)
    p.add_argument("--max-tokens", type=int, default=4096, dest="max_tokens")
    p.add_argument("--model", default=os.environ.get("LLM_MODEL"))
    p.add_argument("--endpoint", default=os.environ.get("LLM_ENDPOINT", DEFAULT_ENDPOINT))
    p.add_argument("--voice")
    p.add_argument("--raw", action="store_true")
    p.add_argument("--list", action="store_true")
    p.add_argument("-h", "--help", action="store_true")
    return p.parse_args(argv)


def main(argv):
    args = parse_args(argv)
    if args.help:
        sys.exit(__doc__)
    if args.list:
        for name, (instruction, maxlen) in KINDS.items():
            print(f"{name:10} ≤{maxlen:<4} {instruction.split('.')[0]}")
        return
    if args.kind not in KINDS:
        sys.exit(f"unknown kind: {args.kind} — see --list")

    brief = " ".join(args.brief)
    if brief.strip() == "-" or not brief.strip():
        brief = sys.stdin.read()
    if not brief.strip():
        sys.exit("no brief given — pass it as arguments or on stdin")

    context = [open(f, encoding="utf-8").read() for f in args.context]
    voice = open(args.voice, encoding="utf-8").read() if args.voice else HOUSE_VOICE
    avoid = [w.strip() for w in args.avoid.split(",") if w.strip()]
    if not args.voice:
        avoid = BANNED + avoid
    maxlen = args.maxlen or KINDS[args.kind][1]
    model = args.model or pick_model(args.endpoint)

    cands = []
    for seed in range(args.rounds):
        reply = request(
            args.endpoint,
            "/chat/completions",
            {
                "model": model,
                "messages": build_messages(voice, args.kind, brief, context, args.n, avoid),
                "temperature": args.temperature,
                "seed": seed,
                "max_tokens": args.max_tokens,
            },
        )
        choice = reply["choices"][0]
        text = choice["message"].get("content") or ""
        if not text.strip() and choice.get("finish_reason") == "length":
            spent = (reply.get("usage") or {}).get("completion_tokens_details", {})
            print(
                f"round {seed}: empty reply, budget exhausted "
                f"({spent.get('reasoning_tokens', '?')} reasoning tokens) — "
                "raise --max-tokens or pick a non-reasoning model",
                file=sys.stderr,
            )
        if args.raw:
            print(text)
            continue
        cands += parse_candidates(text)

    if args.raw:
        return
    cands = clean(cands, args.kind, maxlen, avoid)
    print("\n".join(cands))
    print(f"{len(cands)} candidates ({model})", file=sys.stderr)


if __name__ == "__main__":
    main(sys.argv[1:])
