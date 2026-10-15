# Concept: Board, Zone and UI Personality Polish

- **Slug**: board-ui-polish
- **Created**: 2026-10-15
- **Recommended option**: B — Etched Stone and Ether Rifts, with Option A's space work as its first slice

## Setting cues the options draw on

The rulebook's setting (`reference/rulebook.txt:39-79`) has these elements:

- **Vale** is a harsh land where "the very earth pulses with magic".
- **Ether rifts** tear open across it, and dragons come through them from the realm of
  **Etchinstone**.
- **The Tower** is home to the mages. The player is an **apprentice mage** answering an
  elders' **proclamation**.
- The physical game is **"palm-playable"**: it's played in the hand, with no table or
  playmat.

The creature art already uses a heraldic woodcut / linocut style (`art/STYLE_PROMPT.md`).
The cards already carry Ether colour fields (feature 005).

## Options

### Option A — Reclaim and Enliven (smallest thing that could work)
- **Sketch**: No new visual direction; the current dark theme stays. The work fixes
  space and stillness:
  - The "which card goes to which role" area above the Hand shrinks to what it needs.
  - Empty zones are filled or tightened, such as the lower preview panel and the band
    above the Hand.
  - The board gains light idle and feedback motion: zones answer when they become
    relevant, and the Encounter breathes.
  - The other screens get the same pass for dead space and stillness.
- **Appetite**: small (days).
- **Trade-offs**:
  - Wins: directly meets Goals 2 (space) and 3 (life), carries the lowest
    performance and layout risk, needs no new art, and is easy to judge before/after.
  - Sacrifices: Goal 1 (identity) and much of Goal 4 (coherent character). The game
    would look tidier and livelier, but still generic. That leaves the owner's main
    complaint, "generic / no identity", unsolved.
- **Rabbit holes**:
  - Reworking the slot row touches the layout solver and its 8-size matrix.
  - Motion can creep into a full animation-system rewrite.

### Option B — Etched Stone and Ether Rifts
- **Sketch**: Give the whole game one material and one light source, both taken from
  its name and lore.
  - **The material:** the world is carved, dark stone. Zones read as places cut into a
    tablet: engraved borders, recessed wells for cards, carved dividers and headings
    in the woodcut language the creatures already use.
  - **The light:** Ether. Rift light glows through cracks and seams in the stone,
    tinted by the current Encounter's Ether, so each Region and fight has its own
    colour and mood.
  - **Life:** shimmering seams, embers or motes drifting from the rift, and zones that
    light up when they become relevant.
  - **Every screen:** the title becomes the Tower or The Tear, setup reads as the
    elders' proclamation, and the ending, rulebook and overlays are stone slabs and
    scrolls in the same language.
  - **Space:** Option A's fixes are folded in as the first slice.
- **Appetite**: medium (a few weeks, as one feature branch). It's an appetite, not an
  estimate.
- **Trade-offs**:
  - Wins: meets Goal 1 with a direction that is *this* game's own: its name, its
    lore and its existing art all point here. It supports Goal 4 across every screen
    and lets Ether (already the cards' strongest feature) light the whole board.
    Original art direction, so no trade-dress issue.
  - Sacrifices: more work than A. Stone textures risk murk and lost contrast on a
    dark theme. Glow and particles add GPU cost on weak phones and the web build,
    where performance was never measured. Taste risk: the owner may not like it once
    seen.
- **Rabbit holes**:
  - Texture art: code-drawn stone may look cheap, and generated textures mean a
    Windows-PC hand-off.
  - Particles and shaders pile up on top of 005's animated card fields.
  - Restyling every overlay and screen one by one.
  - Holding contrast and text minimums on textured surfaces.

### Option C — The Apprentice's Journey (map and tome)
- **Sketch**: Frame the game as the apprentice's quest record.
  - The play screen sits on a parchment map of Vale, with the road through the four
    Regions always visible as a progress spine.
  - Zones read as pages and plates of a mage's tome: inked borders, marginalia,
    wax-seal and ribbon accents.
  - Setup is the proclamation, the ending is a page of the chronicle, and the
    rulebook is already a book.
  - Life comes from ink spreading, pages turning and the map's road advancing.
- **Appetite**: medium-to-large. It replaces the dark palette that every token and
  contrast test is built on.
- **Trade-offs**:
  - Wins: a strong, readable identity, and the journey and progress story become
    visible.
  - Sacrifices: it turns a dark game light (or sepia), which means rebuilding the
    whole colour system. The Ether-coloured card fields were tuned for dark
    surroundings and would clash with parchment. It is further from the existing
    woodcut-on-dark art. "Map of the land" overlaps with the Final Battle road that
    was just built.
- **Rabbit holes**:
  - Full palette migration and re-verifying contrast.
  - Map art for four Regions.
  - The page-turn transitions.

### Option D — Do nothing
- **Sketch**: Keep the current presentation. Finish 001/005's loose verification tasks
  instead.
- **Appetite**: none.
- **Trade-offs**: costs nothing and risks nothing. It leaves the owner dissatisfied
  with every goal in `problem.md` (see Cost of Inaction there).

### Considered and set aside: the physical game's playmat look
The original is palm-played, so a tabletop or playmat metaphor isn't even faithful to
it. Reproducing the publisher's trade dress also raises the fan-IP question in
`research.md`. Card faces already follow the official cards; going further adds risk
for little identity gain.

## Recommendation

**Option B, run in this order:**

1. **Space first.** Fix the oversized card-assignment area and the empty zones on
   the play screen. This answers the owner's one concrete complaint and is useful
   whatever the direction.
2. **A style frame.** Restyle the play screen alone in the stone-and-rift
   direction. The owner judges it against the current screenshot before the look
   spreads, which tests the taste and contrast risk early.
3. **Roll out.** Extend the look to the Final Battle, title, setup, rules, ending and
   overlays.

Why: B is the only option that meets all four of the problem's goals. Identity comes
from the game's own name, lore and art rather than a borrowed look, and it builds on
the dark palette, contrast checks and Ether system already in place, where C would
discard them. Doing A first gives a quick, visible win. The style-frame step is an
exit point: if the owner rejects the direction there, the work stops having
delivered Option A, and Option C can be tried instead.

## Out of Scope (for the recommended option)

- Rule, card-data or balance changes; new modes or content.
- Portrait orientation or new platforms.
- Music and sound effects — [still open in `problem.md`; recommend leaving out of this
  effort and assessing separately].
- A light or parchment palette (Option C territory).
- Reproducing the publisher's art or trade dress.
- Redrawing the creature and dragon silhouettes; they are reused as they are.
- Formal device benchmarking as a gate (owner chose to skip). Visible stutter on the
  web build and Android emulator still counts as a failure.

## Assumptions to Validate

- The owner likes the stone-and-rift direction when they see it. To be tested by the
  play-screen style frame before rollout.
- A stone surface can stay quiet enough that text and cards keep current contrast
  ratios and the 22-unit text minimum.
- The stone material can be made convincingly with code-drawn shaders and simple
  assets. If not, the textures have to be generated on the Windows PC, which adds a
  hand-off.
- Ambient life (glow, motes) fits next to 005's card shaders without visible stutter
  on the web build and mid-range phones.
- The card-assignment area can shrink without losing what it tells the player during
  selection, and within the seven-zone layout or a small change to it.
- One feature branch is the right size. If the rollout to every screen runs long,
  it can split into "play screen" and "everything else".
