# Dragon art: full body, head crops and moving parts

## Goal

Each of the four dragons gets one full-body silhouette, generated for this project, in
place of its game-icons.net head icon. The game shows the whole dragon where the player
chooses it and the head where they face it. Both views come from the same drawing, so
they always match, and a moving part rigged on the full body also works in the head
view.

## The art

- `art/creatures/grimroch.svg`, `helsang.svg`, `rodving.svg` and `vuurhast.svg`, converted
  with `tools/vectorize_art.py` from the approved images (`build/art/prime/`, not in git).
  Their subject lines are in the "Dragons, full body" table of `art/STYLE_PROMPT.md`.
- All four share one pose: side-on facing right, on the hind legs, the head at the upper
  right. That keeps the head crops in the same part of each image.
- `art/creatures/CREDITS.md` lists them as made for this project with FLUX.1-dev, so the
  art test's credit check still holds.
- The eight old dragon files (`spiked-dragon-head`, `dragon-head`, `sea-serpent`,
  `wyvern`, each with `-base` and `-part`) and their credit rows are removed once nothing
  uses them.

## Head crops

`ui/model/art.gd` gets a table of head regions, one square per dragon in the art's
512-unit coordinates (x, y, size):

| Dragon | Region |
|---|---|
| grimroch | 262, 70, 215 |
| helsang | 262, 8, 200 |
| rodving | 245, 8, 195 |
| vuurhast | 240, 0, 200 |

These are first estimates from the renders and get tuned by eye in the game.

`ui/fx/creature.gd` takes an optional crop region. With one, it sizes and offsets every
layer so that the region fills the widget, and clips the rest. Layers are still the
whole 512 canvas, so pivots, the idle shader and the parts need no change. Particles
fill the widget as before.

## Which view goes where

| Place | View |
|---|---|
| Title screen: dragon choice tiles | full body |
| Title screen crest | full body |
| Rules screen crest | full body |
| Region stage header and banners | head |
| Final Battle, Final Journey (dragon small, far side) | full body |
| Final Battle, Final Enemy (dragon large) | head |
| Ending screen | head |

The view state carries the crop with the art name (`"art"` plus `"crop": "head"` or
`"body"`), and each widget passes it to the creature.

The choice tiles draw the art as a plain icon (`ChoiceTile.make` with a texture path), not
through `creature.gd`, so they show the full body without change.

## Moving parts, step 1: jaws

Each dragon's lower jaw becomes its moving part, on a hinge at the back of the jaw, as
the old dragon heads had:

1. Paint a mask over the jaw on the approved image (white over the jaw, a little past
   the joint).
2. Make the body layer with `generate_art.py body`, which inpaints the masked area with
   FLUX Fill as solid throat, using the fill text in the subject table.
3. Convert the whole image, the body (`-base`) and the part (`-part`, with `--mask`).
4. Read the pivot off the art and set it in `Art.PARTS`.

## Moving parts, step 2: arms (after step 1 is approved)

- `creature.gd` and `Art.PARTS` change from one part per creature to a list of parts,
  each its own layer with its own pivot, angle and period. The shader is unchanged: each
  layer already does one hinge.
- Arms for Rodving (the raised foreleg), Helsang (the near arm) and Grimroch (the near
  arm, a slow heavy swing), made the same way as the jaws. Vuurhast keeps only its jaw,
  since its forelimbs are planted legs.

## Tests

- `tests/test_art.gd` keeps its checks: every dragon's art exists, is credited, used
  once, has a motion, and every part has a body, a part and a pivot on the art. It adds a
  check that every dragon has a head region inside the art.
- `tools/ui_check.gd` and `tools/shot.gd` already go through the title, rules, Final
  Battle and ending screens. The screenshot matrix is the visual check of the crops.

## Out of scope

- Style references (FLUX Redux) and a style LoRA, for when the rest of the creatures are
  redone.
- Regenerating the other 33 silhouettes.
