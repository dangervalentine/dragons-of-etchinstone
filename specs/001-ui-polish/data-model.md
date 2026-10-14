# Data Model: UI Polish and Presentation Overhaul

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Date**: 2026-10-13

This feature adds no game data. Everything here is presentation state derived from
the existing game (`engine/game.gd`) and card data (`data/cards.json`), neither of
which changes. The only thing persisted is `Settings`.

## Ownership

```text
engine (frozen)          ui/model (pure, tested headless)        ui widgets
Game  ──read──▶  ViewState ──┐
                 TurnDraft ──┼──▶ screens and widgets render these
                 StepList  ──┘        and send intents back
```

Widgets never read `Game` directly. They render a `ViewState` and a `TurnDraft` and
emit intents; the root applies an intent to the draft or the game and produces a new
view state, plus a step list when the game changed.

## ViewState

An immutable snapshot of everything a screen needs. Built by one function from a
`Game` and a `TurnDraft`.

| Field | Meaning |
|---|---|
| `phase` | Engine phase: setup, challenge, penalty, poison, upgrade, final_journey, final_enemy, final_soak, won, lost |
| `stage` | Display grouping: `region` (1 to 4) or `final_journey` / `final_enemy`, with the Region or dragon name |
| `progress` | Cards left before the Region ends, as deck size against the size needed for another Encounter |
| `piles` | Counts for deck, discard, trash |
| `zones` | Ordered card ids in deck, hand, discard, trash (used for diffing; deck order is not shown) |
| `cards` | For each card id: a `CardModel` |
| `encounter` | An `EncounterModel`, or absent outside play |
| `preview` | A `PreviewModel`, or absent |
| `prompt` | The current step's instruction and its primary action (label, enabled, reason if disabled) |
| `secondary_actions` | Fuse, Divert, Regroup, Give up Reserve: each with visible, enabled, active, remaining uses, reason if disabled |
| `soak` | In soak phases: damage owed, element, total selected so far |
| `xp` | In the upgrade phase: XP available |
| `ending` | On won / lost: score, score breakdown by Level, or cause of loss |

**Rule**: a `ViewState` built twice from the same game and draft is identical. The
sequencer depends on this.

## CardModel

One Mage Card as shown now.

| Field | Meaning |
|---|---|
| `id`, `name`, `element` | From card data |
| `level` | Current Level, 1 to 4 |
| `stats` | Initiative, basic action, enhanced action, Boost, Armor, Upgrade cost, at the current Level |
| `key` | What this card asks for as Key Card: Encounter type, index, Hardship |
| `zone` | deck, hand, discard, trash |
| `state` | One of the states below |
| `role` | When assigned: set index and role (spell, element, boost) |
| `fuse` | When fused: `top` with chosen element, or `bottom` |
| `eligible` | Whether it can be chosen in the current step |
| `reason` | Why not, when not eligible |
| `note` | Step-specific figure: Soak value, Upgrade cost |
| `selection_order` | In setup and soak: position among chosen cards |

### Card states

```text
available ─tap─▶ assigned(role) ─tap─▶ available
available ─fuse─▶ fused-top / fused-bottom ─unfuse─▶ available
available ─(all roles filled)─▶ reserve
any Hand state ─soak select─▶ selected ─confirm─▶ downgraded (this Encounter)
downgraded ─end of Encounter─▶ available
any ─not choosable in this step─▶ unavailable (with reason)
```

`downgraded` and `unavailable` can combine with a role (a Downgraded card can still
be played). The card face must show each of these without text alone (FR-012).

## EncounterModel

| Field | Meaning |
|---|---|
| `kind` | enemy, journey, final_journey, final_enemy |
| `title` | "Enemy 3", "Journey 2", or the dragon's name and title |
| `element` | Ether element that colours the face |
| `key_card` | Id of the Key Card (Region Encounters) |
| `targets` | Enemy: HP, Initiative, Attack with element, Armor entries. Journey: MP with element, time penalty. Final stages: the tier ladder |
| `reward` | XP for a win |
| `effects` | Zero or more of Hardship, Ability, Peril: each an id with a glossary entry |
| `carried_damage` | Final Enemy only |

## TurnDraft

The player's uncommitted choices. Extracted from the loose variables in today's
`ui/main.gd` (`sets`, `active`, `boost_to`, `fuse`, `fuse_pick`, `mode`,
`ranged_discard`, `picks`).

| Field | Meaning |
|---|---|
| `sets` | One or two Action Sets: role to card id |
| `active_slot` | Set index and role the next tapped card fills |
| `boost_to` | For each set: attack or initiative |
| `fuse` | Absent, or top, bottom, element |
| `mode` | none, divert, regroup, fuse_pick, fuse_element |
| `fuse_pick` | Cards picked so far in fuse_pick mode |
| `give_up_reserve` | Ranged enemies only |
| `picks` | Ordered card ids for setup and soak |

