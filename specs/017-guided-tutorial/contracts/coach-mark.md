# Contract: The Coach Mark

The layer that lights one thing and shows a lesson's message (`ui/overlays/coach_mark.gd`,
research R5, R6).

## Place in the tree

`main` adds it between `_flight` and `_overlays`. Overlays (glossary popover, How to
Play, the menu, inspect, the confirm dialog) open above it. While one is open, the coach
mark stays as it is and takes no input. When the overlay closes, the same message is
still shown (spec edge case). The coach mark is not an `Overlay`: it does not stop the
play clock, does not change `fields_live`, and Esc does not close it.

## Parts

| Part | Look | Input |
|---|---|---|
| Dimming | Read steps: four `ColorRect`s round the lit rect, `Color(T.BG_BASE, T.COACH_DIM)`; the whole view when the target is `screen`. Action steps: none at all (owner review: nothing that must be pressed may look shut) | Read steps: `STOP` (nothing under it can be pressed). Action steps: nothing dimmed, every press goes through |
| Rim | The lit rect grown by `T.COACH_PAD`, outlined `T.FOCUS`, width `T.COACH_RIM`, radius `T.RADIUS_S` | `IGNORE` |
| Bubble | `UI.tooltip_box()`, at most `T.COACH_MAX_W` wide. A `RichTextLabel` of the step's text at `T.BODY` (≥ `T.TEXT_MIN`), then a button row | `STOP` |
| Buttons | Read steps: Skip, Back (when `can_back()`), Next. Action steps: none (owner review), since the way on is the game's own button; a lesson can still be left from the menu. Each `UI.button` at least `T.TAP_MIN` tall, its words on one line | Back → `tutorial.back()`; Next → `tutorial.next()`; Skip → leave the tutorial (tutorial-flow) |
| Press rim | Action steps whose move is made with the screen's own button (`dragon`, `setup`, `play`, `soak`, `upgrade`): that button (Continue, Confirm, Play) gets the rim too, and the bubble keeps clear of it | — |
| Glossary links | `[[term]]` rendered as meta links | Pressing one opens the glossary popover anchored at the link, through `main.dispatch({"type": "help", …})` |

## Target vocabulary

`play_screen.coach_rect(target) -> Rect2` (global). An unknown target, or one whose node
is not present (for example `key` while the Key Card is not raised), returns an empty
rect. The mark then lights nothing and centres the bubble; `test_lessons` and the UI walk
make sure no shipped step relies on that.

| Target | Lit |
|---|---|
| `screen` | Nothing |
| `deck` | The top card of the Deck |
| `key` | As built (tasks T023, the fallback): the reading strip under the landed Encounter, which names it and its Hardship as the Key Card's strip did when it rose |
| `encounter` | The landed Encounter panel |
| `chip:<name>` | One figure of that panel: `hp`, `initiative`, `attack`, `armor0`, `mp`, `time`, `xp` |
| `card:<id>` | A Hand card |
| `card:<id>+<id>` | The rect spanning both cards |
| `hand` | The whole Hand well |
| `ether:<id>` | That card's Ether sigil |
| `place:<key>` | A place label: `0/spell`, `0/element`, `0/boost`, `reserve` |
| `aim` | The Boost target box |
| `primary` | The primary button |
| `action:<id>` | A secondary button: `fuse`, `divert` |
| `picker` | The Fuse Ether picker |
| `soak`, `xp` | The Soak meter, the XP purse |
| `dragon:<id>` | (Dragon screen) that dragon's tile |

## Placement

The bubble goes beside the lit rect, on the side with the most room inside
`plan.content`, `T.COACH_GAP` from the rim, and is clamped inside `plan.content`. It
never covers the lit rect. If no side has room, it goes over the far half of the screen
from the lit rect. Placement is recomputed on every `apply_layout` (resize, rotation,
safe-area change) and after every animator step that moves the target.

## Timing

- A new step's mark appears when the animator is idle. While a sequence plays, the
  mark is hidden and input passes to the skip as usual.
- Appear: fade `T.COACH_FADE`. Moving to another target: the rect and bubble tween
  `T.MOVE`.
- Reduced motion: no tween and no fade. The mark is shown in place.

## Refusals

A move that the gate holds back calls `main._refuse(hint, card_id, "Lesson")`: the
existing refusal card on the Deck, haptics and shake. The coach mark stays on the same
step.

## UI check invariants (`lessons` walk)

- Every bubble lies inside the view and the safe area, and passes `_inspect_screen`
  (text ≥ 22, buttons ≥ 88).
- The rim contains its target's node rect and lies inside the view.
- The bubble does not overlap the lit rect.
- The checks hold with reduced motion on, and at every window size in full mode.
