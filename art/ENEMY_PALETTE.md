# Enemy palette

Every painted enemy and dragon (`art/painted/`) is coloured from this palette and
nothing else. Swatches for Illustrator: `enemy-palette.ase` (File > Open Swatch
Library > Other Library). Preview: `enemy-palette.png`.

The palette is built in OKLCH, so the families match each other step for step.
Every family uses the same four lightness steps and keeps its chroma low and
fixed. That leaves the Ether as the only saturated colour on a creature.

## Body families

| Family | Use for | 1 (L .32) | 2 (L .44) | 3 (L .56) | 4 (L .68) |
|---|---|---|---|---|---|
| stone | neutral hide, stone, bare grey skin (ogres, ghouls, antler horror, naga) | `#30342f` | `#50544f` | `#717670` | `#959a94` |
| slate | cool hide, scales, iron (ape, treant, dragons, crane, helmets, blades) | `#27353e` | `#47555e` | `#687781` | `#8b9ba6` |
| dusk | cloth: robes, hoods, tunics, sashes, trousers | `#313142` | `#505063` | `#727286` | `#9696ab` |
| hide | warm skin, bellies, faces, manes, beards, horns | `#3b3121` | `#5c5140` | `#7e7361` | `#a39684` |
| umber | fur, leather, belts, boots, wood (panda, boar, staffs, clubs) | `#462b21` | `#684a40` | `#8c6c61` | `#b19084` |
| moss | goblin skin, bark, moss | `#2e3623` | `#4d5642` | `#6f7963` | `#929d86` |

## Constants

| Name | Hex | Use for |
|---|---|---|
| ink | `#1f1f24` | outlines, mouths, eye sockets, the deepest folds |
| bone | `#ddd7ca` | teeth, claws, tusks, bone horns |
| oxblood | `#74383b` | gums, tongues, old blood; the only warm accent that isn't Ether, used small |

## Ether

`deep` is the card's Ether colour from `ui/theme/tokens.gd` (`ETHER`), so the
creature matches its card.

| Ether | core | glow | deep |
|---|---|---|---|
| fire | `#ffe5df` | `#ef6856` | `#c8261d` |
| water | `#d4f5ff` | `#4ec0ed` | `#1f5fd0` |
| lightning | `#ffead3` | `#ffae4c` | `#e99a1c` |
| shadow | `#f6e8ff` | `#b883e6` | `#6b34c0` |

- **glow** is the main colour of the energy (flames, frost, sparks, smoke) and of the eyes.
- **core** is the hot centre: the eye slit, the base of a flame, the brightest line of an arc.
- **deep** is the edges and tips where the energy fades, and never covers a large area.

## Rules

1. **Base and shade are one step apart.** A form painted with step *n* takes its
   one hard shade in step *n − 1* of the same family. Step 1 is only ever a shade.
   Every creature then has the same contrast between light and shade.
2. **One main mass.** The largest area of a creature is a single family at step 3
   or 4. Pick step 2 only for a creature meant to read as dark (the crane, Helsang),
   and give it a step 3 or 4 area near the head so it still shows.
3. **At most three families per creature**, plus ink, bone and its Ether. Cloth is
   always dusk, fur and leather always umber, and skin is one of
   stone/slate/hide/moss.
4. **Nothing on the body is darker than step 1 except ink.** The UI background is
   L .17–.29, so a body darker than step 2 merges into it; only shades and ink go
   that dark.
5. **Only the Ether is saturated.** Each creature uses one Ether, at the eyes and in
   one place (see `PAINTED_PROMPTS.txt`), and never anywhere else. A ruby, fire on a
   water creature, red eyes on a shadow creature all break the rule.
6. **No new colours.** If a part has no family that fits, use the closest swatch.
   Don't mix a new one.

## Notes on the current set

When all 20 current images are snapped to this palette automatically, they keep
their look. The palette was taken from what they already do. The changes are
tightening, not a repaint:

- Water art today glows cyan (`#3cd7e4`), while the card's water colour is a royal blue
  (`#1f5fd0`). Water glow `#4ec0ed` sits between the two, so the creatures and
  their cards look related.
- The shadow glows move slightly toward the card's violet (from about `#db9eec` to
  `#b883e6`).
- The lion's ruby quiver is fire red on a fire creature, which is allowed. Any
  similar jewel on a creature of another Ether becomes bone or oxblood.
