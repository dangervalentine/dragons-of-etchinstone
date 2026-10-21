# Implementation Plan: Guided Tutorial (Learn to Play)

**Branch**: `017-guided-tutorial` | **Date**: 2026-10-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/017-guided-tutorial/spec.md`

## Summary

Six lessons, each a staged moment of a real game played on the real screens under the
real rules, with a coach mark that lights one thing at a time and explains it.

- **The tables exist and are proved** (R1). Every lesson's table was found by searching
  all Region 1 Key Cards and Hands. Each was then run through `engine/game.gd`, with
  every Action Set and Fuse enumerated:
  - Victory 11 vs 11;
  - Narrow 9 vs 12, paying 2 cards;
  - Loss 6 vs 13, with 3 damage Soaked;
  - Victory 10 vs 9 that only a Fuse wins;
  - a Region that ends at Cleanup and deals Region 2.

  The setup lesson's pick, Destruction at Level 3, is the card that wins the first
  fight.
- **The engine stages a table** (R2). `Game.stage(table)` validates and sets the piles,
  the Levels and the phase. The lesson data lives in the UI, not the engine.
- **The lessons are data** (R3). `ui/model/lessons.gd` is a `const` script in Rulebook
  markup, with Glossary links.
- **A pure tutorial model gates commits** (R4). `ui/model/tutorial.gd` holds the step,
  Back and the gate. `main` asks it at the commit points it already has, and a wrong
  move becomes the existing refusal card, titled "Lesson".
- **A coach mark lights the target** (R5, R6). A new layer under the overlays: four-rect
  dimming, a rim, and a bubble. `play_screen.coach_rect(target)` resolves a small
  target vocabulary.
- **Entry, list and progress** (R7, R8):
  - Learn to Play on the title; a lesson list; the dragon screen in lesson mode
    (Rodving only, no difficulty screen);
  - progress kept in `Settings.progress`;
  - no history records;
  - a one-time offer on the first Play press.
- **Proof** (R9). Exhaustive engine tests of every lesson, a model test of the gate and
  progress, and a `lessons` UI walk at every window size.

## Technical Context

**Language/Version**: GDScript, Godot 4.7.2 (standard build, GL Compatibility)

**Primary Dependencies**: none new. Reused:
- `Game`, `ViewState`, `TurnDraft`, `Sequencer` and `Animator`;
- `Rulebook.expand` and the glossary popover;
- `ConfirmDialog`, `UI.tooltip_box`/`UI.button`;
- the Deck's refusal card.

**Storage**: `user://settings.cfg` (section `progress`: `lessons`, `tutorial_done`,
`tutorial_offered`). No history writes during lessons.

**Testing**:
- `tools/test.sh unit game lessons tutorial` (new `test_lessons`, `test_tutorial`);
- `tools/test.sh ui lessons` (new walk), plus `screens` for the title and lesson list.

**Target Platform**: Web, Android and iOS (landscape), and desktop; touch, mouse and
keyboard.

**Project Type**: Single-player card game (Godot app).

**Performance Goals**:
- 60 fps while a coach mark is shown: four rects, a rim and a bubble.
- A lesson starts in under 1 s plus its deal animation.

**Constraints**:
- No rule changes.
- `engine/` holds no tutorial content.
- Text ≥ `TEXT_MIN` 22; taps ≥ `TAP_MIN` 88.
- Reduced motion has a still form.
- The coach mark works at every `layout_solver.MATRIX` size.
- Tools never write the player's progress or history.

**Scale/Scope**:
- 6 lessons, about 50 steps.
- 4 new source files:
  - `ui/model/lessons.gd`
  - `ui/model/tutorial.gd`
  - `ui/overlays/coach_mark.gd`
  - `ui/screens/lessons_screen.gd`
- About 9 changed files: `game.gd`, `main.gd`, `play_screen.gd`, `dragon_screen.gd`,
  `title_screen.gd`, `settings.gd`, `deck_stack.gd`, `card_view.gd` and `tokens.gd`.
