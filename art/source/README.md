# Approved source images

The approved silhouettes the game art is made from: the four dragons
and the sixteen card-inspired Encounters, 1024 px, black on white. They are the
starting point for the hand clean-up in Illustrator and then the dataset for the
`etchsil` style LoRA. The prompts are in `../STYLE_PROMPT.md`.

`masks/` holds the dragons' lower-jaw masks, white over the jaw, used by
`tools/draw_throat.py` and `tools/vectorize_art.py --mask` to split each dragon
into its body and moving jaw.

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
