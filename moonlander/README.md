# Moonlander layout

Offline dump of the ZSA Moonlander layout "My Layout v3", so the keymap
survives Oryx and is diffable across revisions.

- Oryx (canonical editor): <https://configure.zsa.io/moonlander/layouts/JJaM7/latest/0>
- Layout hash `JJaM7`, this dump from revision `VqyPde` (QMK 25.0, 2026-10-30).

## Contents

- `layout.json` — full layer data from the Oryx GraphQL API (titles, every
  key's tap/hold/modifiers/colors). The richest artifact; regenerate with:

  ```sh
  curl -s -X POST https://oryx.zsa.io/graphql \
    -H 'Content-Type: application/json' \
    -d '{"query":"query($h:String!,$r:String!){layout(hashId:$h,revisionId:$r){revision{layers{position title keys}}}}","variables":{"h":"JJaM7","r":"latest"}}'
  ```

- `qmk-source/` — Oryx's compiled source drop (from the API's `zipUrl`):
  `keymap.c`/`config.h`/`rules.mk`, the compiled rev A and rev B firmware
  binaries with md5s, and the build log. Generated — refetch, never hand-edit.

## Layers

| # | Name | Access |
| --- | --- | --- |
| 0 | Letters | base (QWERTY, ctrl-arrow word nav, MEH thumbs) |
| 1 | Symbols | OSL on right thumb |
| 2 | Arrows | |
| 3 | Media | |
| 4 | Gaming | |
| 5 | Colemak | |
| 6 | Numbers → **Recording** | hold left-thumb Backspace (MO) |

Layer 6's number-pad experiment never built muscle memory; it is being
repurposed as the OBS/FCP recording layer (left hand: F13–F20 per the
hotkey table in the vault's `video/OBS.md`; right hand reserved for FCP
chords once the editor habits settle). Flash via Keymapp with the rev B
binary, or re-download from Oryx after editing there.

## Future: CLI build & flash

The source targets ZSA's QMK fork (`zsa/qmk_firmware`), not vanilla QMK.
A web-editor-free loop is: clone the fork, add this keymap, `qmk compile
-kb zsa/moonlander`, flash with `wally-cli`. Own session; the round-trip
through Oryx downloads is why this keyboard never got power-used.
