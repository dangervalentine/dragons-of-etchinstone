# Approved source images

The approved silhouettes the game art is made from: the four dragons, the sixteen
card-inspired enemies and the seventeen journey scenes, 1024 px, black on white. The
enemies here are the hand-finished versions; the dragons are still as generated, and the
journeys are first drafts, taken as generated, to be reworked. Together they are the dataset for the
`etchsil` style LoRA. The prompts are in `../STYLE_PROMPT.md`.

The table below records where each image started, before the hand finishing.

`touch-up/` holds the hand-finished versions (black on transparent, with their
Illustrator files); `tools/frame_art.py` puts them on the common canvas as the
`<name>.png` here, which `tools/vectorize_art.py` turns into the game's SVGs.

The dragons are now drawn in layers in Illustrator, as
`art/creatures/<name>-parts.svg` (see `../STYLE_PROMPT.md`); the images here are where
they started.

`painted/` holds the inputs for the coloured art of feature 008 (`tools/paint_art.py`,
`../PAINTED_PROMPTS.txt`): `anchors/`, the shared style references, and `starts/`,
silhouettes painted over by hand to start from in place of the ones in
`art/creatures/`. None of it is approved art. `painted/illustrator/` (git-ignored)
is the Illustrator working folder for the painted art: one `.ai` per picture, named
`<name>-<seed>[-full|-head].ai`, with `_template.ait` and `frame-log.txt`. Illustrator
exports a file as `<file>-01.png`; an approved export is copied to
`art/painted/<name>[-full|-head].png` without the seed, so the exports kept here are
only the ones not promoted.

Godot ignores this folder (`.gdignore`); nothing here ships with the game.

## Where each image came from

ComfyUI numbers are the outputs of `tools/generate_art.py` (FLUX.1-dev), `d` is the
restyle denoise.

| Image | Source |
|---|---|
| grimroch | grimroch_00012_, restyle d0.55 |
| helsang | helsang_00005_, restyle d0.55 |
| rodving | rodving_00008_, restyle d0.7 |
| vuurhast | vuurhast_00016_, restyle d0.75, stray marks painted out |
| panda-fighter | panda-fighter_00022_, painted fix, restyle d0.35 |
| crane-monk | crane-monk_00018_, painted fix, restyle d0.5 |
| axe-gnome | axe-gnome_00021_, painted fix, restyle d0.5 |
| lion-archer | lion-archer_00009_, painted mane fix, restyle d0.35 |
| club-ogre | club-ogre_00006_, cleaned by hand, mirrored, restyle d0.35 |
| hedge-wizard | hedge-wizard_00009_, straight crook staff painted, restyle d0.3 |
| twin-ghoul | twin-ghoul_00005_, fringes smoothed, second head painted, restyle d0.3 |
| boar-shaman | boar-shaman_00009_, mirrored, ground erased |
| naga | naga_00021_ (restyle d0.55 of naga_00010_), ground erased |
| monkey-brawler | monkey-brawler_00014_, tail erased |
| twin-ogre | twin-ogre_00013_ (from twin-ogre_00009_: bare forearm and gnarled branch painted, loincloth smoothed, restyle d0.3) |
| goblin-hexer | goblin-hexer_00016_ (from goblin-hexer_00009_: robe smoothed, tail erased, tooth necklace painted, restyle d0.4) |
| horned-goblin | horned-goblin_00007_ (from horned-goblin_00001_: ground cut, plain grip, fringes smoothed, restyle d0.4), tail and belt removed by hand |
| marsh-treant | marsh-treant_00009_, restyle d0.6 of a hand edit of marsh-treant_00006_ |
| antler-horror | antler-horror_00009_, restyle d0.6 of a hand edit of antler-horror_00003_ |
| gath-brute | gath-brute_00007_, restyle d0.45 of a hand edit of gath-brute_00004_ |

Journey first drafts, as generated (natural-landscape scene prompts):

| Image | Source |
|---|---|
| peaks | peaks_00004_ |
| waterfall | waterfall_00003_ |
| mountain-road | mountain-road_00002_ |
| cave-entrance | cave-entrance_00002_ |
| swamp | swamp_00005_ |
| river | river_00003_ |
| willow-tree | willow-tree_00001_ |
| cliff-crossing | cliff-crossing_00002_ |
| volcano | volcano_00003_ |
| desert | desert_00004_ |
| lava | lava_00003_ |
| underground-cave | underground-cave_00001_ |
| rope-bridge | rope-bridge_00003_ |
| forest-entrance | forest-entrance_00005_ |
| burning-forest | burning-forest_00003_ |
| stone-path | stone-path_00002_ |
| horizon-road | horizon-road_00002_ |
