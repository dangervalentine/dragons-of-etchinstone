# Research: Playing Field and Card Polish

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Date**: 2026-10-14

Sources: the official card scans (`reference/sheets-official/o1a`–`o6`), current
screenshots from `tools/shot.gd` at `phone-16x9`, and the code under `ui/`.

## What the official card looks like

Read from the scans, top to bottom (one Level of a printed card):

| Part | Official rendering | Ours today |
|---|---|---|
| Frame | Near-black card with rounded corners; no coloured border | Rounded rect with a 2 px Ether-coloured border |
| Top band | Black band: white crown with the Level number, a small Ether pip, the name in serif capitals | Gold crown, name, no pip |
| Key Card strip | Bronze/brown band with a pointed tab at the left edge: Encounter icon and number, Hardship icon; on the right the Upgrade cost beside a starburst XP icon and a thin rule running to the edge. Ragged (torn) edges where the bands meet the field | Plain dark strip |
| Ether field | Saturated Ether colour with a labyrinth/fingerprint line texture, darker centre, illustration | Concentric swirl shader, faint generic sigil in a ticked ring |
| Stat column | Hangs off a vertical sword: Initiative in a black pennant crest at the top; the action plates sit at the crossguard; Boost a black square plate on the blade; Armor a shield crest at the foot, filled with the Armor Ether when it has one, with an Ether pip | Same order, but free-floating rounded rectangles, no spine |
| Action plates | Black octagonal plates, white numeral and action icon; a small arrow links basic to enhanced; enhanced plate filled with its Ether colour, Ether pip at the corner | Rounded rectangles, enhanced filled |
| Ether symbols | Fire: a slim flame leaning right with a curl. Lightning: a sharp zig-zag bolt. Shadow: a four-point sparkle star. Water: a plain droplet | Fire: a drop with a notch. Lightning: bolt in a circle. Shadow: crescent. Water: droplet |
| Ether colours | Fire deep red, Lightning orange-gold, Shadow royal purple, Water royal blue; all much more saturated than ours | Muted versions of the same hues |

## Decisions

### D1. The card face stays procedural, drawn by `card_face.gd` plus one field shader

- **Decision**: Rebuild `ui/widgets/card_face.gd` as a layered procedural drawing
  (frame → bands → field shader → spine → crests and plates → ink → emphasis) and
  replace `ether_field.gdshader` with a per-Ether field shader. No bitmap card
  frames.
- **Rationale**: Faces are drawn at every size from 120 to 440 units tall (Hand,
  slots, detail, inspect, rulebook figures). Procedural drawing stays sharp at all
  of them, keeps the "no scanned artwork ships" rule from feature 001, and lets
  emphasis restyle any region per frame.
- **Alternatives**: 9-slice bitmap frames (blur at small sizes, can't restyle
  regions); a SubViewport per card (expensive on the web build, nothing gained).

### D2. Depth comes from three cheap tricks used consistently

- **Decision**: Every raised piece (plate, crest, band, card) is drawn as
  shadow → body → top-edge highlight → bottom-edge shade, from one helper
  (`_raised(rect, shape, fill)`), lit from the top. The card casts a soft drop
  shadow; plates cast a tight one onto the field. Ragged band edges are a
  deterministic jagged polyline seeded by card id, so a card always tears the same
  way.
- **Rationale**: Matches the printed card's embossed look with no textures and a
  handful of draw calls; one helper keeps the light direction consistent (FR-003).
- **Alternatives**: Normal-mapped shader lighting (needs textures, overkill at Hand
  size).

### D3. Stat column follows the official sword spine at every size

- **Decision**: Draw the sword (blade, crossguard at the action plates, pommel at the
  Armor crest) as a thin bevelled line behind the stat column. Initiative becomes a
  pennant crest, Armor a shield crest; action plates become octagons; a small arrow
  links basic to enhanced; Boost is a square plate on the blade.
- **Rationale**: The spine is what makes the column read as the official card, and
  it costs no space: the column already sits where the blade goes. At Hand size
  (≈ 190 × 266) the blade is 3 units wide, which stays visible.
- **Alternatives**: Leave the spine out below a size threshold: it would make Hand
  cards look different from the inspect view.

### D4. A foil field per Ether: one shader, four etchings, one slow sheen

- **Decision**: `ui/fx/shaders/ether_card.gdshader` with an `ether` int uniform
  (0 fire, 1 water, 2 lightning, 3 shadow). The field is a rich Ether gradient
  etched with fine lines, as on the printed cards; each Ether has its own etching
  (Fire rises from a glowing base into tongues of flame, Water runs in long waves, Lightning breaks into zig-zags with
  a bolt, Shadow coils under faint four-point stars) that drifts almost
  imperceptibly. The motion is a holographic sheen: a broad, faint band of
  iridescent colour that crosses the card in about half a minute and is strongest on
  the etched lines, plus a few slow foil glints. A `motion` uniform (0 or 1)
  multiplies time; with reduced motion the sheen rests across the upper left like a
  card tilted to a lamp (FR-008). A `phase` uniform hashed from the card id keeps
  cards from catching the light together.
- **Rationale**: The user asked for "faint, slow, like premium trading cards, not
  like a visualizer, holographic effects" after a first pass with flickering
  embers, flashing arcs and ripples proved distracting. Character now lives in the
  still etching, which is also what lets the four Ethers be told apart in greyscale
  (SC-008); motion is shared and quiet.
