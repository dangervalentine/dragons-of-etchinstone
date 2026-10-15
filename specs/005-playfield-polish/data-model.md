# Data Model: Playing Field and Card Polish

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Date**: 2026-10-14

No game data changes. `engine/` and `data/cards.json` are untouched (FR-028). This
feature adds presentation fields to the pure UI model (`ui/model/view_state.gd`),
one new pure module (`ui/model/emphasis.gd`), and theme values
(`ui/theme/tokens.gd`). Nothing new is persisted; the motion preference already in
`Settings` drives the living fields.

```text
engine (frozen) ──read──▶ ViewState ──uses──▶ Emphasis (pure)
                              │
                              ▼
            card model { …existing…, focus }   vs { …existing…, input_region }
                              │
                              ▼
            CardView ─▶ CardFace(model, focus) ─▶ EtherField shader (ether, motion, phase)
```

## Card region

The named parts of a Mage Card face. Every region has a fixed place in the face
layout ([contracts/card-face.md](contracts/card-face.md)) and can be drawn in one of
three treatments.

| Key | Part of the card |
|---|---|
| `level` | Crown and Level number |
| `name` | Ether pip and name |
| `key` | Key Card strip, left: Encounter icon and number, Hardship |
| `cost` | Key Card strip, right: Upgrade cost and XP icon |
| `initiative` | Initiative pennant crest |
| `basic` | Basic action plate |
| `enhanced` | Enhanced action plate (Ether-filled) |
| `boost` | Boost plate |
| `armor` | Armor shield crest and its Ether pip |
| `ether` | The card's Ether: the name pip, the field sigil and the field's brightness |

Treatments: **normal** (no focus active on the card), **emphasised** (in
`focus.regions`), **quietened** (a focus is active and the region is not in it).
A card whose `eligible` is false is drawn **unavailable** as a whole, regardless of
focus.

## Focus (new field on each card model)

Added by `ViewState._card()`; computed by `Emphasis.focus(...)`.

| Field | Type | Meaning |
|---|---|---|
| `regions` | Array[String] | Region keys to emphasise. Empty means no focus: the card is drawn normally |
| `mark` | String | Extra mark: `""`, `soaks_more` (Armor Ether matches the damage), `affordable`, `unaffordable`, `max_level` |
| `changed` | Array[String] | Regions an Upgrade would change (Upgrade step only); drawn with the existing "changed" ring on top of emphasis |

**Rules** (the full step table is in
[contracts/step-emphasis.md](contracts/step-emphasis.md)):

- Same input, same output; no engine state is changed.
- A card placed in a slot is focused on its role's regions regardless of the next
  empty slot.
- In the Upgrade step, `mark` is exactly one of `affordable`, `unaffordable`,
  `max_level`, or `""` for a Downgraded card (which is unavailable).
- In the Soak steps, `mark` is `soaks_more` exactly when the card model's existing
  `match` is true.

## ViewState additions

| Field | Type | Meaning |
|---|---|---|
| `cards[id].focus` | Focus | As above |
| `next_role` | String | The role of the slot the next card fills (`spell`, `element`, `boost`), or `""` when no slot is being filled. Drives the slot's focus treatment so slot and cards match (FR-015) |
| `input_region` | String | The play-screen region taking input in this step: `hand` or `commit`. The other panels recede (FR-019) |

`input_region` rules: `commit` when the primary action is enabled and no card choice
is still pending (Action Set complete with no mode active, Soak covered, setup picks
complete); otherwise `hand`. The Upgrade step is `hand` while any card is
affordable, else `commit`.

## Ether character (theme)

One entry per Ether in `ui/theme/tokens.gd`, used by the face, the field shader,
slots and the Encounter face.

| Field | Meaning |
|---|---|
| `base` | The printed hue (tuned against the contrast test) |
| `deep` | Field centre and shadows (base darkened) |
| `lit` | Highlights, glow, focus rim tint (base lightened) |
| `plate` | Enhanced action plate fill |
| `plate_ink` | `INK` or `BG_BASE`, whichever has the higher contrast on `plate` |
| `shader_id` | 0 fire, 1 water, 2 lightning, 3 shadow |
| `icon` / `sigil` | Icon names; shapes from `tools/gen_icons.py` |

## Field layer (theme)

| Layer | Treatment |
|---|---|
| Background | `backdrop.gdshader` as today, darkened at the edges, faintly tinted by the Encounter's Ether |
| Panel | Raised surface: top-lit gradient, 1-unit top highlight, soft drop shadow. `input_region` panel lighter with a focus rim; others darker, no rim |
| Card | Near-black frame with drop shadow, bevelled bands and plates (see card-face contract) |

## State transitions

Focus is recomputed with the rest of the view state after every intent. On the face,
a change in `focus` cross-fades treatments over `T.FAST` (0.15 s), or instantly with
reduced motion (FR-014, FR-027). The field shader's `motion` is 1 unless reduced
motion is on or the card is covered by an overlay.
