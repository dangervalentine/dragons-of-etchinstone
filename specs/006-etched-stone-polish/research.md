# Research: Etched Stone and Ether Rifts

All open questions from the assessment and spec are resolved below. Nothing is left
as NEEDS CLARIFICATION.

## D1. What replaces the slot band

**What the band does today** (`ui/widgets/slot_row.gd`, `layout_solver.gd`):
- Three large buttons per Action Set, Spell, Element and Boost. Each shows the
  role name and the placed card's *name* and contribution.
- A tap on a filled slot takes the card back; a tap on an empty one selects the
  slot the next card fills.
- The gold-ringed slot is the one being filled next.
- A Boost-to toggle (Attack or Initiative) sits at the end.
- After a battle it becomes a recap of the cards played and the Reserve.
- Its height is 112 design units (96 per row with two sets) plus up to 80 more taken
  from spare height. In `05_challenge_assigned.png` it is about a quarter of the
  right column.
- The placed card is *also* shown in the Hand: lifted by `CARD_LIFT`, with a role
  ribbon from `card_view.gd`. The preview panel lists the roles "Still needed".

**Decision**: a **role rail**. It is one row, exactly `TAP_MIN` (88) tall, with one
token per role per set and the Boost-to toggle at the end.
- Tokens have a fixed width (about 132 units with one set, `TAP_MIN` square with
  two) and are centred over the Hand, not stretched across it.
- A token shows the role icon. When filled, it adds the contribution in numerals
  (for example `3 / 8🔥`, `⚡ 5`, `+2`), tinted by the card's Ether.
- The card name is dropped: the lifted, ribboned card directly below already says
  which card it is.
- The active token wears the focus rim, as today.
- Taps keep today's meaning: on an empty token, select that slot; on a filled one,
  take the card back.
- After a battle the rail shows the recap in the same tokens: role icon, a struck
  "discarded" mark, and the Reserve token in gold if kept.
  - The played cards are still in the Hand during the recap (Penalty and Upgrade
    phases), but today they lose their role ribbons there. So the recap would be
    the only role-to-card link, which a tooltip can't carry on a phone.
  - Fix: while `vs.played` is set, Hand cards that were played wear a **"played as"
    ribbon** (role icon, muted), the same ribbon `card_view.gd` draws while building.
  - A tap on a recap token opens that card's inspect view (`inspect {id}`).
  - The name stays out of the token, and the link stays visible (FR-002, FR-020).

**Measured today** (solver run over the matrix, 2026-10-15):

| Window | Sets | Band (w × h) | Card |
|---|---|---|---|
| phone-16x9 1280 × 720 | 1 | 824 × 154 | 197 × 275 |
| phone-16x9 | 2 | 824 × 96 | 137 × 191 (2 rows) |
| desktop 1280 × 800, tablet 1280 × 960 | 1 | 824 × 192 | 197 × 275 |
| phone-tall 1558 × 720 | 1 | 917 × 126 | 220 × 308 |
| desktop-ultrawide | 2 | 1188 × 171 | 161 × 225 |

**Rationale**:
- With one set at 1280 × 720, the rail is about 4 × 132 + 3 × 8 = 552 × 88 against
  the band's 824 × 154. That is a 62% cut in area, which meets SC-001 (≥ 50%).
  Height alone falls 43%; the fixed-width tokens make the rest.
- Taps, the active slot, the Boost toggle and the recap all keep a home, so
  FR-003, FR-004 and FR-020 hold.
- The tokens stay directly above the cards they describe, so the eye moves token
  → card, short and vertical.

**Final Battle**:
- Six tokens plus up to two toggles, 88 square. At the minimum right-column width
  (824) that is 6 × 88 + 2 × 88 + 7 gaps × 8 = 760 × 88. It fits in one row.
- Tokens show the set number as a small pip, as `slot_row` does today.
- Today's two-set band is already compact (824 × 96), so the cut here is small,
  about 15% by area. That still meets US1 scenario 6 ("more compactly than today").
  SC-001 is measured on the one-set state, where the band is largest.

**Alternatives considered**:
- *Move the roles into the preview panel's empty lower half.* It kills two problems
  at once, but puts the role display a column away from the cards. With six Final
  Battle tokens it needs two rows in a 400-wide column, and the Soak and Upgrade
  states have no roles to show there. Rejected.