- **Alternatives**: The first pass (per-Ether animation: rising embers, forked arc
  flashes every 2 s, ripples, swirling sparkles), rejected as too busy; particles
  or sprite sheets (cost, new art).

### D5. Official Ether symbols, redrawn in `tools/gen_icons.py`

- **Decision**: Replace the `fire`, `lightning`, `shadow` paths (and refine `water`)
  in `tools/gen_icons.py` with the official silhouettes: leaning flame with curl,
  zig-zag bolt, four-point sparkle, droplet. `sigil_<ether>` becomes the same shape
  large, with an inner etched line and a soft outer flare, without the generic ticked
  ring. Icons regenerate as today.
- **Rationale**: The icons appear everywhere (cards, slots, Encounter faces, dragon
  stats, rulebook), so changing them at the source keeps one vocabulary (FR-005).
- **Alternatives**: Separate "card-only" sigils (two vocabularies for one concept).

### D6. Saturated Ether palette with derived shades

- **Decision**: Move `T.ETHER` toward the printed hues (fire ≈ `#c8261d`, lightning
  ≈ `#e99a1c`, shadow ≈ `#6b34c0`, water ≈ `#1f5fd0`, exact values tuned against the
  contrast test) and add `T.ether_shade(e, role)` for `deep` (field centre), `lit`
  (highlights, glow) and `plate` (enhanced plate fill), all derived from the base.
- **Rationale**: Flat colour was one of the user's three complaints; one source with
  derived shades keeps every place consistent. Ink on enhanced plates switches
  between dark and light by computed contrast, so the brighter lightning plate stays
  legible.
- **Alternatives**: Hand-picked colours per use (drifts quickly).

### D7. Step emphasis is a pure model field, drawn by the face

- **Decision**: `ViewState._card()` adds `focus: {regions, mark, changed}` to every
  card model; a new pure helper `ui/model/emphasis.gd` decides it from the phase, the
  draft mode, the next empty slot and the engine's level data. `card_face.gd` takes
  it and draws emphasised regions lifted (raised, focus-coloured rim, full ink) and
  the others quietened (plates desaturated toward the band colour, ink to
  `INK_MUTED`, field dimmed 25 %). Unavailable cards keep the existing greyscale
  `dim` plus their reason tag, which is a whole-card treatment and visibly different
  (FR-016).
- **Rationale**: Pure and testable like the rest of `ui/model/`; the face stays a
  dumb renderer. Quietening by colour, not by alpha, keeps every value above the
  contrast floor (FR-011, FR-026).
- **Which action is "in effect"** for a placed Spell: `Rules.action(spell, element,
  kinds)` with the set's Element (or none yet). When no Element is placed, both
  plates stay emphasised. **When a Reserve's Boost counts** on a journey: when the
  Spell's action is enhanced and its Ether matches the journey's MP Ether, mirroring
  `Rules.resolve_journey`; checked against the engine in a test, like
  `_would_knock_out`.
- **Alternatives**: Deciding emphasis inside `card_view.gd` (not testable without a
  display; duplicates rules knowledge).

### D8. Layout: more air from a quieter header and tighter fixed parts, not smaller cards

- **Decision**: In `layout_solver.gd`: `GAP` 8 → 12, `COLUMN_GAP` 16 → 24, header
  56 → 48 with smaller, muted pile counts; the slot row's spare-height growth is
  capped at +40 so the Hand keeps the height; Hand card gaps 12–36; the left column
  narrows from 0.335 to 0.32 of the width (minimum 400) to pay for the wider gaps,
  which keeps four Hand cards at 197 units wide on `phone-16x9`, as today. A new test pins each matrix size's Hand card width at no less
  than today's value (recorded in the test). Each frame the view state names the
  `input_region` (hand, slots or commit); `play_screen.gd` raises that panel (lighter
  surface, focus rim) and lowers the others (no rim, darker surface).
- **Rationale**: The current screenshot shows the Hand cards touching their
  neighbours and the slot row as tall as needed; the header is the loudest gold text
  on screen but the least used. Pinning card width in a test keeps FR-018.
- **Alternatives**: Collapsing the preview into the Encounter panel (bigger change to
  a layout the rulebook already explains with figures).

### D9. Performance budget for living fields

- **Decision**: Budget ≤ 1.5 ms GPU for all card fields at 1280 × 720 on a mid-range
  phone; at most 2 noise octaves per Ether; fields of cards that are fully covered
  (under an overlay) set `motion` to 0 and skip redraws. `tools/field_bench.gd`
  draws 11 animated faces (7-card offer + 3 slots + detail) and reports average and
  worst frame time over 10 s, run on desktop and on the web build in a phone browser.
- **Rationale**: SC-007 asks for no visible stutter; the web build on the
  Compatibility renderer is the weak target.
- **Alternatives**: Animate only the hovered card (the user asked for the Ethers to
  feel alive in the Hand).

### D10. The inspect overlay shows every Level

- **Decision**: `inspect_overlay.gd` shows all of a card's Levels (1 to max, up to
  four) in a row, each a full face at the same size, the current one raised with a
  focus rim and "CURRENT". Captions: the Level below the current one "If
  Downgraded" (or a "Trashed if Downgraded" note under Level 1 when it is current),
  the next one "If Upgraded · N XP", others plain "Level N". Changed figures on the
  neighbouring Levels are ringed as today.
- **Rationale**: FR-004 and the clarification (each Level is its own card). Four
  faces at 1280 × 720 are about 280 × 392 each, larger than today's side cards.
- **Alternatives**: Swipe through Levels (hides the comparison).
