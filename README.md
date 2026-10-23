# Dragons of Etchinstone (digital)

A fan-made digital version of *Dragons of Etchinstone*, the solo palm-playable card
game designed by Joe Klipfel and published by Chip Theory Games. Built with Godot 4.7
for web, Android and iOS.

This project is not affiliated with or endorsed by Chip Theory Games. The game's
name, rules text and artwork belong to their owners. The rulebook, card scans and
other reference material used to build it are not part of this repository.

## Status

A complete solo game is playable from the menu through four Regions and the Final
Battle:

- All 16 Mage Cards, 4 Regions and 4 dragons, with every Hardship, enemy Ability and
  journey Peril
- Fusing, Diverting, Regrouping, Knock Out, poison, and scoring
- The six difficulty levels and both alternate rules (Cavalier, Glass Cannon)
- A landing page (Play, Learn to Play, the Leaderboard, the Glossary), then the choice of dragon, one
  dragon's figures at a time, then the difficulty and alternate rules
- A landscape interface for phones, tablets and desktop browsers, played by touch,
  mouse or keyboard
- How to Play: the rules in this project's own words, written for the digital game,
  readable from the menu or the H key without disturbing a
  game in progress, with labelled example cards and links into the Glossary
- Learn to Play: six short lessons played on the real screens under the real rules,
  each from a table of its own (setting out with Rodving, a Victory, a Narrow
  Victory on a Journey, a Loss and its Soak, a Fuse, the end of a Region), with a
  message beside whatever is being explained and the move to make held to the
  lesson's. Offered on the first Play, kept as finished lesson by lesson, and never
  recorded

The play screen keeps everything for a turn in view: the Encounter, your Action
Set, your Hand and the controls. The left side is the Deck and nothing else, as held
in the physical game: a stack of Mage Cards as deep as the cards left in the Region,
with the Region Card on top, drawn as the printed card (its four Enemies two by two,
its four Journeys in a row beneath, each with its figures and XP star), or the
printed Dragon Card in the Final Battle. Each Hand is drawn from under it; then the
Key Card rises from beneath the Region Card just far enough to show the Encounter it
names and any Hardship, slides back, and the view zooms into that Encounter's panel
on the card, the rest of the card dimmed round it, with its name and what its
Hardship, Ability or Peril does written along the foot. When there is something
else to read (a Fuse, Divert or Regroup step, a refused move, the result of a Play
set out line by line, the Soak or the XP to spend) a note is laid on the Deck in the
card's place; hold it to look under it. At the end of a Region the card turns over
to the next Region, or gives way to the other card. Each card lifts the parts that will count when you
play it, and an Encounter's Hardship or ability shows its mark beside each figure it
works against; against an Enemy you aim the Boost at Attack or Initiative on the
Boost card itself. Committing plays a short sequence showing what happened (the
sum against its target and the verdict, then what it earned and cost), which a tap
skips. Spending XP sends it to the card as stars. Cards are drawn in their Ethers'
mineral colours (lapis, ochre, amethyst, cinnabar) with their numbers and icons in the
same arrangement as the printed cards. The interface follows the "Inkstone and Brass"
design system (`specs/019-unified-design-system/design-system/`): slate stone lettered
in parchment, with brass only for the next thing to do.
Each Encounter has a name of this project's own (the cards only number them) and is
shown by a silhouette that idles (breathing, hovering, swaying,
rippling or shimmering, with its Ether drifting around it as embers, bubbles, sparks
or motes); the enemies are drawn for this project after the creatures on the official cards,
and the dragons have full-body art made for this project, with a moving jaw,
shown whole when choosing a dragon and cropped to the head when facing it. The Mage
Cards carry an Ether emblem in place of an illustration. Hovering a card opens a larger copy with every figure spelled out, holding a card
shows its other Levels, and pressing any figure or effect explains it. A reduced-motion setting follows the device by default.

## Requirements