- *Drop the role display entirely and rely on the Hand ribbons.* That loses
  slot selection (choosing which role the next card fills) and the Boost-to
  toggle's natural home. Rejected (FR-003, FR-004).
- *Keep the band, but shorter.* At 88 tall the name *and* contribution do not fit
  legibly at 22 units; a name-less band is the rail.

## D2. Where the freed height goes, and the empty preview

**Finding**: Hand cards are bound by *width*, not height, at every matrix size except
the two-row Final Battle Hand. At 1280 × 720 the right column (824) fits four cards
of 197. So the height the rail frees cannot make one-set Hand cards larger without
taking width from the left column, which is already at its 400 minimum.

**Decision**:
- **Right column.** The freed height (about 66 units at 1280 × 720, about 104 at
  1280 × 800) becomes the Hand's well: deliberate breathing room above and below
  the cards, the deepest place cut into the stone, and the room placed cards rise
  into. This is FR-005's "deliberate breathing room".
- **Two-row Final Battle Hand.** Its cards are height-bound (137 × 191 at
  1280 × 720), so they gain the freed height directly. That is only 8 units
  (band 96 → rail 88), so the growth is slight.
- **Left column, content-driven.** `preview_panel.gd`, `soak_meter` and `xp_purse`
  report a `needed_height` for the current state. The solver takes
  `preview_h = clamp(needed, PREVIEW_MIN, body_h × 0.5)`, and the Encounter gets the
  rest: a larger creature, and more of the stone-and-rift look where the light
  comes from.
- **Stable within an Encounter.** The needed height is that of the panel's *fullest*
  composition for the current Encounter kind and phase, not the current state. For
  example, an Enemy preview is sized for both comparisons plus the verdict even while
  "Still needed" shows. The Encounter frame then doesn't resize as cards are placed;
  it changes only between phases (challenge → Soak → Upgrade) and Encounters, which
  are already visible transitions.
- The solver stays pure. `needed_height` is an input, like `hand_count`.

**Rationale**:
- In `05_challenge_assigned` and `20_region_banner` the preview's lower 35–45% is
  empty while the creature is cramped.
- A content-driven split removes that space (FR-005, SC-002) without inventing
  filler.
- A Hand well with designed margins is the stone look's centrepiece, not dead space.

**Alternatives**:
- *Fixed ratio tuned once (0.62 / 0.38).* Rejected. The states differ too much
  (one-line "Still needed" against Final Battle tiers against Soak).
- *Narrow the left column so one-set cards widen.* Rejected. The left column is at
  its 400 minimum for preview legibility, and gaining 10–15 units of card width is
  not worth the risk.

## D3. Making stone without art

**Decision**: procedural, baked once at startup.
- **Stone grain**: a `NoiseTexture2D` (`FastNoiseLite`, simplex fractal, 3
  octaves, seamless, 512²), remapped into a narrow luminance band around
  `BG_SURFACE` (D5).
- **Crack map**: a second `NoiseTexture2D` using cellular noise with
  `DISTANCE2_SUB` return (F2 − F1). Its thin dark valleys read as branching cracks
  through stone. Seamless, 512².
- Both are generated once on a thread at boot. They are shared by every
  `StoneStyle` and the backdrop, so the per-frame cost is texture lookups only.

**Fallback**: if the owner finds procedural stone cheap-looking at the style frame,
the same two slots take bitmap textures generated on the Windows PC (ComfyUI;
`tools/generate_art.py`), handed off as a command per the project's art rule. Nothing
else changes.

**Alternatives**:
- *Full-screen fbm in the backdrop shader every frame.* Too costly on the web build
  for no visual gain over a baked map.
- *Shipped bitmaps from the start.* Adds the hand-off before the direction is even
  approved.

## D4. Zones as places cut into the stone

**Decision**: `ui/theme/stone_style.gd`, a `StyleBox` subclass overriding `_draw`:
- a chamfered outline (cut corners, not rounded): the woodcut "gouge" corner;
- a stone fill from the shared grain texture, offset per zone so neighbours do not
  repeat;
- an **inner bevel**: a light edge on the bottom and right and a shadow edge on the
  top and left, so the zone reads as *recessed* (cut in), not raised;
- an optional **rim glow** (focus or Ether) for the active zone, animated by a
  single `glow` property that tweens.

