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
- A landing page (How to Play, Records, Play), then the choice of dragon, one
  dragon's figures at a time, then the difficulty and alternate rules
- A landscape interface for phones, tablets and desktop browsers, played by touch,
  mouse or keyboard
- How to Play: the rules in this project's own words, written for the digital game,
  readable from the landing page, the in-game menu or the H key without disturbing a
  game in progress, with labelled example cards and links into the Glossary

The play screen keeps everything for a turn in view: the Encounter, your Action
Set, a preview of the outcome (your totals against the targets, the verdict, and
what it will earn and cost), your Hand and the controls. Committing plays a short
sequence showing what happened, which a tap skips. Cards are drawn in their Ether
colours with their numbers and icons in the same arrangement as the printed cards.
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
plays seeded games through the real screens at every window size in the layout
matrix:

```sh
./tools/test.sh
```

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
| `ui/theme/` | Design tokens (sizes, colours, type, timings) and the theme built from them |
| `ui/screens/` | Title, play and ending screens |
| `ui/widgets/` | Card and Encounter faces, preview, slots, Hand and the rest of the play screen |
| `ui/overlays/` | Inspect, glossary, stage banners, menu and dialogs |
| `ui/fx/` | The animator, the effects layer and the shaders |
| `art/icons/` | The icon set and sigils, generated by `tools/gen_icons.py` |
| `art/fonts/` | Cinzel and Alegreya Sans, under the SIL Open Font License |
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
- Fonts: Cinzel and Alegreya Sans, under the SIL Open Font License (`art/fonts/`).

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
