# Etchinstone design system — local copy

- `README.md` — the guide: principles, colour, type, spacing, shapes, states, voice.
- `tokens.json` — every token with its usage note (the source of truth).
- `tokens.css` — the same tokens as CSS variables, @font-face rules and type classes.
- `fonts/` — Fraunces (variable) and Alegreya Sans 500/700/800, woff2, both SIL Open Font License. Godot 4 imports woff2 directly.
- `components/<Name>/README.md` — rules per component; `preview.html` opens in a browser.
- `components/bundle.css` — reference CSS for the components (a spec for your StyleBoxes, not code to ship).
- `assets/Art/` — reference crops of the game art.

Sizes are phone points; multiply by 1.85 for a 720px-tall Godot base viewport.