It is drop-in: `UI.box`, `UI.panel` and `UI.raised_panel_box` return a `StoneStyle`
with the matching role ("well" for zones, "plinth" for buttons, "slab" for overlays,
"inset" for small chips).

**Zone weight (FR-008)**:
- **Depth**: active zones are cut deeper (stronger bevel, darker floor) and lit at
  the rim.
- **Brightness**: resting zones are shallower and quieter.
- **Floor**: the Hand's well and the Encounter's frame are the two deepest places,
  and the header is a shallow band.

**Rationale**: one style object covers the 46 call sites in about 20 files with no
per-widget drawing. Chamfers plus the inner bevel are what read as "cut into stone",
as opposed to the rounded, shadowed "lifted panel" of today.

**Alternatives**:
- `StyleBoxTexture` nine-patches: cheap, but they cannot vary bevel depth and glow
  per state without many textures.
- A shader per panel: more GPU work and more material instances.

## D5. Contrast on a textured surface

**Decision**:
- Stone luminance is remapped so its brightest texel is no lighter than
  `BG_RAISED` (#2b2640), the lightest panel colour today.
- Seam glow is capped where text can sit. The rift light shows in the *backdrop*
  between zones and at zone rims, never under a zone's text.
- `tests/test_stone_contrast.gd` checks every text colour in `tokens.gd`, plus
  `ether_ink` per Ether, against:
  - the brightest grain texel plus maximum rim glow, for ≥ 4.5:1 (≥ 3:1 for
    numerals ≥ 32 units);
  - the darkest grain texel, for ≥ 4.5:1.

**Rationale**: today's contrast holds because the panels are uniform. Checking the
texture's extremes keeps FR-017 testable rather than judged by eye.

## D6. Rift light

**Decision**: the rewritten `backdrop.gdshader` composes:

1. **Grain**: stone grain at base luminance, with a vignette as today.
2. **Seams**: crack map → seam mask → `seam_colour × intensity`.
   - `seam_colour` is the Ether's `lit` shade (`tokens.ether_shade`), or a neutral
     cold violet.
   - `intensity` is a slow per-seam shimmer: two sines on the crack map's cell id.
     It is constant under reduced motion.
3. **Rift bloom**: a broad, soft glow from one "rift" point per screen (the
   Encounter frame on the play screen, the dragon tiles on the title). The light
   seems to come from the thing you face.
4. **Dark zones**: zone rectangles are passed as a uniform array (≤ 8). Seams fade
   out under zones, so light never sits behind text.

**Mood per Ether (FR-010)**: the tint, plus one behaviour per Ether.
- Fire: warmer, faster flicker.
- Water: slow swell.
- Lightning: rare brighter jolts.
- Shadow: dim, with faint pinpricks.

These are written as small branches on `ether_id`, the same vocabulary as
`ether_card.gdshader` and the 005 clarification (faint and slow, not a visualizer).

**Transitions**: a change of Ether tweens `tint` over `T.REVEAL` (0.4 s). There is
no snap (edge case).

## D7. Ambient life and its budget

**Decision**:
- **Seam shimmer**: in the shader, with no node cost.
- **Motes**: one `CPUParticles2D` in a new `rift_layer.gd` above the backdrop and
  below screens. It emits from the rift point with a lifetime of 4–7 s and at most
  24 alive, tinted to the Ether, and drifts up and out. `CPUParticles2D` rather than
  `GPUParticles2D` because the Compatibility renderer and web are the weak targets.
- **Active zone**: the zone named by `vs.input_region` (extended in D9 to name
  preview, hand or commit) has its `StoneStyle.glow` tweened to 1 and
  the others to 0 over `T.BASE`. It breathes slowly (±15%) while waiting.
- **Budget**: ≤ 1 ms GPU for the backdrop, seams and motes at 1280 × 720, measured
  by the extended `tools/field_bench.gd` against 005's PASS thresholds. If it fails,
  drop in this order: motes to 12, then Ether behaviours to the plain shimmer.
- **Reduced motion**: no motes, the shimmer frozen at its mean, glow set instantly
  and no breathing.
- **Busy moments**: during an animator sequence, motes pause emission, and the
  shimmer keeps going at half amplitude so it does not compete (edge case).

## D8. A response for every action

**Decision**: `ui/model/board_response.gd` is a pure table from game and draft events
to a board response. `animator.gd` and `play_screen.gd` call it, and `rift_layer.gd`
and the active `StoneStyle` play the result.

| Event | Board response |
|---|---|
| Place card | Its rail token flares in the card's Ether; the Hand well's rim brightens briefly |
| Take back | Token dims to empty with a short fall |
| Fuse | Seams near the Hand flare in the fused Ether |
| Divert / Regroup | A cold sweep along the header band |
| Play | Seams surge toward the Encounter frame (the rift answers) |
| Damage dealt to enemy | Encounter frame shudders; dust motes burst at it |
| Damage taken / Soak | A crack flash across the Hand well; brief red in the seams |
| Upgrade | The upgraded card's well rim glows gold; a short rise of motes |
| Encounter won | Seams brighten all over, then settle; the rift tint fades toward neutral |
| Encounter lost / time lost | Seams dim and redden briefly |

Each response has a still form under reduced motion: a held tint or rim for
`T.BASE`, with no movement. `tests/test_board_responses.gd` checks that every event
the animator emits maps to a response with both forms (FR-015, FR-016).

## D9. Which zone is "active"

**Decision**: `view_state._input_region` already returns `hand` or `commit`. Extend
it to return `preview` in Soak and Upgrade, where the decision is read off the meter
or purse. Do **not** add a `rail` zone. The player's input is always a Hand card or
the commit control, and the rail is only where an optional choice lives: picking a
role out of order, or the Boost-to toggle, which defaults to Attack
(`turn_draft.gd`), so it is never "pending". The rail's next token already carries
the focus rim. It stays a pure function of game, draft and view state,
and is tested in `test_view_state.gd`.

## D10. Woodcut ornament and lettering

**Decision**:
- `tools/gen_icons.py` gains about 8 ornament SVGs:
  - gouged horizontal divider;
  - corner cut;
  - heading flourish left and right;
  - a rift glyph;
  - a Tower glyph;
  - a seal for the proclamation;
  - a scroll end.
- They are drawn as flat shapes with carved negative space, like the creature
  silhouettes.
- Headings stay in Cinzel. Display headings gain a *carved* treatment: a 1-unit dark
  offset above and a light offset below (an incised look), in `theme.gd`.

**Alternative**: a new display font. Rejected as unnecessary. Cinzel is already
lapidary (inscriptional) and the spec asks for no new fonts.

## D11. Lore framing per screen

**Decision**:

| Screen | Framing |
|---|---|
| Title | The Tear: a tall rift seam behind the dragon tiles, as the bloom source; the game title carved into a lintel |
| Rules setup | The elders' proclamation: a slab headed with the Tower glyph and "By order of the Tower", the options as carved lines, a seal over Continue |
| Region banner | A carved lintel across the screen, with the rift tint changing beneath it |
| Final Battle | The play screen; the dragon's Ether lights the rift |
| Ending | An inscribed slab: victory carves the verdict and lights the seams gold; a loss dims and cracks them |
| Rulebook, glossary | Scrolls: slab body with scroll ends, for the book-like reading surfaces |
| Inspect, menu, confirm, size notice | Slabs |

Every existing choice, value and control stays (FR-020); the framing is around the
content, not instead of it.

## D12. Measuring space

**Decision**: `tools/space_audit.gd` drives the same seeded states as `shot.gd` at
`phone-16x9` (1280 × 720) and records:

- **SC-001**: the role display's area as a share of the content rect. It is compared
  with a baseline recorded from the current build before stage 1 and written to
  `specs/006-etched-stone-polish/baseline.md`.
- **SC-002**: for each zone, the empty fraction: panel area minus the union of its
  visible children's rects, over panel area. It fails if any zone is over 1/3 empty.
  - **A zone is the panel drawn on screen**, not the solver's region. The Hand zone
    is `_hand_panel`'s rect (the cards' bounds plus margins), not `regions.hand`.
    The Hand region is deliberately taller than its cards (D2), and the stone
    between panels is background.
  - **It is judged at the minimum sizes** (`phone-16x9`, `phone-small`), where SC-002
    applies. Larger windows add stone around the panels by design.

It runs headless and is not part of `tools/test.sh`, because the baseline comparison
is a one-time judgement. The SC-002 check *is* added to `ui_check.gd` as a
non-regression, at the two minimum sizes only.
