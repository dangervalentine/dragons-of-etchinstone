# Panel

A panel is a slab of carved stone that holds one job: the Action Set tray, Result, Prepare, the score.

- `stone` fill, 2px `edge` rim, 1px parchment inner highlight, `chamfer-lg` corners. No gold outline at rest: brass is reserved for "this is selected / this is the target".
- Head: `heading` in `parchment`, a `brass` glyph before it, a `line` rule under it.
- Inside, figures use the Numerals styles; sums read left to right with muted operators and the result in `brass-bright`.
- Outcomes: good in `jade` with a tick, harm in `danger` with a minus or heart. Never colour alone.
- The current panels are drawn as stacked paper cards; keep that only for things that really are cards (Region, Encounter, Key). Information panels are stone.
