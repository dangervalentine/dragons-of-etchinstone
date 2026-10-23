# Contract: components

Every component is built from the tokens, the materials and the type styles. The rules
come from [`../design-system/components/<Name>/README.md`](../design-system/components/);
this contract records where each one lives in the game and the decisions on top of the
README.

## Button: `UI.button(text, kind = "stone", icon = "")`

- **Kinds**:
  - `stone`: a plinth with `PARCHMENT` `BUTTON` text.
  - `primary`: a brass plinth with `ON_BRASS` text and meta `primary`.
  - `quiet`: a plinth at depth 0.3, used for secondary actions in a row.
- `warning`, `active` and `style_button` are removed.
- Height `ACTION_H` in the play screen's action row; at least `TAP_MIN` everywhere.
- An icon sits above the label, `SPACE_1` apart. Counts follow a middle dot in `NUMERAL_SM`
  (Divert · 2).
- **One primary per screen**:
  - Title: Play.
  - Dragon: Continue.
  - Rules: Set out.
  - Lessons: Continue/Start again.
  - Ending: Play again.
  - Play: the action bar's primary.
  - Coach mark: Next.
  - Dialog: its answer.

## Tabs: `ui/widgets/tab_row.gd`

- A row of plinths at `CHAMFER_SM`, `TAP_MIN` high, sized to the label plus `SPACE_4` each
  side.
- The label is `BUTTON` style at `BODY` size in `PARCHMENT_MUTED`. Selected: `STONE` face,
  `BRASS` 6-unit rim, `PARCHMENT` label. Exactly one is selected.
- Used for:
  - the records dragon filter;
  - the Leaderboard/History switch (new: tabs at the top of the records screen);
  - Boost aim (Attack/Initiative per set);
  - the rulebook contents' current section;
  - the menu's Motion and Window rows;
  - the records screen's difficulty filter.
- ChoiceTile stays only for tiles with descriptions (the setup screen's difficulty grid and
  the alternate rules). This departs from the Tabs README on purpose: those tiles explain
  each choice, which a tab cannot. They are restyled as
  plinths with the brass selected rim and the jade focus rim.

## Slot: `place_labels.gd` and `hand_tray.gd` `_Outline`

- The header is `LABEL` and the well is a `well` at the card's size. States follow
  data-model "Place state".
- The target well shows its name inside, in `LABEL` `BRASS`.
- The divider between Set 1 and Set 2 is a `LINE` hairline.
- The Steep/Freeze rule icon stays `DANGER`.

## Panel: `UI.panel(heading = "", icon = "")`

- A slab at `CHAMFER_MD` (`CHAMFER_LG` for the Action Set tray), padded `SPACE_3`/`SPACE_4`.
- Head: a glyph in `PARCHMENT_MUTED`, then the heading in `HEADING` `PARCHMENT`, with a
  `LINE` rule under it. The Panel README puts a brass glyph here; it is muted instead
  because the README's own "Brass means here" principle reserves brass, and a panel head
  at rest is not a choice. This departure is deliberate.
- Sums read left to right with `PARCHMENT_MUTED` operators. The result is `BRASS_BRIGHT`
  only when it is a reward (XP, Score); otherwise `PARCHMENT`.
- Replaces `UI.slab`, `stone_slab`, `stone_zone`, `raised_panel_box` and `panel`. The soak
  meter's and XP purse's zones are panels.

## Chip: `UI.chip(icon, figure, tone = "plain")`

- A well at `CHIP_H`, `CHAMFER_SM`, with a `LINE` rim, the icon then the figure in
  `NUMERAL_SM`.
- Tones:
  - `plain`: `PARCHMENT`.
  - `reward`: `BRASS_BRIGHT`.
  - `harm`: `DANGER`, always with its sign or heart.
- Wrapped in a hit area when it opens the glossary: `TAP_MIN` in the top bar (the TopBar
  README's `touch-min` for counters), `HELP_MIN` only for chips inside panels.
- Used for the top bar's pile counts and the preview panel's pills. `stat_chip` (figures
  on stat shapes on cards) keeps its shapes and takes `STAT_PLATE` plates.

## Dialog: `confirm_dialog.gd`

- A slab at `CHAMFER_LG`, `DIALOG_W` wide, padded `SPACE_5`, over `SCRIM`.
- **Title** (new): the question, in `TITLE`. **Body**: the consequence in one sentence, in
  `PARCHMENT_MUTED` `BODY`.
- Buttons: stone (safe) on the left, primary (answer) on the right.
- The unspent-XP question draws its body on paper inside the dialog (FR-020).
- Callers give a title and a body:
  - Learn to Play offer.
  - Clear records.
  - Abandon run.
  - Unspent XP: "XP does not carry over".

## Banner: `stage_banner.gd`

- A lintel over `SCRIM`.
- The rim and medallion ring are the Region tint (`REGION[n]`, `REGION_LAIR` for the
  finale).
- The kicker is `LABEL` `PARCHMENT_MUTED`; the headline is `BANNER` `BRASS_BRIGHT`.
- It slides in, holds and slides out.
- The ending uses it too: victory has a `REGION_LAIR` rim and a `BRASS_BRIGHT` headline;
  defeat has a `DANGER` rim and a `PARCHMENT` headline.

## Ledger: `ui/widgets/ledger.gd`

- Column heads in `LABEL` `PARCHMENT_MUTED`; rows in `BODY_SM` with `LINE` hairlines, at
  least 56 units high (30pt).
- Scores in `NUMERAL` (tabular). Place and "—" in `PARCHMENT_MUTED`.
- The best row is `BRASS_BRIGHT`, and only that row. A whole row is the tap target when it
  opens something.
- Used by the Leaderboard, History, the ending's score table, rulebook tables and the
  dragon table.

## CoachTip: `coach_mark.gd`

- The bubble is `UI.paper_box()`, at most `COACH_MAX_W` wide, with a pointer at the target.
- The ring round the lit target is `BRASS` `BORDER_SELECT` (it is "here"); the dim is
  `SCRIM`.
- Glossary terms in the text are bold with a `BRASS_DEEP` underline.
- Specs 017's coach-mark contract keeps its behaviour, with these colours.

## TopBar: `header_bar.gd`

- A `STONE` bar `TOPBAR_H` high inside the safe area, with a 4-unit `CARD_FRAME` line under
  it.
- The heading is in `TITLE` (contracts/type-styles.md "Top bar").
- The pile counts are chips with the pile icons.
- Menu and Back are stone slabs at least `TAP_MIN` square. On menu screens (Leaderboard,
  Hunt a Dragon), Back is on the left and the title is centred.

## MageCard: `card_face.gd` and `card_view.gd`

See contracts/materials-and-ground.md "Cards". The role ribbon added under an assigned card
(`card_view.gd:427`) is `CARD_RIBBON` with `PARCHMENT` text, not gold.
