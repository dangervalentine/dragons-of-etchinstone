# Research: Unified Design System (Inkstone and Brass)

Findings from a survey of `ui/`, `tools/ui_check.gd`, `tests/` and the design system's
files, made 2026-10-22. File references are to the code as it stood at `c74c310`.

## R1. Where the tokens live and how they are checked

- **Decision**: Rewrite `ui/theme/tokens.gd` around the design system's names
  (`GROUND`, `STONE`, `STONE_RAISED`, `WELL`, `LINE`, `EDGE`, `PARCHMENT`, ... see
  [contracts/tokens.md](contracts/tokens.md)), with values copied from
  `design-system/tokens.json`. A new unit test, `tests/test_design_tokens.gd`, reads
  `res://specs/019-unified-design-system/design-system/tokens.json` and asserts that
  every colour in it equals the token of the same name and that every size equals the
  token's phone points × 1.85, rounded. The old names (`BG_BASE`, `GOLD`, `INK`...) are
  kept only as a migration bridge while the screens move over, then deleted (FR-001).
- **Rationale**: `tokens.gd` is already the one place widgets take values from (CLAUDE.md).
  Writing constants by hand keeps the GDScript `const` style and the `##` comments that
  cite their use, and the test makes `tokens.json` the source of truth without a
  generator step. The specs folder is in the project, so `res://specs/...` reads in
  headless tests. It does not ship: only resources and `data/*.json` are exported.
- **Alternatives considered**: a `tools/gen_tokens.py` generator like `gen_cards.py`
  (a second source to keep in step, and it would lose the hand-written `##` notes);
  copying `tokens.json` into `data/` (it would then ship with the game for nothing).

## R2. Phone points to design units

