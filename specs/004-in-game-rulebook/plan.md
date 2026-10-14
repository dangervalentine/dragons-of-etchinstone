# Implementation Plan: In-Game Rulebook

**Branch**: `004-in-game-rulebook` | **Date**: 2026-10-14 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/004-in-game-rulebook/spec.md`

## Summary

Add a "How to Play" rulebook: the printed rules rewritten in the project's own words for the digital game, readable in-game from the title screen and the in-game menu. It is an overlay, so it sits above whatever is showing and never touches the game. Opening and closing it mid-turn leaves everything as it was.

- **Content**: lives in a GDScript module beside the Glossary. It has 18 sections in order of play, each with one or more pages that fit the screen whole. Nothing scrolls, matching the project's rule, so spec FR-009 was amended to use pages.
- **Markup**: the text marks Glossary terms, inline icons and numbers drawn from engine constants, so it can't disagree with the engine on those figures.
- **Page layout**: each page has a text column and an aside holding a labelled example card (drawn with the game's own card widgets) or a table. Below the aside, a column of chips opens the existing Glossary popover for each term on the page.
- **Reading position**: kept in a static variable for the session.
- **Tests**: a headless content test, and the existing UI check walking every page at every window size.

## Technical Context

**Language/Version**: GDScript, Godot 4.7.2 (GL Compatibility renderer)

**Primary Dependencies**: Godot engine only. Uses the project's `ui/theme` (tokens, `UI.*` builders), `ui/overlays/overlay.gd`, `ui/model/glossary.gd`, `ui/widgets/card_face.gd`, `encounter_face.gd`, `dragon_stats.gd`, and the engine's `CardDB` and `Game` constants

**Storage**: None. Content is compiled in; the reading position is a session-only static variable

**Testing**: `./tools/test.sh`: the headless unit suite (`tests/run.gd`, new `tests/test_rulebook.gd`) and `tools/ui_check.gd` (extended); `tools/shot.gd` for screenshots

**Target Platform**: Web, Android, iOS (landscape); desktop for development

**Project Type**: Mobile/web game (single Godot project)

**Performance Goals**: Page changes draw within one frame and fade over `T.FAST` (0.15 s); opening the rulebook adds no noticeable delay

**Constraints**: Every page fits the safe content rect at every `Solver.MATRIX` size (tightest: 1248 wide, 665 tall) with no scrolling and no clipped text; text ≥ `T.TEXT_MIN` (22); tap targets ≥ `T.TAP_MIN` (88), help chips ≥ 44; works offline; reduced motion respected; rules text paraphrased, never copied

**Scale/Scope**: About 3,500 words over 18 sections (about 30 pages). One overlay, one widget and one content module are added. Small edits to `main.gd`, `title_screen.gd`, `menu_overlay.gd`, `view_state.gd`, `glossary.gd`, `gen_icons.py`, `ui_check.gd` and `shot.gd`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is the unfilled template: it defines no principles or gates, so there is nothing to violate. **Pass** (no gates defined).

In place of a constitution, the plan holds to the project's working rules, as written in the README, the earlier specs and `tools/ui_check.gd`:

| Project rule | How this plan keeps it |
|---|---|
| The rules engine has no dependency on the interface | No engine changes. The UI reads engine constants only |
| Overlays never change the game | The rulebook is an overlay and reads nothing from `game`, `draft` or `vs` |
| Nothing scrolls; everything fits at every matrix size | Authored pages, verified per page by `ui_check` |
| Minimum tap and text sizes | Chips instead of inline links; `ui_check` extended to rich text |
| Rules text belongs to its owners | Own-words paraphrase; not-verbatim test against the local reference |
| Logic is covered headless | Content helpers are pure statics tested in `tests/test_rulebook.gd` |

**Post-design re-check**: Pass. The design introduces no new projects, dependencies, storage or engine coupling.

## Project Structure

### Documentation (this feature)

```text
specs/004-in-game-rulebook/
├── plan.md              # This file
├── research.md          # Phase 0: design decisions R1–R14
├── data-model.md        # Phase 1: Rulebook, Section, Page, Block, reading position, section outline
├── quickstart.md        # Phase 1: how to validate
├── contracts/
│   └── rulebook-ui.md   # Phase 1: intent, overlay, entry points, figures, verification hooks
├── checklists/
│   └── requirements.md  # From /speckit-specify
└── tasks.md             # Phase 2 (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
ui/
├── model/
│   ├── rulebook.gd           # NEW: SECTIONS content, token expansion, paging helpers, static position
│   ├── glossary.gd           # EDIT: "book" added to NOT_SYMBOLS
│   └── view_state.gd         # EDIT: encounter_model() factored out of _encounter()
├── overlays/
│   ├── rulebook_overlay.gd   # NEW: header, text and aside columns, terms chips, footer, contents, keys
│   └── menu_overlay.gd       # EDIT: How to Play button; buttons in two rows
├── widgets/
│   └── rulebook_figure.gd    # NEW: labelled mage, enemy, journey and dragon examples
├── screens/
│   └── title_screen.gd       # EDIT: How to Play button
└── main.gd                   # EDIT: "rulebook" intent; H key

art/icons/book.svg            # NEW: generated by tools/gen_icons.py (EDIT)

tests/
└── test_rulebook.gd          # NEW: content, coverage, tokens, wording, length, not verbatim

tools/
├── ui_check.gd               # EDIT: walk every page at every size; mid-game no-change check; RichTextLabel checks
└── shot.gd                   # EDIT: rulebook screenshots
```

**Structure Decision**: Single Godot project, following the existing split. Content and its pure logic go in `ui/model/`, next to the Glossary. The view goes in `ui/overlays/` and `ui/widgets/`, built with the `UI.*` helpers. Wiring goes in `main.gd`. Verification goes in `tests/` and `tools/`. `engine/` is not touched.

## Implementation Order

Each step leaves `./tools/test.sh` passing.

1. **Model skeleton**: `rulebook.gd` with helpers (`expand`, `terms`, `step`, `find`, `difficulty_rows`, `position`) and the 18 section stubs, plus `test_rulebook.gd` for structure, tokens and stepping (US1 foundation).
2. **Overlay and entry points**: `rulebook_overlay.gd` (layout, paging, contents, keys); the `rulebook` intent and `H` in `main.gd`; the title and menu buttons; the `book` icon; `ui_check` walking every page, plus the mid-game no-change check (US1 and US2 working, with stub text).
3. **Write the content**: all 18 sections in the project's own words for the digital game, within the page budget, with the coverage, wording, length and not-verbatim tests turned on (US1 and US3). Read each section against the engine (quickstart, Content review).
4. **Terms chips and inline icons**: rich text paragraphs, and `ui_check` extended to `RichTextLabel` (US4).
5. **Figures**: `encounter_model` refactor, `rulebook_figure.gd`, tables, and `shot.gd` screenshots (US4).

## Complexity Tracking

No constitution violations to justify.