- 2 new test files and 1 new UI walk.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template, so there are no formal
gates. The project's established conventions apply:

| Convention | Status |
|---|---|
| The engine is the only judge of rules; `engine/` never preloads `ui/` | Pass. `stage()` is generic and validated, the lessons live in `ui/model`, and every outcome comes from `Game.play`/`soak`/`finish` |
| Only `view_state.gd` reads engine internals | Pass. The UI stages through `stage()`. The gate compares `draft.to_action()`, not engine fields. `coach_rect` reads widgets, not the game |
| Pure models are tested headless | Pass. `lessons.gd` and `tutorial.gd` are `RefCounted`/const and are covered by `test_lessons` and `test_tutorial` |
| The Sequencer is pure; `skip()` settles on the after state | Pass. No new step kinds. A lesson's deal is the existing start sequence, and the coach mark waits for the animator |
| Every screen is checked at every `MATRIX` size; tap ≥ 88, text ≥ 22 | Pass. The `lessons` walk runs at every size in full mode, and `_inspect_screen` covers the coach layer and the lesson list |
| Reduced motion is first class | Pass. The coach mark has no tween or fade when reduced, and the walk runs it |
| Never colour alone | Pass. The lit target has a rim and the dimming; "Done" is an icon and a word |
| Tools never write the player's records | Pass. `HistoryStore.use_empty` is already used, and `Settings` gains a path override for the tools |
| README "Rules interpretations" updated when engine decisions change | N/A. No rule changes |

Re-checked after Phase 1: no violations. Four new files, each its own concern: data, a
model, a layer, a screen.

## Project Structure

### Documentation (this feature)

```text
specs/017-guided-tutorial/
├── spec.md
├── plan.md              # This file
├── research.md          # Phase 0: R1–R10 (R1 holds the verified lesson tables)
├── data-model.md        # Phase 1: Table, Lesson, Step, Tutorial, Progress
├── quickstart.md        # Phase 1: tests, by-eye walk-through, shots
├── contracts/
│   ├── lessons.md       # Every lesson step by step, concepts covered
│   ├── coach-mark.md    # The layer, the target vocabulary, placement, timing, checks
│   └── tutorial-flow.md # Intents, start_lesson, list, completion, first-launch offer
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
engine/game.gd                  # stage(table) -> String (R2)
ui/model/
├── lessons.gd                  # NEW: const LESSONS, the six tables and their steps (R1, R3)
├── tutorial.gd                 # NEW: step/next/back/check/acted/sequence_done; first_unfinished, is_open (R4, R8)
└── settings.gd                 # progress.lessons, tutorial_done, tutorial_offered; path override (R8)
ui/overlays/coach_mark.gd       # NEW: dimming, rim, bubble, buttons, glossary links (R5)
ui/screens/
├── lessons_screen.gd           # NEW: the lesson list (R7)
├── title_screen.gd             # Learn to Play button
├── dragon_screen.gd            # lesson mode: Rodving only; Continue → lesson_setup
└── play_screen.gd              # coach_rect(target) (R6)
ui/widgets/
├── deck_stack.gd               # public getter for the Key strip rect
└── card_view.gd                # public getter for the Ether sigil rect
ui/theme/tokens.gd              # COACH_* tokens
ui/main.gd                      # tutorial + coach layer; start_lesson; gate at commit points; no records in lessons; first-launch offer; lesson intents
tests/
├── test_game.gd                # stage() valid / refused
├── test_lessons.gd             # NEW: each lesson's outcome, exhaustive; steps' targets, terms, concepts
└── test_tutorial.gd            # NEW: gate, Back floor, progress
tools/
├── ui_check.gd                 # NEW lessons walk; coach layer inspected; tool Settings path
├── shot.gd                     # a read step and an action step per lesson type
└── test.sh                     # walk list comment
README.md, CLAUDE.md            # Learn to Play line; walk and unit tables
```

