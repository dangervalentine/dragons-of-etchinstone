# Contract: checks

## Unit tests

| Test | Asserts |
|---|---|
| `tests/test_design_tokens.gd` (new) | Every colour in `design-system/tokens.json` equals its token. Every size equals round(points × 1.85). Every type style matches family, weight, opsz, spacing and case. No old-palette token exists. Every style is ≥ `TEXT_MIN` except `CARD_NAME` (≥ `CARD_NAME_MIN`). |
| `tests/test_palette_contrast.gd` (new, replaces `test_stone_contrast.gd`) | Each text pair in research R4 is ≥ 4.5:1. `EDGE` on `STONE` and `GROUND` is ≥ 3:1. `STAT_HP` and each `ether_shade(lit)` on `STONE` is ≥ 3:1. `PARCHMENT_FAINT` is used only as the disabled colour (a source grep). Each Ether's `plate_ink` on `plate` and `pill_ink` on `pill` is ≥ 4.5:1. |
| `tests/test_card_contrast.gd` (rewritten in Phase 2 with `test_stone_contrast.gd` deleted, extended in US5) | `PARCHMENT` on `CARD_FRAME` and `CARD_RIBBON`; `BRASS_BRIGHT` on `CARD_RIBBON` ≥ 4.5:1; `PARCHMENT` and `BRASS` on `STAT_PLATE`; then each Ether's plate and pill inks as the card face draws them. |
| `tests/test_fonts.gd` (new) | Fraunces and Alegreya cover every non-ASCII character in `data/*.json` and in the UI's strings. Fraunces figures are tabular in `NUMERAL*` styles (equal advances for 0–9, by feature or by `numerals.gd`). No `Cinzel` file or reference remains under `ui/` or `art/`. |
| `tests/test_place_labels.gd` (updated) | States `empty/open/target/filled/inactive`. At most one `target`, chosen as data-model says. |
| `tests/test_card_face_layout.gd` (updated) | `LONGEST_LINE` is the widest line in Fraunces. Names are ≥ `CARD_NAME_MIN` at the scale of the smallest window. Numerals still fit their plates. |
| `tests/test_deck_stack.gd` (updated) | `card_radius(190) == 15`, `card_radius(400) == 32`. |
| `tests/test_settings*.gd` | A config with `display/ground` loads without error and the key is dropped. |

## UI check (`tools/ui_check.gd`)

In `_inspect_screen`:

- **Primary**: at most one visible Control with meta `primary`.
- **Target**: at most one place in state `target` (play screen).
- **Fonts**: no Label's font resolves to a face other than Fraunces or Alegreya Sans.
- **Text colour** (SC-002): every visible Label's colour is one of the text tokens proven
  in `test_palette_contrast`, ignoring alpha (`PARCHMENT_FAINT` only on a disabled
  control).
- **Focus**: a control given keyboard focus draws a `JADE` rim `BORDER_SELECT` wide.
- **Top-bar chips**: held to `TAP_MIN`, not `HELP_MIN`.

The existing text-size and tap-size checks stay. Text-size checks reach drawn text through
a meta `drawn_text_min` that each drawing widget sets to the smallest size it drew this
frame.

The `screens` walk opens the menu and asserts there is no Ground row.

## Visual review

`godot --path . -s tools/shot.gd -- build/screenshots/matrix` at every window size, judged by
the owner side by side with `design-system/components/EncounterScreen/preview.html`
(SC-007).
