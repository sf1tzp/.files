---
name: kb
description: Write or update a Street Fortress knowledge-base document in the sfi/knowledge repo. Use when the user asks to document a technical topic (the why, then the how), or when a session surfaced a notable technique/pattern/tool that isn't in the knowledge base yet and the user agreed to capture it.
---

# Knowledge Base Writer

The knowledge base is the `sfi/knowledge` repo. It documents the **why** and
then the **how** of technical topics encountered at SFI, and a weekly job
revises it into the public handbook (sfi/deployments#511), so the bar is
"insightful reference," not "notes dump": a reader should come away
understanding why the technique exists, when to reach for it, and how to apply
it — with the trade-offs stated honestly.

**Find the repo before anything else.** It is nested in the Obsidian vault on
a workstation and stands alone on a dev fort, so no absolute path is right in
both layouts:

```sh
KB=$(ls -d ~/captains-log/knowledge ~/src/sfi/knowledge 2>/dev/null | head -1)
```

Every path below is relative to `$KB`. If neither exists, clone it:
`git clone ssh://git@gitea.zen.lofi:30022/sfi/knowledge.git`.

**What exists already:** `$KB/kb-map.txt` is the generated tree listing of the
repo — consult it (not the per-directory READMEs) to see current coverage.
Regenerate it with `just build-kb-map` in `$KB` when it looks stale, and again
before you commit. Nothing does this for you; there is no hook.

## Directory guide

| Directory            | Purpose                                                 |
| -------------------- | ------------------------------------------------------- |
| `paradigms/`         | Fundamental concepts in system design                   |
| `coding-practices/`  | Coding patterns, conventions, test strategies           |
| `config-management/` | Infrastructure-as-code guides and patterns              |
| `components/`        | Open source component operations (postgres, redis, etc) |
| `observability/`     | Logging patterns, metrics, the four golden signals      |
| `security/`          | Host configs, supply chain, network isolation           |
| `projects/`          | Publication pages for streetfortress.com/showcase       |

If placement is ambiguous (a testing technique with security implications, a
component with config-management concerns), pick the directory matching the
*primary lens of the document you're writing* and `[[link]]` to the others.

## Per-directory tone (2026-09-11 contract)

The general voice rules apply everywhere, but the audience — and therefore
the register — shifts by directory:

- `paradigms/` — the high-level **why and how** of system design.
- `components/` — **SFI-ops-focused what/where/how handbooks**: they orient
  *us* during ops work (`components/grafana-loki.md` is the model), not
  general upstream reference.
- `projects/` — **marketing surface**: proud, polished project descriptors
  that build the company image on streetfortress.com/showcase. No roadmap
  framing, no tech-debt or honest-state sections, no hedging about
  migrations in progress — state capabilities as achieved facts. Hype
  through confident, concrete capability; Apple/Anthropic-caliber prose,
  never buzzwords. The "honest trade-offs" rule below is for the internal
  directories, where the audience is ops — it does not apply here.
  (First applied in captains-log PR #46: forts.md, the sfi-platform.md
  rewrite — the old page read "roadmappy", which undercuts a showcase.)

## Note granularity (zettelkasten semantics)

The knowledge base is a zettelkasten-style graph. The retrieval question it
serves — especially for `coding-practices/` — is *"didn't we implement XYZ
before? What did we do, and what contextual information informed it?"* That
question shapes the rules:

- **One note per pattern, titled by the problem** — not per technology.
  `swiftui-drag-drop-transferable.md`, not a section buried in `swiftui.md`.
  A technology-titled doc is allowed as an *orientation* note (what the stack
  is, how it maps to what we know) that links out to its pattern notes; it
  must not accrete every pattern into one long document.
- **Split on provenance.** When a section of a note develops its own
  provenance — proven in a different project, for a different reason — split
  it into its own note and link it. Until then, don't split; premature
  scattering creates the link-maintenance overhead it's meant to avoid.
- **Constraints before code** in coding-practice notes. Paradigms explain why
  and how; a coding-practice note records *decisions plus the constraints
  that forced them* (API shape, missing transactionality, trust requirements).
  The constraints are what transfer to the next project; the code is residue.
- **Link economy, three tiers.** Discovery is `kb-map.txt` (generated, free).
  Curation is the per-directory README table (one hook line per doc — the
  hub). Inline `[[links]]` are sparse: only where reading one note genuinely
  calls for another. Do not maintain a dense mesh; a link earns its place
  like a sentence does.

## Document shape

**Voice, tone, and article structure are defined in `$KB/CLAUDE.md`
("Knowledge Base Style Guide") — read it before writing.** The arc is orient → explain → implement; direct, confident prose;
no filler, no hype, no emoji. On top of that guide:

- **Provenance line** near the top: where this was encountered at SFI
  (project, PR, incident). Real-world grounding is the knowledge base's
  differentiator.
- **Real examples over toy examples.** Prefer config/code lifted from the
  actual encounter (trimmed and anonymized as needed).
- **Honest trade-offs.** Include failure modes and security angles; a doc
  that reads like marketing is not insightful.
- **Obsidian `[[links]]`** to related knowledge docs — check `kb-map.txt` for
  targets. A `[[link]]` to a doc that doesn't exist yet is acceptable; it
  marks a topic worth writing.
- **References section** at the end: authoritative sources, upstream docs,
  and the SFI artifact (PR/repo) where the topic came up.

Model documents: `security/supply-chain.md`,
`coding-practices/vcr-casette-testing.md`, `coding-practices/s3-image-uploads.md`.

## Procedure

1. **Check coverage** in `$KB/kb-map.txt` — update an existing doc rather
   than duplicating it. Kebab-case filename matching the node title.
2. **Read the style guide** in `$KB/CLAUDE.md`, then write the document in the
   chosen directory.
3. **Update the directory `README.md`** table with the doc and a one-line
   hook (the READMEs remain the curated per-directory index; `kb-map.txt` is
   the generated whole-tree listing).
4. **Run `just build-kb-map`, then commit and push to `main`.** No branch,
   no PR, no review — `sfi/knowledge` is unguarded by design (captains-log#60),
   for agents as well as humans, and this is the one repo where the standing
   "you cannot push main" rule does not apply. Write for an internal reader:
   work-item references, `.lofi` hosts, gitea links and mesh addresses belong
   in these documents. Nothing here is public — the weekly job's PR on the
   public handbook repo is where a human reads prose before a stranger does.

## Lightweight capture

When a topic is worth remembering but not worth a full document right now, add
a bullet to the target directory README's "Topics to Document" list (create
that section if missing) with a one-line description of the angle — enough for
a future work session to pick it up cold.