- [Godot 4.7.2](https://godotengine.org/) (standard build, not .NET), with `godot` on
  your `PATH`
- For Android: the Android SDK and JDK 17
- For iOS: Xcode
- The matching Godot export templates for any platform you export to

## Run it

```sh
godot --path .
```

Or open the folder in the Godot editor and press F5.

## Tests

The rules engine has no dependency on the interface. It and the interface's own
logic (the view state, the player's draft, the animation sequencer, the layout and
the glossary) are covered by a headless test suite, followed by a UI check that
plays seeded games through the real screens:

```sh
./tools/test.sh                 # quick: unit tests, UI check at the smallest phone (~1 min)
./tools/test.sh full            # UI check at every window size in the layout matrix (~3.5 min)
./tools/test.sh unit rules game # only tests/test_*.gd files whose names contain these
./tools/test.sh ui deck divert  # only these UI check walks
```

The UI check's walks are `notes screens marks play deck skip look ending resize
divert arrange lessons`. Run the quick check while working, the walks or unit files that
cover a change to look at it closely, and `full` before a commit.

Screenshots of every screen at every size, for review by eye:

```sh
godot --path . -s tools/shot.gd -- build/screenshots/matrix
```

## Put a build on a device

```sh
scripts/install.sh            # Android emulator, iOS simulator and web
scripts/install.sh android
scripts/install.sh ios
scripts/install.sh web
```

The script exports from Godot, then installs and launches on whichever Android
device and iPhone simulator are already running, saving a screenshot of each to
`build/screenshots/`. For web it serves the build at
`http://127.0.0.1:8765/index.html`.

**iOS simulator on Apple Silicon:** Godot's official iOS export template only
includes an Intel simulator library, so simulator builds fail to link until the
template is patched. The steps are in
`.claude/skills/install-on-emulators/references/ios-simulator-template.md`.

Signed iOS and Android release builds are exported from the Godot editor in the
usual way. Set your own team ID and bundle identifier in the export presets.

## Layout

| Path | What it holds |
|---|---|
| `data/cards.json` | Every card's numbers, keyed by the printed card codes |
| `data/flavor.json` | The landing page's subtitle and each dragon's flavour line, written for this project; edit by hand |
| `engine/card_db.gd` | Read-only access to the card data |
| `engine/rules.gd` | Encounter maths, as pure functions |
| `engine/game.gd` | One game's state and flow, driven by a small set of actions |
| `ui/main.gd` | The root: owns the game, lays out the screen, applies every press |
| `ui/model/` | The interface's logic, with no nodes: view state, draft, sequencer, layout, glossary, settings |
| `ui/theme/` | Design tokens (sizes, colours, type, timings), held to `specs/019-unified-design-system/design-system/tokens.json`, and the theme built from them |
| `ui/screens/` | Title, play and ending screens |
| `ui/widgets/` | Card and Encounter faces, preview, slots, Hand and the rest of the play screen |
| `ui/overlays/` | Inspect, glossary, stage banners, menu and dialogs |
| `ui/fx/` | The animator, the effects layer and the shaders |
| `art/icons/` | The icon set and sigils, generated by `tools/gen_icons.py` |
| `art/fonts/` | Fraunces (with tabular figure cuts made by `tools/make_figures.py`) and Alegreya Sans, under the SIL Open Font License |
| `art/creatures/` | Enemy, journey and dragon silhouettes made for this project, listed in `CREDITS.md` |
| `art/source/` | The approved images the silhouettes are made from |
| `tests/` | Test runner and tests |
| `tools/` | Test script, UI check, screenshot driver, data and icon generators, and art generation, painting, framing and vectorising (`generate_art.py`, `paint_art.py`, `frame_art.py`, `vectorize_art.py`), and the dragon rig splitter (`split_rig.py`) |
| `scripts/install.sh` | Build, install and launch on emulators and web |
| `specs/` | Specification, plan and tasks for each feature |

## Credits

- Enemy, journey and dragon art: made for this project with FLUX.1-dev, the enemies
  finished by hand
  (`art/STYLE_PROMPT.md`, `art/source/`, `tools/frame_art.py`, `tools/vectorize_art.py`,
  `tools/split_rig.py`).
- Fonts: Fraunces and Alegreya Sans, under the SIL Open Font License (`art/fonts/`);
  the "Etchinstone Figures" cuts are Fraunces with every digit one width.

## Card data

`data/cards.json` was transcribed from the retail cards and cross-checked against
the earlier print-and-play edition and a fan-made pixel-art variant. It is written by
`tools/gen_cards.py`, which also checks the numbers for internal consistency.

## Rules interpretations

Where the rulebook is silent or ambiguous, the engine does the following:

- An enhanced action whose type does not fit the Encounter falls back to the basic
  action rather than counting as 1.
- Enemy Armor reduces an enhanced Attack only, not a Move used against a Slow enemy.
- Fusing in a Region needs a full Hand of four.
- Diverting needs a second card in the deck to become the new Key Card.
- Knock Out is applied automatically when the Hand cannot Soak the damage.
- A Final Journey time penalty the deck cannot pay is added to the dragon's damage.
- With fewer than five cards left at a Region change, play goes straight to the
  Final Battle.
