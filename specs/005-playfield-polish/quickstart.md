# Quickstart: Validating Playing Field and Card Polish

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

## Prerequisites

- Godot 4.7.2 on `PATH` (`godot --version`)
- Python 3 (standard library only), for regenerating icons: `python3 tools/gen_icons.py`
- The official scans in `reference/sheets-official/` (git-ignored; for side-by-side
  comparison only, never shipped)

## 1. Automated checks

```sh
./tools/test.sh
```

Expected: every existing test passes, plus the new ones:

| Test | Proves |
|---|---|
| `tests/test_emphasis.gd` | Every row of the step table; Reserve Boost and Spell-in-effect agree with the engine ([contracts/step-emphasis.md](contracts/step-emphasis.md)) |
| `tests/test_card_contrast.gd` | Every numeral and label meets 4.5:1 (text) / 3:1 (large numerals) in every Ether and treatment (FR-026, SC-005) |
| `tests/test_card_face_layout.gd` | Regions inside the face, not overlapping, numerals no smaller than today at Hand size |
| `tests/test_layout_solver.gd` | Card-size floor per matrix size; gaps; existing invariants (SC-004) |
| `tools/ui_check.gd` (run by `test.sh`) | Seeded games through the real screens at every size: nothing off screen, too small, or scrolling; same outcomes as the engine alone (SC-010) |

## 2. Screenshot review

```sh
godot --path . -s tools/shot.gd -- build/screenshots/005 phone-16x9 desktop tablet
godot --path . -s tools/design_shots.gd -- build/screenshots/005-cards
```

Check, against the same shots taken on `main` before the change:

- `03_challenge_empty`, `04_challenge_one`, `05_challenge_assigned`: Hand cards
  emphasise Spell plates, then Ether and Initiative, then Boost as each slot comes
  up; the next slot carries the same focus rim. Placed cards emphasise only their
  role.
- `07_soak`: Armor crests emphasised, matching-Ether cards show the ×2 chip, Covered
  cards look unavailable (greyscale), not quietened.
- `08_upgrade`: cost emphasised; affordable, unaffordable and max read differently;
  changed figures ringed.
- `09_inspect`: every Level of the card in a row, current one raised and titled.
- Every shot: regions separated by visible air; header quieter than the Encounter;
  panels, cards and background read as three layers.
- Card faces beside the official scans: frame, bronze key strip, torn edges, sword
  spine, crests, octagon plates, Ether pip by the name.

## 3. Ether character (SC-008)

1. Open `ethers.png` from the `tools/design_shots.gd` output (extended by this
   feature to render one face per Ether at Hand size), or run the game with a Hand
   holding all four Ethers.
2. Watch each card for 10 seconds: the fields stay calm; a faint holographic sheen
   drifts slowly across each one and a few glints fade in and out. Nothing flashes
   or flickers.
3. Convert a still of the four cards to greyscale; ask someone to name each Ether.
   Pass: 9 of 10 trials correct.
4. Set Menu → Motion → Reduced: fields stop moving and each keeps its character as a
   still; emphasis changes appear instantly.

## 4. Performance (SC-007)

```sh
godot --path . -s tools/field_bench.gd            # desktop
```

Expected: average frame ≤ 16.7 ms and 99th-percentile frame ≤ 33 ms over 10 s with 11 animated
faces. Then export the web build and open the play screen with a full setup offer on
a mid-range phone browser: no visible stutter while idle, while placing cards, or
during the resolution sequence.

## 5. Observer checks (SC-001, SC-003, SC-006, SC-009)

- Show the Hand in each step for 3 seconds; the viewer points to the value that
  matters on each card (9 of 10).
- Show the play screen for 5 seconds to a first-time viewer; they name the Encounter,
  the predicted result and the Play control.
- Show before and after screenshots side by side; ask which looks more finished.
- Show a Hand card to someone who owns the physical game; they match it to the
  printed card without being told.
