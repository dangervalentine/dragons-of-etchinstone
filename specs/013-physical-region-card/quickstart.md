# Quickstart: Checking the Physical Region Card

## Run the checks

```sh
tools/test.sh                       # headless suites, then ui_check across every MATRIX shape
godot --headless --path . -s tools/space_audit.gd
```

Expected:
- All suites pass.
- `ui_check` reports no `DOE-` labels, no tip strings, whole-card numerals ≥ 22, notes that fit, and no jump between the zoomed card and the landed panel.

## Look at it

```sh
godot --path . -s tools/design_shots.gd -- build/screenshots/013 deck
godot --path . -s tools/design_shots.gd -- build/screenshots/013 scan
```

Check the `deck` shots against [contracts/region-card-face.md](contracts/region-card-face.md) and [contracts/left-column.md](contracts/left-column.md):

| Shot | Look for |
|---|---|
| Whole card, Region 1 | The title band, Enemies 2 × 2, Journeys in a row of four, XP stars, number markers, no code |
| Enemy landed | The same panel enlarged, a moving creature, and a reading strip with name, Hardship and Ability |
| Journey landed | The tall panel, the MP/Time header, and the strip with the Peril |
| Each note | setup, mode (Divert), refusal, result with outcome lines, upgrade, soak. Each sits on the stack, with the edges visible |
| Dragon Card | The printed layout, no code |

The `scan` shot overlays the official Jade Mountains card at 50%. Every panel's edges and badges should line up within a few pixels (SC-001). If they don't, tune `RegionCard.LAYOUT`.

## Play it

Use the `install-on-emulators` skill, or run the desktop build. Play Region 1 through to its End:

1. The left side is only the stack.
2. The stack thins with each draw and Divert, and refills at the reshuffle.
3. Each Encounter zooms from the card into its panel and back.
4. Pressing Play shows the result note with the reasons written out.
5. Diverting shows its step note. Holding the note shows the Enemy beneath.
6. A refused Play shows its reason in the card's place.
