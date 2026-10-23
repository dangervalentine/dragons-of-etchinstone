# Contract: type styles

The values come from `tokens.json` → `type.groups`, with sizes × 1.85. Display is
Fraunces (variable, `SOFT` 50, `WONK` 0, `opsz` per style). Sans is Alegreya Sans
(Medium 500, Bold 700, ExtraBold 800, with `lnum` and `tnum` on).

| Style | Family | Size | Weight | opsz | Spacing | Case | Use | Replaces |
|---|---|---|---|---|---|---|---|---|
| `BANNER` | display | 63 | 800 | 72 | 0.01 em | UPPER | Region banner, verdict, the game's name | `TITLE`, `BANNER` |
| `TITLE` | display | 41 | 700 | 36 | 0.01 em | Title | top-bar heading, dialog and screen titles | `H1` |
| `HEADING` | display | 31 | 700 | 24 | 0 | Title | panel heads, Encounter names, dragon names | `HEADING`, `SUBHEAD` |
| `CARD_NAME` | display | fits the band, ≥ 20 | 700 | 12 | 0.03 em | UPPER | Mage Card names | card_face's own Cinzel |
| `NUMERAL_XL` | display | 67 | 900 | 72 | 0 | — | Score, Key Card Level, Dragon HP | `NUMERAL_L` |
| `NUMERAL` | display | 37 | 800 | 24 | 0 | — | card figures, Result sums, stat shapes | `NUMERAL` |
| `NUMERAL_SM` | display | 26 | 800 | 14 | 0 | — | counters, ribbon cost and XP, chips | `NUMERAL_S` |
| `LABEL` | sans | 22 | 800 | — | 0.1 em | UPPER | slot headers, column heads, kickers | `EYEBROW`, `LABEL_BOLD` |
| `BUTTON` | sans | 30 | 800 | — | 0.01 em | Sentence | every button label | `BUTTON` |
| `BODY` | sans | 28 | 500 | — | 0 | — | panel copy, coach tips, rulebook | `BODY` |
| `BODY_SM` | sans | 24 | 500 | — | 0 | — | effect text, table rows | `LABEL` |
| `CAPTION` | sans | 22 | 500 | — | 0 | — | hints, fine print | `LABEL` (hints) |

- **Figures**: every game number uses a `NUMERAL*` style and is tabular (research R3).
  `numerals.gd` draws with the style's font.
- **Case**: the style applies UPPER. Code does not call `.to_upper()` for display. Titles and
  headings are written in title case in their source strings.
- **Running text**: at most about 60 characters a line on stone and 50 on paper
  (`BODY` × 0.5 em ≈ 14 units a character, so about 840 and 700 units wide).
- **Floors**: no `Label` or `RichTextLabel` below `TEXT_MIN`; no drawn string below
  `TEXT_MIN`, except card names (`CARD_NAME_MIN`).
- **Top bar**: `"<Region name> · Region <n>"`, with the name in `PARCHMENT` and
  `· Region <n>` in `PARCHMENT_MUTED`. For the finale it is `"<Dragon>, <title> · Final Battle"`.
- **API**: `UI.font(style) -> Font` (one cached `FontVariation` per style);
  `UI.label(text, style = T.BODY, colour = T.PARCHMENT)`; `UI.style_label(label, style, colour)`.
  The `[font, size]` arrays and the `display`/`display_bold`/`numeral`/`body*` font names
  are gone.