**Rules**
- A card fills at most one role across all sets; a fused-bottom card fills none.
- Filling a slot advances `active_slot` to the next empty slot.
- Any mode can be cancelled, returning to `none` without changing the game.
- The draft is reset when the game moves to a new step. It survives resizing and
  turning the device (FR-030) because it is not stored in widgets.
- The draft converts to exactly the action dictionary the engine accepts today.

## PreviewModel

The predicted result of committing the draft, shaped for display.

| Field | Meaning |
|---|---|
| `status` | `incomplete` (with the missing slots), `ready`, or `blocked` (with a reason) |
| `comparisons` | One or two of: label, player value, target value, result (complete / narrow / loss / tier reached), and for Initiative: early damage or not |
| `verdict` | complete, narrow, loss, or for the Final Battle: tier reached, survivable, or defeat |
| `rewards` | XP |
| `costs` | Each present cost as its own item: damage (with element), time penalty, poison, Reserve discarded |
| `fatal` | True when committing would end the game in a loss |
| `changed` | Which figures differ from the previous preview (drives the highlight in acceptance scenario 1.3) |

**Rule** (FR-010): every figure comes from the engine's own `preview` /
`preview_final` result. The model reshapes; it never recomputes.

## Step and StepList

A `StepList` is the ordered presentation of one change to the game. Produced by the
sequencer from (view state before, intent, engine result, view state after).

| Field | Meaning |
|---|---|
| `kind` | See the table below |
| `cards` | Card ids involved |
| `from`, `to` | Zones or regions for moves |
| `values` | Figures to show (totals, amounts, Levels before and after) |
| `anchor` | Region of the screen where feedback appears |
| `duration` | Seconds at full motion |

### Step kinds and how each is derived

| Kind | Derived from |
|---|---|
| `play_cards` | The committed draft's assigned cards |
| `tally` | The engine result's totals against the Encounter's targets |
| `verdict` | The result's outcome or tier |
| `gain_xp` | Result XP greater than zero |
| `damage` | Result damage (early and combat shown separately when both occur) |
| `pay_time` | Cards that left the deck for the discard without passing through the Hand |
| `poison_pending` | Result poison greater than zero |
| `knock_out` | Result flagged knocked out: every Hand card Downgraded, four cards from the deck |
| `downgrade` | A card whose Level fell |
| `trash` | A card that moved from the Hand to the trash |
| `upgrade` | A card whose Level rose |
| `discard` | Cards that moved from the Hand to the discard |
| `gather_shuffle` | Hand and discard both emptied into the deck |
| `draw` | Cards that moved from the deck to the Hand, in order |
| `stage_banner` | Region number changed, or phase entered the Final Battle |
| `ending` | Phase became won or lost |

**Rules**
- Applying every step of a list to the before state yields the after state exactly.
  This is tested for every action in a seeded playthrough.
- The order within a list depends on the action: a play shows the strike, tally
  and verdict first, then its consequences; ending an Encounter shows the discard,
  then a Region change (gather, banner) if there is one, then the draw, then any
  poison landing on the new Hand. `ui/model/sequencer.gd` is the reference.
- Total duration is at most 3 seconds; longer lists are compressed proportionally.
- An empty list (for example, toggling the Boost target) means the view updates in
  place with no sequence.

## LayoutPlan

Output of the layout solver for a window size and safe area.

| Field | Meaning |
|---|---|
| `scale` | Screen pixels per design unit |
| `design_size` | Width and height in design units |
| `regions` | Rectangle for each of: header, encounter, preview, slots, hand, actions, commit |
| `card_size` | Hand card width and height |
| `hand_rows` | 1 or 2 |
| `undersized` | True when the window is taller than wide or the scale is below the legibility floor; drives the turn-or-widen notice |

**Rules**
- Every region lies inside the safe area.
- Region order and relative position are the same for every phase and every window
  size (FR-001). There is one arrangement.
- `design_size` is at least 1280 x 720 and at most 1760 x 990.
- `undersized` is false for every landscape window of at least 1136 x 640 pixels.

## GlossaryEntry

| Field | Meaning |
|---|---|
| `id` | Matches an icon name, a Hardship / Ability / Peril id from card data, or a game term |
| `name` | Display name |
| `icon` | Icon to show beside it, when one exists |
| `text` | One or two sentences |

**Rule**: every Hardship, Ability and Peril id present in `data/cards.json`, and
every icon in `art/icons/`, has an entry.

## Settings (persisted)

| Field | Values | Default |
|---|---|---|
| `motion` | system, reduced, full | system |
| `last_options` | Dragon, difficulty and alternate rules of the last game started | Rodving, Normal, none |

Stored locally on the device. No game position is saved.
