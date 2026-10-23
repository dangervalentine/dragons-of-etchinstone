**Inkstone and brass.** The art of Dragons of Etchinstone is painted: misty jade peaks, slate-blue water, peach and rose dusk skies, characters with clean dark outlines. The interface is the table those paintings lie on: dark slate stone, carved and chamfered, lettered in warm parchment, with brass reserved for the one thing you can do next. The UI never competes with the art for colour; the Ether faces and the Encounter paintings are the brightest things on screen.

## Principles

1. **The art is the colour.** Chrome stays in low-chroma stone (`ground`, `stone`, `stone-raised`). Saturated colour belongs to card art, Ether fields and Region tints.
2. **Brass means "here".** `brass` marks the primary action, the selected thing and the slot being filled, and nothing else. Never outline a panel or a header in gold at rest.
3. **Stone is carved, paper is printed.** Interactive chrome and panels are chamfered stone slabs. Things that are physically cards (Mage, Key, Region, Encounter, Dragon) are paper with rounded corners. Text meant to be read at length (lessons, glossary, rulebook) is printed on `paper`.
4. **Every number is a figure.** All game numbers are set in the Numerals styles (Fraunces, tabular), so figures read the same on cards, in sums and on the score.
5. **Phone first.** Sizes are phone points. Nothing tappable is smaller than `touch-min`; no live text is smaller than `caption`, except `card-name`.

## Units

Every size in this system is a **phone point** (CSS px at 1×). For a Godot project with a 720px-tall base viewport stretched to a phone held in landscape (about 390pt tall), multiply by **1.85**: `body` 15pt → 28px, `touch-min` 44pt → 81px, `action-height` 48pt → 89px. Check sizes at that scale: on today's screens, card names land near 7pt and the menu button near 22pt.

## Color

- **Grounds.** Paint the screen `ground`. Panels, the tray and the top bar are `stone`; buttons and tabs are `stone-raised`; empty slots are `well` with `shadow-well`.
- **Region wash.** Over `ground`, add a large soft radial glow in the current Region's tint (`region-jade`, `region-marsh`, `region-basin`, `region-gath`, `region-lair`) at `opacity-region-wash`, centred behind the Encounter card. This replaces the purple mottled-stone texture and makes each Region feel like its painting.
- **Text.** `parchment` for all primary text on the stone grounds; `parchment-muted` for secondary text, column heads and inactive tabs; `parchment-faint` only for disabled labels. On `paper`, use `paper-ink` and `paper-muted`.
- **Brass.** `brass` fills the primary button (with `on-brass` text, never white) and draws selected and target rims. `brass-bright` is for rewards: Score, XP, 1st place, banner headlines.
- **Signals.** `jade` for good outcomes and the focus ring; `danger` for harm. Both always travel with a tick, minus sign, heart or skull, because jade and danger must never be told apart by hue alone.
- **Ethers.** The four card fields are mineral pigments that sit with the painted art: `ether-lapis` (drop), `ether-ochre` (bolt), `ether-amethyst` (spark), `ether-cinnabar` (flame). Their `-bright` partners fill the highlighted figure pill. Lapis, amethyst and cinnabar are close in lightness, so the Ether glyph on the card is mandatory, not decoration. Text on `ether-ochre` is `on-brass`.
- **Contrast.** Every text pair named in a token's note is at least 4.5:1; `edge` rims are at least 3:1 on `stone` and `ground`. `parchment-faint` is deliberately below 4.5:1 and is only for disabled labels.

## Typography

Two families, both open-source and shipped as files in `fonts/`.

- **Fraunces** (display and numerals). A soft, warm old-style serif with heavy, open figures, set with the `SOFT` axis at 50 and `WONK` at 0. Use it for `banner`, `title`, `heading`, `card-name` and all three Numerals styles. It replaces Cinzel: Cinzel's inscriptional capitals read as Roman stonecutting against an East-Asian-inflected painted landscape, and as caps-only it is the hardest text in the game to read at phone size.
- **Alegreya Sans** (everything else). Kept from the current game: humanist, calligraphic in origin, compact and very legible small. Use it for `label`, `button`, `body`, `body-sm`, `caption`.
- Titles and headings are title case, not all caps. Only `banner`, `card-name` and `label` are uppercase.
- Set figures tabular so sums align: Result rows, the leaderboard, counters.
- Keep running text to about 60 characters a line; on `paper`, 50.

