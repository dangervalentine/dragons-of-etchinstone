# Data Model: Guided Tutorial (Learn to Play)

Phase 1 for [plan.md](plan.md). The new types are plain dictionaries in `const` data
or fields of pure `RefCounted` models. No engine data changes; `data/cards.json` is
untouched.

## Table (input to `Game.stage`)

A staged moment of a game, read by `engine/game.gd` (research R2).

| Field | Type | Rule |
|---|---|---|
| `phase` | String | `"setup"` or `"challenge"` |
| `region` | int | 1–4 |
| `levels` | {card id: int} | Levels 1–4; cards not listed are Level 2 |
| `deck` | Array[id] | Index 0 is the Key Card; non-empty in `challenge` |
| `hand` | Array[id] | At most `HAND_SIZE` (4) cards; the dealt order, which is also the places' order |
| `discard` | Array[id] | May be `"rest"`: every card not otherwise placed, in id order |
| `trash` | Array[id] | Usually empty |
| `setup_offer` | Array[id] | `setup` only: the cards offered |
| `setup_picks` | int | `setup` only: how many to choose, from 1 up to one less than the offer size |
| `setup_level` | int | `setup` only: the Level the chosen cards are set to |

Validation (`stage()` returns a message and changes nothing on failure):

- every Mage Card id appears exactly once across `deck`, `hand`, `discard` and `trash`;
- for `setup`, every card is in `deck` and `setup_offer` is a subset of it;
- for `challenge`, `deck` has a Key Card.

On success `stage()` also resets the per-Encounter state:

- `xp`, `diverts`, `damage_due` → 0;
- `damage_element` → "";
- `downgraded` → [];
- `result`, `faced`, `_action` → {};
- `_pending_poison`, `carried_damage` → 0;
- `_regrouped` → false.

## Lesson (`ui/model/lessons.gd`, `const LESSONS`)

| Field | Type | Meaning |
|---|---|---|
| `id` | String | `setting_out`, `victory`, `narrow`, `loss`, `fuse`, `region_end` |
| `title` | String | Shown in the lesson list and the lesson-complete bubble |
| `table` | Table | The staged table. For `setting_out`, the setup table |
| `outcome` | String | `setup`, `complete`, `narrow`, `loss`, `fuse_complete`, `region_end`. This is what the lesson test proves |
| `steps` | Array[Step] | In order |

The six tables are research R1's, expressed in this shape. For `setting_out`, the dragon
screen comes first: its steps carry `"screen": "dragons"` until the setup table is
staged.

## Step

| Field | Type | Meaning |
|---|---|---|
| `text` | String | Rulebook markup: `[[term]]`, `[[term\|label]]`, `{icon:…}`, `{n:CONST}` |
| `target` | String | What to light. Vocabulary in [contracts/coach-mark.md](contracts/coach-mark.md); `"screen"` lights nothing |
| `wait` | String | `next` (a read step, with a Next button), or an action kind: `dragon`, `setup`, `arrange`, `play`, `soak`, `upgrade`, `fuse_begin`, `fuse_element`, `sequence` |
| `expect` | Dictionary | For action steps, the guided move (shapes below) |
| `hint` | String | Shown as the refusal when the move differs (FR-013, FR-014) |
| `concepts` | Array[String] | FR-012 concept ids this step explains. The lesson test checks every concept is covered |

`expect` shapes:

| `wait` | `expect` | Matches when |
|---|---|---|
| `dragon` | `{"dragon": "rodving"}` | Continue is pressed with Rodving chosen |
| `setup` | `{"picks": [id]}` | The picks are the same set |
| `arrange` | `{"places": {"0/spell": id, …}}` | The draft's places hold those cards. This step advances by itself; it never refuses |
| `play` | `{"spell", "element", "boost", "boost_to", "fuse"?}` | `draft.to_action()` equals it, ignoring `ranged_discard`, with a missing `boost_to` read as `attack` |
| `soak` | `{"picks": [id]}` | The same set |
| `upgrade` | `{"picks": [id, …]}`, or `{}` | The Upgrade Phase's single confirm press. The Upgrades and Cleanup are one commit in `main` (`_on_primary` → `_finish_upgrade` → `game.upgrade` per pick, then `_act(finish)`). With `picks`, the draft's picks must be the same multiset (one entry per Level); with `{}`, any picks, including none, pass |
| `fuse_begin` | `{}` | The Fuse button is pressed |
| `fuse_element` | `{"top", "bottom", "element"}` | The draft's fuse equals it |
| `sequence` | `{}` | Advances when the animator finishes (or at once if the move set off none); used to wait out a reveal, a result or a Region change. No mark shows while it plays, so what to say about it is the next step's |

