# Contract: Getting In, Moving Through and Getting Out

Navigation and persistence around the lessons (research R7, R8).

## Intents (handled in `main.dispatch`)

| Intent | From | Effect |
|---|---|---|
| `{"type": "lessons"}` | Title: Learn to Play | No lesson finished: `start_lesson(0)`. Otherwise: show the lesson list |
| `{"type": "lesson", "index": i}` | Lesson list | `start_lesson(i)` if `Tutorial.is_open(i, done)` |
| `{"type": "lesson_setup"}` | Dragon screen in lesson mode: Continue | Stage Lesson 1's setup table on the play screen |
| `{"type": "lesson_next"}` | Lesson-complete bubble | `start_lesson(i + 1)`, or the summary after the sixth |
| `{"type": "lesson_list"}` | Lesson-complete bubble, the summary | Show the lesson list |
| `{"type": "lesson_leave"}` | Skip; the in-game menu's Leave during a lesson | Detach the tutorial and show the title. No confirm dialog: nothing of the player's is lost |

## `start_lesson(i)`

1. If a real game is in memory and running, record it as abandoned, as `start_game`
   does.
2. Lesson 1: show the dragon screen in lesson mode, with the tutorial attached.
3. Lessons 2–6:
   - `game = Game.new(db, {"dragon": "rodving", "difficulty": "normal", "seed": 0})`;
   - `game.stage(lesson.table)` (a failure is a bug, caught by `test_lessons`);
   - reset the draft;
   - build the play screen;
   - play the start sequence (the deal), as `start_game` does;
   - attach the tutorial and show the first step once the animator is idle.

Neither `Settings.last_options` nor the history marker is written.

## Lesson complete and the summary

When `tutorial.finished()`:

1. `id` is added to `Settings.lessons` and saved.
2. The coach mark shows a bubble over a dimmed screen: "Lesson N complete", with **Next
   lesson** (or **Finish** after the sixth), **Lessons** (the list) and **Leave**.
3. After the sixth, **Finish** shows the summary:
   - what the lessons covered;
   - what a full game holds (four Regions, then the Final Journey and the Final Enemy,
     the dragon);
   - **Leave** and **Lessons** buttons.

   Showing it sets `Settings.tutorial_done`.

## Lesson list (`ui/screens/lessons_screen.gd`)

- A heading, then the six lessons in order. Each row shows:
  - its number and title;
  - a finished mark (an icon and the word "Done", never colour alone);
  - its state: open (a button) or not yet open (dimmed, with the line "Finish Lesson N
    first").
- A primary button: "Continue: Lesson N" for the first unfinished lesson; "Start again"
  once all are finished, which opens Lesson 1 and leaves the marks in place.
- `back()` returns to the title.
- Replaying a finished lesson never removes its mark. Leaving any lesson part way
  changes no mark.

## First-launch offer

When Play is pressed on the title with `HistoryStore.records.is_empty()`,
`Settings.lessons.is_empty()` and not `Settings.tutorial_offered`:

- a `ConfirmDialog`: "New to Etchinstone? Learn to Play takes about ten minutes.";
- buttons: **Learn to Play** (the `lessons` intent) and **Play** (the usual dragon
  screen);
- either way, `tutorial_offered` is set and saved;
- closing the dialog any other way plays nothing and also sets `tutorial_offered`.

## What a lesson never does

- Write a history record or marker (`_record`, `_save_marker` return at once).
- Change `Settings.last_options` or `Settings.unlocked`.
- Show the difficulty screen, turn on an alternate rule, or show or record a difficulty
  (FR-009). The staged setup of Lesson 1 belongs to no difficulty.
- Allow Divert, or Fuse outside Lesson 5. Both are refused with "Not in this lesson."
