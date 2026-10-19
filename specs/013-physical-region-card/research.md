# Research: The Left Side as the Physical Region Card and Deck

The spec has no open NEEDS CLARIFICATION items. The one question raised during `/speckit-specify` (where the old box's feedback goes) was answered and recorded in the spec's Clarifications.

The decisions below build on `specs/012-deck-region-card/research.md` (R1–R11 there). Where they conflict, this file wins. 012's motion decisions stand: its Sequencer steps, Key Card peek, `turn_to`, the hold during sequences and the anchors.

---

## R1. The printed Region Card's geometry

**Decision**: The Region Card is drawn to the printed card's proportions. These were measured from `reference/sheets-official/o5.png` (each card is about 498 × 695 px, aspect ≈ 5 : 7).

All values are fractions of the card's width (x) or height (y):

| Part | x | y | Notes |
|---|---|---|---|
| Title band | 0 – 1 | 0 – 0.105 | Name over "REGION n", centred, a skull ornament at each end |
| Enemy 1, Enemy 2 | 0.045 – 0.49, 0.51 – 0.955 | 0.135 – 0.355 | Panel aspect ≈ 1.45 |
| Enemy 3, Enemy 4 | as above | 0.39 – 0.61 | |
| Journeys 1–4 | four equal columns across 0.005 – 0.995, gap 0.008 | 0.655 – 0.955 | Panel aspect ≈ 0.6. The header strip is the top 0.25 of the panel |
| Foot | | 0.955 – 1 | Bare. The printed card code lives here and is not drawn |

The constants live in one place, `RegionCard.LAYOUT`, so a design-shot overlay against the scan can tune them.

**Rationale**:
- The user asked for the physical card's look.
- Fixed fractions make the card one rigid picture that scales as a whole. The zoom (R3) depends on that.

**Alternatives considered**:
- 012's 2 × 4 grid of tiles shaped like the face: this is what the user rejected.
- A container-based layout: it reflows with size, so the zoomed panel would not be the same picture enlarged.

## R2. One panel widget, drawn by its own size

**Decision**: A new `RegionPanel` (`ui/widgets/region_panel.gd`) replaces 012's `region_tile.gd`. It draws one Enemy or Journey in the printed layout, with every part placed as a fraction of the panel's own size:

- **Enemy**:
  - Art panel with the creature (cropped by `EncounterFace.enemy_crop`).
  - Left badge column: HP (heart), Initiative, Attack (Ether), Armor (Ether; two shields side by side when there are two).
  - Ability disc at the top right.
  - XP star at the bottom right.
- **Journey**:
  - Header strip with the MP badge (Ether mountain) and the Time Penalty (hourglass).
  - Landscape art below.
  - Peril disc at the top right of the art.
  - XP star centred at the foot.

Badges are `StatChip`s, whose numerals already fit their shape's window at any size (commits 78b1a4c, 3485a69), so the same panel reads correctly at 90 px wide on the card and at 360 px zoomed in. The Encounter number marker is the game's one addition (spec FR-002/FR-003): a small numeral plate at the art's top-left corner, in `T.LABEL_BOLD` on `T.BG_BASE` at 0.72 alpha, like 012's tile corner.

**Rationale**:
- One class for both sizes guarantees that the zoomed Encounter is the same panel enlarged (FR-008).
- `StatChip` already carries the glossary help, so badges explain themselves at both sizes.

**Alternatives considered**:
- Scaling a small panel up by transform: text and icons rasterise at the small size and blur.
- Keeping `EncounterFace` as the landing face: it is a different picture, which FR-008 rules out.

## R3. Zoom: the card itself scales; the landed face is a full-size panel

**Decision**:
- **Zoom in**: `DeckStack.zoom_in(target)` scales and moves the whole top card about the target panel until that panel fills the **panel rect**. The panel rect is the face rect less the reading strip (R4), with the panel's aspect fitted and centred.
- **Landing**: on landing, the scaled card is hidden and a full-size `RegionPanel` of the same Encounter (the **landed panel**) takes its exact rect. Both are the same layout at the same rect, so the swap is invisible. The landed panel's creature starts moving.
- **Zoom out**: `zoom_out` is the reverse. The landed panel hides, and the card appears scaled at the panel rect and shrinks back to the card rect.
- **Reduced motion**: a cross-fade, as in 012.

012 cross-faded between a tile and a different face. Here no cross-fade is needed in full motion, because what grows *is* the panel.

**Rationale**: The zoom reads as one physical card being looked at more closely. The landed panel keeps text crisp and lets the creature move.

**Alternatives considered**:
- Leaving the card scaled at rest: blurry text, eight creatures in the tree, and hit-testing through a transform.
- 012's shared-element cross-fade: unnecessary now that both ends are the same picture.

## R4. The reading strip: what icons stand for, written out

**Decision**: Under the landed panel (or beside it, if the face rect is wider than tall after fitting) sits a **reading strip** on the card's own stone. It is part of the face area and appears only when zoomed in. It holds:

1. **Name line**: the Encounter icon and number, and the Encounter's name (`tile.title`), as today's face band shows.
2. **Hardship** (from the Key Card): its icon and its short text from the `Glossary` (for example, "Ambush: Early Damage is doubled").
3. **Ability or Peril**: its icon and short text.

Each line's icon is the same disc the panel shows, so the strip is a key to the panel. Lines with nothing to say are omitted (spec edge case). Each line's `StatChip` keeps its help on press.

The Hardship also appears on the landed panel as a disc on the art's top edge, beside any Ability or Peril, as today's face does. That way the panel alone shows everything that is in play.

**Rationale**: FR-009 requires that an icon's meaning be readable without leaving the left side. The printed card relies on the rulebook for that. The strip keeps the panel faithful and puts the words beside it.

**Alternatives considered**:
- Words inside the panel: this breaks the printed look.
- Words only in a tooltip: no hover on touch, and it fails FR-009's "visible".

## R5. The left column is one region

**Decision**: `layout_solver.solve` no longer splits the left column.
- The `encounter` region takes the column's whole body height, and the `preview` region is removed.
- The `preview_needed` and `encounter_min` parameters go, along with `play_screen._replan`'s preview and dragon measuring.
- `T.ENCOUNTER_MIN`, `T.DRAGON_MIN` and `T.PREVIEW_MIN` are retired.
- A new `T.LEFT_MIN_W` (400) records the narrowest column, which fixes the smallest whole card (R9).

The region keeps the name `encounter` to limit churn in `point()`, `ui_check` and `space_audit`.

**Rationale**: The spec requires the column to hold only the stack (FR-005). The preview box was 011's interim (the user confirmed it was meant to be removed).

**Alternatives considered**: Keeping a zero-height preview region. It is dead geometry that every check would have to special-case.

## R6. The note: feedback laid on the stack in the card's place

**Decision**: A new `TableNote` (`ui/widgets/table_note.gd`) is a card-shaped stone panel, the size of the face rect. It lies on top of the stack, above the top card and the landed panel, with the Deck's edges still showing beneath it. It hosts the existing widgets, now moved into it from the removed region:

| Note | Shown when | Content | Leaves when |
|---|---|---|---|
| `setup` | `phase == "setup"` | Replaces `setup_face`'s text. "PREPARE YOUR DECK", the dragon art, and the setup step and prompt from `vs.prompt` | The first Region Card is laid (`turn_to`) |
| `mode` | `vs.mode` is `fuse`, `divert` or `regroup` | The step eyebrow and the step text (today's `PreviewPanel._prompt`, without the building tips) | The mode ends or is cancelled |
| `refusal` | `main._refuse(text)` | The reason in `T.BAD` on `T.BODY` | After `T.NOTE_HOLD` (2.4 s, the toast's time) or at the next intent |
| `result` | The `tally` step of a Play sequence | `PreviewPanel`'s sum, verdict and **outcome lines** (R7) | The next `zoom_out`, or it gives way to `upgrade` |
| `upgrade` | `phase == "upgrade"` | `XpPurse` with its recap | `zoom_out` at Cleanup |
| `soak` | `vs.soak != null` | `SoakMeter` | The soak resolves |

**Precedence**: if several apply, `refusal` > `mode` > `result` > `soak` > `upgrade` > `setup`. A refusal shows over a persistent note and then returns to it.

**How it lands**:
- It is laid on the stack from the column's right edge, sliding in and settling, over `T.BASE`, and taken off the same way.
- In reduced motion it fades.
- `view_state.note_for(vs)` derives the persistent kinds. The animator adds `result` at `tally`, and `play_screen` adds `refusal`.

**Pressing and holding a note** lifts it aside (it slides partly off, at 0.25 alpha) for as long as the press lasts, so the card beneath can be checked (for example, the Enemy's figures while Diverting). No helper text announces this (FR-006).

**Rationale**:
- The user's answer: the feedback replaces the card temporarily and gets more room.
- Showing it as one more card on the stack keeps the left side "all cards".

**Alternatives considered**:
- Replacing the face node with the old box: this looks like a panel rather than a card, and loses the stack's edges.
- A transient banner: rejected in the clarification.

## R7. More room for the result: outcome lines

**Decision**: `PreviewPanel` gains a roomy layout, used when it sits in a note at least `T.NOTE_ROOMY_H` (360) tall. That is every shape, because the note is the face's height. In the roomy layout:

- The verdict is a headline (`T.SUBHEAD`) with its icon.
- The sum rows are unchanged.
- The one-line outcome row of pills becomes **outcome lines**, one per reward or cost. Each line has its pill's icon and figure, then the sentence its help already carries (for example, "Early Damage 4: Ambush doubled the Enemy's Early Damage of 2"). The pill help texts already name the engine's terms (`_pill(... help_id)`), so the sentences come from the same source.

**Rationale**: The user wants the result text to "appear and explain the outcome of the encounter".

**Alternatives considered**: New prose built in the UI. It would duplicate the engine's terms and could drift from the rules.

## R8. Removing the card codes and the tips

**Decisions**:
- **Card codes**:
  - `region_card_model` keeps a `pair` field (the code's value), used only by `turn_to` to tell a turn of the same card from a swap. It loses `code`, and nothing renders `pair`.
  - `dragon_card_model` drops `code`.
  - `ui_check` scans every visible `Label` on the play screen, in every state it visits, for the pattern `DOE-` (SC-002).
- **Tips**:
  - `view_state` removes `TIP_SWAP`, `TIP_AIM` and `TIP_REAIM`, and `_prompt` returns an empty `text` while an Action Set is being built.
  - `PreviewPanel` no longer renders a tip, and its "Hold a card to see its other Levels." line moves into the `setup` note.
  - `test_view_state`'s tip assertions become assertions that no tip is produced.

## R9. Fitting the whole card at the narrowest column

**Decision**: The whole card is fitted to the face rect's width, which is the binding side in a portrait column. At `LEFT_MIN_W` = 400 the face rect is 376 wide, so the card is 376 × 526, and:

- An Enemy panel is about 167 × 115, and its badge column holds four badges of about 26 each.
- A Journey panel is about 92 × 158, with a header strip of about 40.

`StatChip` numerals at those sizes come out at about 22–24.

`ui_check` asserts that every `StatChip` numeral and the number marker are at least `T.TEXT_MIN` on the whole card at every `MATRIX` shape (SC-006). There is more height than the card needs, so the space above the card is the Key Card's peek room, and 012's dip still applies.

**Fallback if a shape fails**:
1. First, the Deck's edge margin on that shape drops from 24 to 16 (as in 012's risk).
2. Then the card may run into the peek room, with the peek rising over the card's title band instead of above it.

## R10. The Dragon Card in the printed layout

**Decision**: `DragonCard` is redrawn to the printed Dragon Card (`o5.png`, Grimroch and Vuurhast), with no card code:

- A title band with the name and title.
- A centred row of stat badges: Initiative, Early Damage, Armor (as `dragon_stats` lists them).
- The MP Tiers down the left (MP badge + hourglass per tier).
- The HP Tiers down the right (heart + Attack per tier).
- All over the dragon's art.

`target_rect("mp" | "hp")` returns the tier columns' printed rects.

**Landing**: The zoom lands on today's `dragon_face`, as 012 decided (spec FR-012 keeps that). FR-008's "no restyled face" applies to Region panels. The dragon face is the ladder the Final Battle is played on, with the tier lighting at Play.

**Rationale**: It is P3 in the spec and keeps the stack faithful through the end. Changing the Final Battle's face is out of scope.

## R11. Tests and tools

- **`tests/test_region_card.gd`** (rewritten):
  - `LAYOUT` rects: inside the card, non-overlapping, in printed order.
  - `panel_rect(key)` for all 8 keys.
  - The model carries every stat and XP, and has no `code`.
- **`tests/test_region_panel.gd`** (new):
  - Part rects scale linearly with size.
  - An Enemy shows 4 badge rows (Armor ×2 side by side).
  - A Journey shows MP and Time.
  - Discs appear only for non-null effects.
- **`tests/test_deck_stack.gd`**:
  - `panel_fit` (the panel rect for a face rect and an aspect) and the reading strip rect.
  - `zoom_scale` and `pivot` for an Enemy and a Journey.
  - Note precedence.
- **`tests/test_layout_solver.gd`**: one left region covering the column, for every `MATRIX` shape. No `preview` region.
- **`tests/test_view_state.gd`**:
  - No tip text while building.
  - `note_for`: setup, mode, upgrade and soak.
  - Panel models.
- **`tools/ui_check.gd`**:
  - No `DOE-` label anywhere.
  - Whole-card numerals ≥ 22.
  - The left column holds only the deck region.
  - Each note kind fits its rect with text ≥ 22 and no clipping.
  - The landed panel equals the card's panel rect at the end of the zoom (no jump).
- **`tools/space_audit.gd`**: measures the `result` note instead of the preview zone.
- **`tools/design_shots.gd`**:
  - `deck` shots: the whole card, an Enemy and a Journey landed, each note kind, and the Dragon Card.
  - A `scan` shot that overlays `o5.png` at 50% on the whole Jade Mountains card, to tune `LAYOUT` (SC-001).

## R12. Documents

- **README**: the play-screen description.
- **`specs/012-deck-region-card/contracts/deck-stack.md`**: a "superseded in part by 013" note on its tiles, band and per-phase face table.
- **`specs/011-card-contribution-highlights/contracts/left-box.md`**: a superseded note; the box is gone.

---

## Implementation notes (2026-10-18)

Where the build departed from the decisions above, and why:

- **R3, the landed face.** A lone panel left a landscape Enemy sitting on half an empty portrait column (`ui_check`'s space check failed at 40–50% empty). The zoom now ends on **the whole card, redrawn at the zoomed size and clipped to the face**:
  - The panel is lit, and the rest of the card is dimmed round it (`RegionCard.set_focus`).
  - The card grows by being laid out afresh each frame, not scaled, so it stays sharp. The landed face is a second `RegionCard` at the same rect, so nothing jumps.
  - `DeckStack.landing()` places it. Where the card is larger than the room, it is moved so no bare face shows.
- **R4, the strip.** The reading strip lies along the face's foot, on a dark band over the card, rather than under a free-standing panel.
- **R6, combined notes.** A Play's result and the step after it share one note: the result first, then the Soak meter or the XP purse (whose recap is dropped as repeated). The result is rebuilt from the state it was played in whenever the note is redrawn. It is also laid on the Deck when the sequence is skipped before its tally. When the roomy lines would overflow the note, it falls back to the one-row outcome.
- **R9.** Whole-card numerals cannot reach `T.TEXT_MIN`, as tasks.md Notes record. The whole card is a picture, read by zooming in.
- **R10, the dragon's art.** On the Dragon Card the whole dragon is drawn as wide as the card and placed by its head region (`Art.head`). The head sits between the two ladders under the row of figures, and the body runs off the left, so no figure covers its face (owner's request). In the Final Battle's face (`dragon_face.gd`), the Final Enemy now shows the whole dragon, not its head, standing under the ladder as large as the room allows (owner's request).