## Tutorial (`ui/model/tutorial.gd`, one per lesson run)

| Field | Type | Meaning |
|---|---|---|
| `lesson` | Lesson | The lesson being played |
| `index` | int | The current step |
| `floor_index` | int | The lowest index Back can return to: the step after the last action taken (named so as not to shadow GDScript's `floor()`) |

| Method | Returns | Behaviour |
|---|---|---|
| `step()` | Step | `lesson.steps[index]` |
| `next()` | void | Read steps only: `index += 1` |
| `back()` | void | `index -= 1` if `index > floor_index` |
| `can_back()` | bool | `index > floor_index` |
| `check(kind, payload)` | String | "" if `kind` is the step's `wait` and `payload` matches `expect`; otherwise the step's `hint`. A commit of a kind the step does not wait for returns a generic "Not yet: [current instruction]". Divert and Fuse outside a step that waits for them are refused with "Not in this lesson." |
| `acted(kind)` | void | After a successful move of the awaited kind: `index += 1`, `floor_index = index`. For `upgrade`, `main` calls it once, after `_act(finish)` succeeds; for `dragon`, from the `lesson_setup` handler |
| `sequence_done()` | void | Advances a `sequence` step |
| `draft_changed(draft)` | void | Advances an `arrange` step once its places match |
| `finished()` | bool | `index == steps.size()` |

State: `reading` (the step's `wait` is `next`) → `awaiting` (an action kind) →
`acted` → the next step … → `finished`, which shows the lesson-complete bubble.

## Progress (`ui/model/settings.gd`, section `progress`)

| Key | Type | Default | Meaning |
|---|---|---|---|
| `unlocked` | Array | [] | Existing; unchanged |
| `lessons` | Array[String] | [] | Lesson ids finished, in any order. Load-time filter: known ids only |
| `tutorial_done` | bool | false | Set when the summary shows after the sixth lesson |
| `tutorial_offered` | bool | false | The first-launch offer has been shown |

Derived, in `tutorial.gd` as statics:

| Function | Returns |
|---|---|
| `first_unfinished(done)` | The index of the first lesson not in `done`, or -1 once all are |
| `is_open(i, done)` | `i <= first_unfinished(done)`, or `true` once all are done |

`Settings` also gains a `path` override, a static var defaulting to `PATH` and set by
tools, so checks never write the player's progress (research R8).

## Changes to existing state

| Owner | Change |
|---|---|
| `engine/game.gd` | `stage(table) -> String` |
| `ui/main.gd` | `tutorial` (a Tutorial or null), `coach` (the CoachMark layer); `start_lesson(i)`; while `tutorial` is set, `_save_marker` and `_record` return at once; gate calls at `_on_primary` (setup, play, soak, and the Upgrade Phase's confirm), `_confirm_mode`, `_on_action("fuse")` and the `fuse_element` intent; `acted` and `sequence_done` after `_act` and `_on_sequence_done` |
| `ui/screens/dragon_screen.gd` | `lesson` flag: every dragon but Rodving locked with the lesson line; Continue emits `lesson_setup` |
| `ui/screens/title_screen.gd` | A Learn to Play button emitting `lessons` |
| `ui/screens/lessons_screen.gd` | New: the lesson list |
| `ui/screens/play_screen.gd` | `coach_rect(target) -> Rect2` |
| `ui/widgets/deck_stack.gd`, `card_view.gd` | Public getters for the Key strip and the Ether sigil rects |
| `ui/theme/tokens.gd` | `COACH_DIM`, `COACH_PAD`, `COACH_RIM`, `COACH_GAP`, `COACH_MAX_W`, `COACH_FADE` |
| `ui/model/settings.gd` | `use_path(p)`, and `use_for_tools()`: the walks' and shot tools' own settings file, fresh, with the first-launch offer already made |
