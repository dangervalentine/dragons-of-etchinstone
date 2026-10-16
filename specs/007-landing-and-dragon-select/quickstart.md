# Quickstart: validating Landing Page and Dragon Selection

## Automated

```sh
./tools/test.sh
```

Expect `0 failed` for the unit tests (including `tests/test_flavor.gd`) and the UI check. The UI check should now assert, at every matrix size:

- launch shows the landing page with no dragon tiles and no dragon stats;
- How to Play opens and closes back to the landing page; Records' Back returns to it;
- Play shows `DragonScreen` with four tiles, each with a flavour line, and exactly one stats block, for `options.dragon`;
- choosing each other dragon moves the stats to it;
- Back / Escape returns to the landing page and Play again keeps the dragon;
- Continue → rules page; its Back returns to the dragon page with the dragon kept;
- set out starts a game; leaving it returns to the landing page.

## By eye

```sh
godot --path . -s tools/shot.gd -- build/screenshots/matrix
```

Check `01_title.png` (landing) and the new dragon-page shot at each size, especially `upright-browser` and `phone-small`: nothing clipped, Play stands out, stats readable.

## Editing the text (after implementation)

Edit `data/flavor.json` by hand, relaunch the game; no code change. Run `./tools/test.sh` to confirm every dragon still has a line.