## Space and layout

- Spacing is a 4pt scale: `space-1` 4 through `space-6` 32. Screen gutter is `space-4` inside the safe area; gaps between cards are `space-2`; panel padding is `space-3`/`space-4`.
- Landscape layout keeps the current structure: top bar (`topbar-height`), the Encounter or Region card on the left, the Action Set tray right, the action row along the bottom (`action-height`).
- Mage Cards in the tray are `card-width` wide at 5:7. That is the size limit for the card face: five figure rows and a two-line name at most.

## Shape, borders and depth

- **Chamfer** (`chamfer-sm`, `chamfer-md`, `chamfer-lg`): the corner cut on every stone element — buttons, tabs, panels, the tray, dialogs, banners. In Godot this is a StyleBoxFlat with `corner_radius` set to the chamfer and `corner_detail` = 1.
- **Radius** (`radius-card`, `radius-plate`, `radius-pill`): only paper things are rounded: cards, the plates on cards, and pill chips.
- **Borders are etched**: a `border-edge` (2px) rim in `edge`, plus a 1px parchment highlight at 10% just inside the top edge. Selected and target states replace the rim with `border-select` (3px) `brass`.
- **Depth is physical.** Stone slabs carry `shadow-slab` (a lit top edge, a dark bottom bevel and a 3px drop onto the table) and collapse to `shadow-slab-pressed` when tapped. Brass buttons carry `shadow-brass`. Cards cast `shadow-card` at rest and `shadow-lift` when held, dragged or inspected. No glows.

## States

- **Target**: brass rim and brass header on the one slot the next tap fills.
- **Selected**: 3px brass ring on the card or tab.
- **Pressed**: bevel collapses and the element drops 2pt.
- **Disabled**: `stone` fill, `line` rim, no bevel, `parchment-faint` label; keep the label.
- **Out of play**: greyscale at `opacity-out-of-play`.
- **Focus** (controller or keyboard): 3px `jade` rim.

## Motion

Things move like objects on a table: cards slide and settle with a short overshoot; slabs press in 80ms and release in 120ms; banners slide in over `scrim`, hold, and slide out. Never fade a card that is moving between places; move it.

## Voice

Keep the game's current voice: short, plain, second person, a little dry. "Four Regions lie between you and the dragon." "Your deck is your time." "You Have Perished." Game terms are capitalised every time (Mage Card, Region, Encounter, Action Set, Reserve, Element, Spell, Boost, Ether, Level, XP). Buttons are verbs or outcomes in sentence case ("Play again", "Change options"). Questions say the consequence ("XP does not carry over"). No exclamation marks, no emoji.

## Iconography

Keep the game's own icon set: the slot glyphs, pile icons, Ether glyphs, stat shapes (heart, flag, shield, star, crown). Draw them single-colour so they take `parchment`, `parchment-muted`, `brass` or a signal colour from context. Icons on stone are at least 16pt; in a chip, 12pt. The previews here use plain diamonds and words where those icons go.

## Replacing the old palette

| Old (night-stone) | New |
| --- | --- |
| ground `#100e17` | `ground` |
| surface `#1d1a29` | `stone` (panels), `stone-raised` (buttons, tabs) |
| line `#3d3757` | `edge` (control rims), `line` (dividers) |
| ink `#f1ecdf` | `parchment` |
| muted `#a69fb8` | `parchment-muted` |
| gold `#f2d16b` | `brass` (actions, selection), `brass-bright` (rewards) |

## Art

`assets/Art` holds crops of the game's own paintings for judging the system against the art: an Encounter, a Region card and a Dragon. They are references, not UI assets.
