# Quickstart: Validating Two-Step Game Setup

## Prerequisites

- Godot 4.7.2 on `PATH` (see `README.md`).
- For device checks: the running Android emulator and iOS simulator (the `install-on-emulators` skill builds and installs).

## Automated

```sh
./tools/test.sh
```

Expected: the unit suite passes unchanged, and the UI check ends `ui check: N checks, 0 failed`. At every size in `Solver.MATRIX`, the extended UI check:

1. Inspects the dragon screen. No control or text runs off screen. No difficulty or rule tiles are present.
2. Sends `setup_rules` and inspects the rules screen the same way. All six difficulty tiles and both rule tiles are present, along with the chosen dragon's name.
3. Changes the difficulty and turns on a rule, goes back (`setup_dragon`), picks another dragon and continues. Difficulty and rule are unchanged.
4. Presses Set out. `ui.game` exists with that dragon, difficulty and rules, and `Settings.last_options` matches.

## Design shots

```sh
godot --path . -s tools/design_shots.gd
```

Expected: a `title` shot (dragons only) and a new `rules` shot, then the existing shots.

## By hand (desktop, `godot --path .`)

| Step | Expected |
|---|---|
| Launch | Dragon screen with the last-used dragon marked; Continue focused |
| Enter, Enter | A game starts with last-used options (SC-001: 2 presses) |
| Leave game → confirm | Back on the dragon screen |
| Pick another dragon, Continue | Rules screen shows that dragon; last difficulty and rules marked |
| Change difficulty, Escape | Dragon screen; Continue → difficulty change still there |
| Open Settings on dragon screen, close | Same screen, same choices |

## By hand (Android emulator)

| Step | Expected |
|---|---|
| On rules screen, system back | Dragon screen, choices kept |
| On rules screen with Glossary open, system back | Glossary closes; still on rules screen |
| On dragon screen, system back | App exits (unchanged) |
