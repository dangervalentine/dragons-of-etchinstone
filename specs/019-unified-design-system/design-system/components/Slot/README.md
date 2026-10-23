# Slot

The four places of an Action Set: Reserve, Element, Spell, Boost.

- Header: `label` style, uppercase. `parchment-muted` when empty, `parchment` once filled, `brass` with a 2px `brass` underline when it is the slot the next tap will fill. Only one target at a time.
- Well: `well` fill, `shadow-well`, 1px `line` rim, `chamfer-sm`, sized to `card-width` at 5:7. The target well gets a 3px `brass` rim and its name inside.
- The current tray draws a gold box around every header; that spends brass on things that are not choices and hides which slot is live.
