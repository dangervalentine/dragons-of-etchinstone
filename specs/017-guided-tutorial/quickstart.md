# Quickstart: Guided Tutorial (Learn to Play)

How to check the feature once it is built. Commands run from the repository root with
the Bash tool.

## Automated

```sh
tools/test.sh unit game lessons tutorial    # stage(); every lesson's outcome, proved exhaustively; the gate and progress
tools/test.sh ui lessons                    # all six lessons through the real screens at phone-16x9, still and animated
tools/test.sh ui full lessons screens       # every window size (the coach mark is sized by the window)
tools/test.sh                               # quick: everything, before calling it done
tools/test.sh full                          # before a commit
```

Expected:

- `test_lessons`: for each lesson, the outcome in [research.md](research.md) R1
  (Victory 11/11; Narrow 9/12 with 2 cards paid; Loss 6/13 with 3 damage Soaked by
  Fleet Footed; Fuse Victory 10/9 where the best without a Fuse is Narrow; Region 2
  dealt with Hand 4 and Deck 12). Every FR-012 concept is covered, and every
  `[[term]]` and target is known.
- `lessons` walk:
  - no refusal except the one wrong commit it makes on purpose in each Encounter
    lesson;
  - `HistoryStore` record count and marker unchanged;
  - lesson progress written only to the tool settings path.

## By eye

```sh
godot --path .
```

1. **Fresh install.** Remove `user://settings.cfg` and `user://history.json`.
   1. Press **Play**: the offer dialog appears. Choose **Learn to Play**.
   2. The dragon screen opens with Rodving chosen and the others locked, each with the
      lesson line. Continue goes straight to the five offered cards; Destruction is
      lit.
   3. Pick another card and confirm: a "Lesson" refusal card appears on the Deck.
   4. Pick Destruction: Lesson 1 is complete.
2. **Lesson 2.**
   1. Step through the Deck, Key Card, Encounter, Ether and Roles messages.
   2. Press **Back** once: the previous message and its light return.
   3. Press a `[[term]]`: the Glossary popover opens above the mark; close it, and the
      same message is still there.
   4. Commit without swapping: refused. Swap, commit: Victory 11 against 11.
   5. Upgrade Rain of Blood, then finish.
3. **Lesson 3**: Narrow Victory, two cards fly off the Deck, and the clock message
   shows.
4. **Lesson 4**: Loss, Soak with Fleet Footed. Choosing Brute Force instead is refused.
5. **Lesson 5**: Fuse Sword of Light over Destruction as fire. Fusing as water, or not
   at all, is refused. Victory 10 against 9.
6. **Lesson 6**: the Region ends after Cleanup and Region 2 is dealt. Finish shows the
   summary.
7. **The list.**
   1. Leave from the summary, then press **Learn to Play** again: the list shows all
      six Done.
   2. Replay Lesson 4 and leave half way: it is still Done.
8. **Records**: open them. No game was recorded.
9. **Reduced motion** (menu → Motion → Reduced): replay Lesson 2. The marks appear in
   place with no fades.
10. **Resize** the window mid-message (desktop): the rim and bubble follow their target.

## Screenshots

```sh
godot --path . -s tools/shot.gd -- build/screenshots/matrix
```

The shot tool gains one lesson message per lesson type: a read step and an action
step.