**Structure Decision**: the existing single Godot project layout. Each new file sits
beside its kind: a model in `ui/model`, a layer in `ui/overlays`, a screen in
`ui/screens`. Every other change lands in the file that already owns that concern.

## Phase 0: Research

See [research.md](research.md). There are no open NEEDS CLARIFICATION items. Decisions:

- **R1**: the six verified tables.
- **R2**: `Game.stage`.
- **R3**: lessons as a const script in Rulebook markup.
- **R4**: the tutorial model and gate at the commit points.
- **R5**: the coach-mark layer.
- **R6**: the target vocabulary.
- **R7**: entry, the lesson list, dragon lesson mode, dealt order.
- **R8**: progress, no records, the first-launch offer, the tool settings path.
- **R9**: tests and the walk.
- **R10**: documents.

Findings made while planning:

- **Lesson 2 needs one card at Level 3.** No Level-2 Hand gives a single,
  Ether-dependent Victory with a faster Element and the Boost on Attack. A Level 3
  Destruction does, which is why Lesson 1 recommends raising it.
- **Normal difficulty has no setup step.** Its setup is 5 cards offered, 0 chosen.
  Lesson 1 therefore stages its own setup (5 offered, 1 chosen, to Level 3) rather than
  borrowing a difficulty.
- **Dealt order is placement.** The Hand's dealt order fills Reserve, Element, Spell
  and Boost. Lessons 3–6 are dealt already in place; Lesson 2 is dealt with Spell and
  Boost swapped, so the player makes one swap.
- **Settings has no tool redirect.** The UI walk would otherwise write the player's
  lesson progress. A path override is added (R8).

## Phase 1: Design

- [data-model.md](data-model.md): the Table accepted by `stage()`, Lesson, Step, the
  Tutorial model, Progress, and the changes to existing state.
- [contracts/lessons.md](contracts/lessons.md): every lesson, step by step, with
  targets, waits, guided moves, hints and FR-012 concepts.
- [contracts/coach-mark.md](contracts/coach-mark.md): the layer's parts and input, the
  target vocabulary, placement, timing, refusals and UI-check invariants.
- [contracts/tutorial-flow.md](contracts/tutorial-flow.md): intents, `start_lesson`,
  lesson complete and the summary, the list, the first-launch offer, and what a lesson
  never does.
- [quickstart.md](quickstart.md): test commands, the by-eye walk-through and shots.

## Risks

- **A staged start through the existing deal sequence.** `Sequencer.build(empty, start)`
  has only dealt from a full Deck. Lesson 6 starts with 11 cards in the discard pile,
  and the deal must draw the discard pile as it is. Mitigation: the `lessons` walk
  settles every lesson's start, and `skip()` must land on the staged table (the existing
  skip invariant).
- **The Key strip is only raised during a reveal.** Lighting `key` needs the Key Card
  raised while the message shows. Mitigation: the step raises it with the existing look
  path, and lowers it on Next. If that reads badly, the step lights the Deck and the
  message describes the strip.
- **The gate versus free arrangement.** A player may reach the guided set by a different
  route, for example swapping twice. Gating compares only the committed action, so any
  route passes.
- **The unspent-XP dialog during lessons.** Lessons 3, 5 and 6 earn XP that is not
  guided. The dialog is kept, since unspent XP is taught in Lesson 2. If play-testing
  finds it noisy, it can be suppressed while a tutorial is attached.
- **Text length on the smallest phone.** Some messages carry figures and links. The
  walk's text-fit check at phone-small is the guard; messages are split into two steps
  rather than shrunk.
- **Card-data drift.** If `data/cards.json` is ever corrected, a lesson may stop working.
  `test_lessons` fails, and the search in R1 is the recipe for finding a new table.

## Complexity Tracking

No violations to justify.