- **Decision**: Every design-system size is multiplied by **1.85** and rounded
  (the system's own factor for a 720-unit-tall base viewport). Type: banner 63, title 41,
  heading 31, card-name 20, numeral-xl 67, numeral 37, numeral-sm 26, label 22,
  button 30, body 28, body-sm 24, caption 22. Space: 7, 15, 22, 30, 44, 59. Chamfer:
  11, 18, 30. Card radius 8% of the card's width (8pt on a 100pt card), plate radius 7.
  Border: etch 2, edge 4, select 6. Top bar 74, action row 89, chip 52, coach tip at
  most 629 wide, dialog 666 wide.
- **Floors**: `TEXT_MIN` stays 22 (it equals `caption`, the system's smallest live text),
  with one exception, card names, whose floor becomes `CARD_NAME_MIN` 20. `TAP_MIN` stays
  88, larger than `touch-min` (81). `HELP_MIN` stays 44.
- **Rationale**: The current tokens already describe a design unit as "about half a
  point", which is what 1.85 gives. The current spacing (S 8, M 16) is about half the
  system's (`space-2` 8pt = 15 units), so gaps grow. The layout solver keeps deciding
  the large geometry (card sizes, zones); only widget gaps and padding move to the scale.
  Wherever a screen then fails the "fits inside the view" checks at a matrix size, its
  gap steps down one rung, and the step is recorded in a `##` comment.
- **Alternatives considered**: keeping today's spacing and changing only colour and type
  (not the system the owner asked for); scaling by 2.0 to keep round numbers (it makes
  the floors disagree with the system's own arithmetic).

## R3. Fonts

Measured with fontTools against the files in the zip:

| File | Glyphs | Axes | GSUB features | Notes |
|---|---|---|---|---|
| `Fraunces-Variable.woff2` | 223 | opsz 9–144, wght 100–900, SOFT 0–100, WONK 0–1 (default 1) | liga, rvrn | **no `tnum`/`lnum`**; proportional figures (advances 1024–1461) |
| `AlegreyaSans-{500,700,800}.woff2` | 224 | — | lnum, tnum, ... | missing → (U+2192), which the game's text uses |
| current `AlegreyaSans-*.ttf` | 1235 | — | lnum, tnum, ... | full coverage |

- **Decision**: Ship the **full upstream fonts** (Google Fonts, SIL OFL), not the zip's web
  subsets: `Fraunces[SOFT,WONK,opsz,wght].ttf` and Alegreya Sans Medium, Bold and
  ExtraBold `.ttf` in `art/fonts/`, with their OFL texts. Remove `Cinzel.ttf`,
  `OFL-Cinzel.txt` and `AlegreyaSans-Regular.ttf` (body moves to weight 500, as the
  system specifies). Before committing to them, run the glyph and feature script
  (quickstart step 1) to confirm the full Fraunces has `tnum` and `lnum` and that both
  faces cover every character the game's text uses.
- **Verified 2026-10-22 (T001)**: the full upstream Fraunces (624 glyphs, axes opsz/wght/SOFT/WONK)
  has GSUB features `case`, `liga`, `rvrn` and `ss01` only: **no `tnum`/`lnum`**, and it also lacks →
  (used by two numeral labels, `dragon_stats.gd:130` and `dragon_face.gd:356`). So the fallback below
  is taken, and every Fraunces variation carries the Alegreya Sans face of its weight as a
  `fallbacks` entry, which supplies →. The upstream Alegreya Medium and Bold are byte-identical to
  the ones already in `art/fonts/`.
- **Taken instead (T006)**: `tools/make_figures.py` cuts one static instance of Fraunces per numeral
  style (weight, opsz, SOFT 50, WONK 0) with every digit the widest digit's advance, centred, renamed
  "Etchinstone Figures" as the OFL asks of a modified font (Fraunces declares no Reserved Font
  Name). That gives Labels tabular figures too, which drawing digits one by one could not.
- **Fallback considered** (superseded by the line above): `ui/theme/numerals.gd` already lays out figures
  glyph by glyph by their ink. It would set each digit on a fixed advance (the widest
  digit's) to make figures tabular wherever figures must line up.
- **Axes**: each Fraunces style is its own `FontVariation` with `wght` from the style,
  `opsz` from the style (72, 36, 24, 12, and 72/24/14 for the numerals), `SOFT` 50 and
  `WONK` 0. Godot does not set `opsz` automatically.
- **Size**: Cinzel (125 KB) and Alegreya Regular (264 KB) leave. Fraunces' full variable
  file (about 300–400 KB) and Alegreya ExtraBold (about 265 KB) come in. The net change
  should be under SC-005's 1 MB; it is measured at implementation.
- **Rationale**: The subsets would lose the arrow glyph and tabular figures, both of which
  the spec needs (FR-014).
- **Alternatives considered**: shipping the subsets and patching around the missing glyphs
  (fragile); subsetting the full fonts ourselves with fontTools (a possible later size
  saving, not needed for the budget).

## R4. Contrast of the new palette

All pairs computed from `tokens.json` (WCAG 2.1):

- Text on the grounds passes everywhere: parchment 10.8–15.2, parchment-muted 5.8–8.2,
  brass 6.9–9.7, brass-bright 9.2–12.9, jade 6.9–9.7, danger 4.95–6.9, stat-hp 4.26–5.96
  (an icon colour, held to 3:1). Parchment-faint is 2.3–3.3, intended for disabled labels
  only.
- Rims: `edge` is 3.53 on stone and 4.00 on ground, but **2.97 on stone-raised**. The
  system claims 3:1 only on stone and ground. Buttons on `stone-raised` keep `edge`; the
  rim is a boundary, and the button's fill already separates it from the ground.
- Paper: paper-ink 11.65, paper-muted 5.61, brass-deep underline 3.66.
- On-brass: on brass 9.18, brass-bright 12.16, ochre 6.47, ochre-bright 9.38.
- Ether fields with parchment: lapis 4.53, amethyst 4.75, **cinnabar 4.49**. Figures
  never sit on the field (they are on `stat-plate`), so no live text uses these pairs.
  If one is ever needed, cinnabar becomes `#b8392d` (4.55), recorded as a deviation.
- **Bright Ether pills with parchment fail (2.71–2.95).** **Decision**: the highlighted
  pill's ink is the dark `stat-plate` (lapis-bright 5.47, amethyst-bright 5.26,
  cinnabar-bright 5.02) and `on-brass` on ochre-bright (9.38). The spec's acceptance
  scenario was corrected to say so.
- **Decision**: `tests/test_palette_contrast.gd` replaces `test_stone_contrast.gd` and
  checks every pair above at the threshold its token note states. `test_card_contrast.gd`
  is rewritten against the new card tokens.

## R5. Grounds, the Region wash and the backdrop

- Today `ui/fx/backdrop.gdshader` blends a stone grain (`art/stone/ground-N.png`, chosen
  in the menu) over a flat base. Its Ether tint (`main._tint_backdrop`, main.gd:1154) is
  mixed into the flat colour and then wholly replaced by stone at `stone_amount = 1`, so
  it is invisible today.
- **Decision**: the backdrop shader draws `GROUND`, plus a radial glow in a `wash`
  colour at `wash_amount` (`opacity-region-wash` 0.22), centred on a uniform point set to
  the centre of the left column (the Encounter or Region Card), with a radius of about
  0.6 of the view's height. `BackdropLayer.set_region(stage)` replaces `_tint_backdrop`:
  Region 1–4 take `REGION[n]`; `stage.kind == "final"` takes `REGION_LAIR`; screens without
  a game take no wash. The change between Regions tweens over `T.MOVE`, or is set at once
  under reduced motion.
- **Removed** (owner decision, FR-006a): `art/stone/`, `tools/make_ground.gd`,
  `Stone.grain/grain_image/ground_file/noise_image`, `Settings.GROUNDS/ground` and its
  load/save/reset (an old `display/ground` key is ignored on load), the menu's Ground row
  (`GROUND_NAMES`, tiles, `_set_ground`, `_swatch`), `main.gd:780` and
  `BackdropLayer.refresh_ground`, `STONE_L_*`, and the shader's `grain` and
  `stone_amount`. `tools/field_bench.gd` is updated to the new uniforms. If `stone.gd` is
  left empty, it is deleted.
- **Alternatives considered**: keeping the patterns recoloured (rejected by the owner).

## R6. What stays brass: the audit

There are about 134 `T.GOLD`/`T.FOCUS` uses. Classified by role:

| Role | ~Uses | New colour |
|---|---|---|
| Primary action (Play, Continue, Set out, Play again, Next, the dialog's answer) | 4 | `BRASS` fill, `ON_BRASS` ink |
| Selected (chosen tile, tab, card, current section, checkbox) | 14 | `BRASS` 6-unit rim |
| Target slot (the one place the next tap fills, the coach mark's target) | 6 | `BRASS` |
| Rewards (Score, XP, star, 1st, won, Level up, upgrade response) | 22 | `BRASS_BRIGHT` |
| Banner headlines (Region banner, game title, verdict) | 4 | `BRASS_BRIGHT` text only; the rim is the Region tint |
| Step emphasis (card figure rings, lit Region panel, board response "focus") | 11 | **`PARCHMENT`** rim/ring (see below) |
| Decorative headings and eyebrows | 19 | `PARCHMENT_MUTED` `LABEL` style, or `PARCHMENT` `HEADING` |
| Panel and slab rims at rest, ornaments, note accents | 24 | `EDGE` (or the Region tint for banners) |
| Icon tints (`icon_ink`, rulebook icons, pointers, tags) | 16 | `PARCHMENT` / `PARCHMENT_MUTED`; Ether icons keep their Ether |
| Keyboard focus rings | 6 | `JADE` 6-unit rim |
| Hover tints, flashes, data colours, effects | ~10 | `PARCHMENT` (hover), `BRASS_BRIGHT` only where the data is a reward |

- **Step emphasis** (feature 005, `emphasis.gd`) lifts the figures that matter in each
  animated step. It is not "the next thing you can do", so it cannot be brass. It
  becomes a parchment ring: the brightest neutral, which stands off the stone and the
  Ether fields without claiming brass. Board response roles keep their names
  (`test_board_responses` asserts names only): `focus` → parchment, `gold` → brass-bright
  (upgrade and encounter_won are rewards), `bad` → danger, `ether` → the Ether's bright
  partner, `neutral` → `EDGE`.
- **Highest-reach changes**: the `slab`/`stone_slab` default edge (theme.gd:327/337,
  about 10 overlays), `icon_ink` (theme.gd:139), `flash` (theme.gd:432), `table_note`'s
  gold accents, and `T.muted(T.FOCUS)` on every resting hand slot (hand_tray.gd:366).
- `T.muted()` and `ACCENT_MUTE` go: the new palette is already low-chroma, and muting
  brass would make a second, ambiguous gold.

## R7. One primary button, one target slot

- **Primary**: `UI.button(..., "primary")` is the only way to make one. It sets the meta
  `primary = true`. The second sources of gold buttons are found and fixed:
  - `boost_aim.gd:86/94` (chosen aim, and the Journey's fixed Move) become Tabs with a
    brass selected rim.
  - The confirm dialog's answer moves from `warning` red to brass; destructive answers
    (Abandon run, Clear records) keep a danger icon on the button.
  - `action_bar`'s FOCUS glow while ready goes. The brass fill is the signal; there are no
    glows for state (FR-018).
- **Target**: `view_state.places()` today marks *every other* place as `target` while a
  card is held (`test_place_labels.gd:67-79` asserts it). **Decision**:
  - The places a held card may go become `open`: parchment header, an `EDGE` rim.
  - Exactly one is `target`: the keyboard aim (`vs.key_target`) or, failing that, the
    one under the pointer, or, with nothing held, `vs.next_role` (TurnDraft's next empty
    slot).
  - The target takes the brass 6-unit rim and the brass header with its underline.
  - `test_place_labels` is updated to the new states. The breathing FOCUS glow on the
    Hand well (play_screen.gd:166) goes.
- **Checks** in `tools/ui_check.gd` `_inspect_screen`: at most one visible Control with
  meta `primary`, and at most one place in state `target` (in `_settle`). No colour
  contrast check is needed in the UI walk: every text colour is a token pair proven in
  R4's unit test.

## R8. Materials: stone, wells, paper and cards

- `StoneStyle` keeps its five kinds and API but is redrawn to the system:
  - **slab** (panels, trays, dialogs, banners): `STONE` face.
  - **plinth** (buttons and tabs): `STONE_RAISED` face, brass for the primary.
  - **well** (slots, chips, the Hand well): `WELL` face with an inset shadow.
  - **lintel**: the banner.
  - **inset**: unused, so it is deleted.
- Each slab has the edge rim (`EDGE`, 4 units), a 2-unit parchment-at-10% line inside the
  top edge, a 6-unit dark bottom bevel at 35%, and a hard 6-unit drop onto `#070b0c`
  (`SHADOW_DROP`). Pressed: the drop collapses to 2, the inset shadow at the top, and the
  Control moves down 4 (2pt).
- Chamfers: `CHAMFER_SM` 11 (chips, tabs, wells), `CHAMFER_MD` 18 (buttons, panels),
  `CHAMFER_LG` 30 (tray, dialogs, banners).
- **Paper**: `UI.paper_box()` replaces `tooltip_box()` (`PAPER` face, 2-unit darker paper
  edge, card shadow, corners rounded at `RADIUS_PLATE`: paper is rounded, never
  chamfered). It is used by
  tooltips, the coach bubble, the glossary (popover and full view), rulebook pages and
  the unspent-XP question. Text on it uses `PAPER_INK` and `PAPER_MUTED`. Glossary terms
  are bold with a `BRASS_DEEP` underline.
- **Cards**: `UI.card_radius(w)` becomes `w * 0.08`, and `card_face.gd:323` and
  `card_view.gd:406` call it. `face_frame.gd` (Encounter and Dragon faces) moves from a
  chamfered well to a rounded card. One `UI.card_shadow(lifted)` draws `shadow-card`, or
  `shadow-lift` while a card is held, dragged or inspected. It replaces the old `CARD_SHADOW` layer list and
  `card_face`'s single shadow. Out of play: a greyscale material at `OUT_OF_PLAY` 0.45,
  replacing today's dim-and-band treatment where the card is truly out of play (not
  merely ineligible this step, which keeps today's dimmed plates).
- Rationale: one StyleBox class already draws every stone thing, so the material change
  happens in one file.

## R9. Type styles and the uppercase pass

- Type tokens move from `[font, size]` to a style dictionary
  (`{family, size, weight, opsz, spacing, upper}`); see
  [contracts/type-styles.md](contracts/type-styles.md). `UI.font(style)` returns a cached
  `FontVariation` per style. `UI.label(text, style)` applies the size, the letter
  spacing and the case.
- Old to new: `TITLE`/`BANNER` → `BANNER`; `H1` → `TITLE`; `HEADING`/`SUBHEAD` →
  `HEADING`; `EYEBROW`/`LABEL_BOLD` → `LABEL`; `NUMERAL_S` → `NUMERAL_SM`; `NUMERAL` →
  `NUMERAL`; `NUMERAL_L` → `NUMERAL_XL`; `NUMERAL_M` (unused) is deleted; `BODY` → `BODY`;
  `LABEL` → `BODY_SM`, or `CAPTION` for hints and fine print; `BUTTON` → `BUTTON`.
- **Cinzel had no lower case**, so every display-face string shows in capitals today
  regardless of its source text. With Fraunces, case is what the string says. So:
  - Strings in banner, card-name and label roles are uppercased by the style
    (`upper: true`).
  - The 20-odd scattered `.to_upper()` calls are removed where the style does it, and
    removed outright for titles and headings, which become title case (FR-013).
  - The top bar's heading becomes `"%s · Region %d"`, with the number in
    `PARCHMENT_MUTED` (a two-run label), and `"%s, %s · Final Battle"` likewise.
- **Card names**: `card_face.gd:853` stops loading Cinzel itself and uses the card-name
  style. `LONGEST_LINE` and the name-size search are re-measured in Fraunces. The floor
  rises from 6 to `CARD_NAME_MIN` (20 at 1280×720 scale, applied as 20/720 of the view
  height on screen through the card's scale). The two `test_card_face_layout` legibility
  tests are updated to the new floor. If "DESTRUCTION" is no longer the widest line in
  Fraunces, the constant changes to whichever is.
- **Drawn text** (`draw_string` in xp_purse, soak_meter, region_card, dragon_card,
  stat_chip, trashed_back, card_view, region_panel, dragon_face) is not seen by the UI
  check today. Each one gets a type style, and its computed size is clamped at `TEXT_MIN`
  (or `CARD_NAME_MIN` for card names, the `NAME_MIN` in dragon_face).

## R10. Components

Each design-system component maps to one builder (see
[contracts/components.md](contracts/components.md)):

| Component | Builder | Replaces |
|---|---|---|
| Button | `UI.button(text, kind)` with kinds stone / primary / quiet | `style_button` (dead), `warning`, `active` |
| Tabs | `UI.tabs(options, selected)` → `ui/widgets/tab_row.gd` | ChoiceTile in records filters, Boost aim, rulebook contents, menu settings |
| Slot | `place_labels` + `hand_tray._Outline` redrawn as header + sunken well | square gold boxes |
| Panel | `UI.panel(heading, icon)` (slab with heading, brass glyph, line rule) | `slab`, `stone_slab`, `stone_zone`, `raised_panel_box` (dead), `panel` |
| Chip | `UI.chip(icon, figure, tone)` (well, `NUMERAL_SM`, reward/harm tones) | header pile counts, preview `_pill`, `stat_chip` plates |
| Dialog | `confirm_dialog.gd` with a title, a consequence line, stone left, brass right | untitled red-answer dialog |
| Banner | `stage_banner.gd`, also used for victory and defeat in `ending_screen` | gold lintel; the ending's carved slab |
| Ledger | `ui/widgets/ledger.gd` (heads, hairlines, numeral scores, one best row) | records rows, ending score table, rulebook `_table`, dragon table |
| CoachTip | `UI.paper_box` + `coach_mark` pointer; target ring brass | dark tooltip bubble, FOCUS rim |
| TopBar | `header_bar.gd`: stone bar, `CARD_FRAME` foot line, chips, slab menu button | flat icons, carved Cinzel heading |
| MageCard | `card_face.gd` frame, ribbon, plates, bright pill, glyph | as R8, R9, R11 |

- ChoiceTile stays only for rich choices with descriptions (the setup difficulty grid, alternate rules; the records difficulty filter becomes tabs),
  restyled as stone plinths with the brass selected rim.

## R11. Ethers

- `ETHER` becomes `{element: {"base": ..., "bright": ...}}`: fire → cinnabar,
  water → lapis, lightning → ochre, shadow → amethyst. The shade roles are:
  - `deep`: the base darkened 0.55, for field centres and shadows.
  - `lit`: the **bright partner**, for icons and text on stone. Each passes 3:1 on stone;
    to be confirmed by the contrast test.
  - `plate`: the base.
  - `plate_ink`: `ON_BRASS` on ochre, `PARCHMENT` on the others (≥4.5 per R4).
  - `pill`: the bright partner.
  - `pill_ink`: `STAT_PLATE`, or `ON_BRASS` on ochre.
- Every consumer listed in the audit (shaders via `card_face`/`face_frame`, board
  responses, creature particles, dragon washes, records/dragon accents, the Ether picker,
  table notes, rulebook inline icons) reads from these. `ether_card.gdshader` and
  `ether_field.gdshader` keep their uniforms; only their inputs change. The iridescent
  foil (ether_card.gdshader:55) stays as art.

## R12. Literals and extension tokens

The game needs a few colours the system does not name. They become tokens with `##`
notes saying they extend the system:

- `METAL` (sword blades and metal glyphs) and `GLASS` (the time-penalty chip): today's
  STEEL/GLASS, moved into the slate family.
- `CARD_EDGE` and `CARD_EDGE_LINE` (the Deck from the side).
- `CREATURE_LINE`.
- `SHADOW_DROP` `#070b0c`.
- `LOCKED` (a locked dragon's silhouette).
- `DIM_MODULATE` (unchosen dragons).
- `DECK_BACK`.

Neutral black and white at an alpha (shadows, bevels, hover washes) become the extension
tokens `SHADE` and `SHEEN`, used as `Color(T.SHADE, a)` and `Color(T.SHEEN, a)`, so SC-001's
search finds no literal outside `tokens.gd` (analysis I4). The only exceptions are the
over-bright flash modulates (channels above 1), which are not palette colours and are
marked so in a comment. The shader defaults that duplicate tokens
(backdrop.gdshader:7-8) are set from the tokens at run time.

## R13. Motion

- **Press**: today's scale to 0.96 over 0.08 s becomes the slab dropping 4 units
  (2pt) with its bevel collapsed, over `PRESS` 0.08 s, and rising over `RELEASE` 0.12 s.
  Under reduced motion it switches to the pressed style with no travel.
- **Cards** in flight already move rather than fade. Their settle gains a short overshoot
  (`Tween.TRANS_BACK`, ease out) in the flight layer's final leg. Under reduced motion
  they go straight to place, as today.
- **Banners** already slide in. They now also slide out instead of fading. Under reduced
  motion they appear and clear in place.

## R14. Constitution

`.specify/memory/constitution.md` is still the unfilled template, so there are no gates.
The project conventions in CLAUDE.md (no `class_name`, preloads, `##` comments citing
specs, tests on `tests/base.gd`, reduced motion as a first-class path, the engine never
touching `ui/`) are the working constraints, and this design keeps all of them.
