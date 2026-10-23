# Quickstart: validating the design system

Run from the repository root. `godot` must be on `PATH`.

## 1. Fonts before anything else (research R3)

Download the full fonts, then check their axes, figure features and coverage before they
replace anything. Keep the downloads and the script in the scratchpad, not in the repo.

```sh
uv run -q --no-project --with fonttools --with brotli python -I <scratchpad>/fontinfo.py \
  art/fonts/Fraunces*.ttf art/fonts/AlegreyaSans-*.ttf
```

**Expected**:

- Fraunces lists the axes `opsz`, `wght`, `SOFT` and `WONK`, and its features include
  `tnum` (if not, take R3's fallback).
- No character the game uses is missing; →, ·, −, — and é all present.
- `du -ch art/fonts/*.ttf` is within 1 MB of the old total (SC-005).

## 2. Tokens and contrast

```sh
tools/test.sh unit design_tokens palette_contrast card_contrast fonts
```

**Expected**: all pass. A colour or size typed wrongly against `tokens.json` fails
`design_tokens` and names the token.

## 3. The areas each step touches

| After changing | Run |
|---|---|
| tokens, fonts, theme helpers | `tools/test.sh unit` (all, about 8 s), then `tools/test.sh ui screens` |
| ground, wash, backdrop, settings | `tools/test.sh unit settings` and `tools/test.sh ui screens play` |
| slots, hand, places | `tools/test.sh unit place_labels view_state turn_draft` and `tools/test.sh ui arrange play` |
| card faces and materials | `tools/test.sh unit card_face_layout deck_stack card_contrast` and `tools/test.sh ui marks play deck skip look` |
| coach tip, paper surfaces | `tools/test.sh ui lessons screens` |
| banners, ending, ledger | `tools/test.sh ui ending screens` |
| spacing that changes layout | `tools/test.sh ui full screens` |

## 4. The whole

```sh
tools/test.sh full
```

**Expected**: every unit test and every walk at every window size passes, still and
animated, with no `SCRIPT ERROR`. This includes the new checks: at most one primary
button, at most one target slot, and no foreign font.

## 5. Look

```sh
godot --path . -s tools/shot.gd -- build/screenshots/matrix
open specs/019-unified-design-system/design-system/components/EncounterScreen/preview.html
```

**Expected** (SC-007, judged by the owner):

- The play screen sits on the slate ground with a soft Region glow behind the card.
- Panels are chamfered stone with `EDGE` rims and no gold at rest.
- The next slot and Play are the only brass things.
- Card names and titles are in Fraunces, title case.
- Coach tips are on paper.

Also check one screenshot per Region and one in the Final Battle for the wash tint, and
one with reduced motion on.

## 6. On devices

Use the `install-on-emulators` skill (Android emulator, iOS simulator, web) to check the
fonts and the wash on real renderers, especially the GL Compatibility web build.
