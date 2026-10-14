# Research: Two-Step Game Setup

No item in the Technical Context was left as NEEDS CLARIFICATION. The open questions were design choices within the existing Godot interface, settled below by reading the code that is there today (`ui/screens/title_screen.gd`, `ui/main.gd`, `tools/ui_check.gd`).

## R1. One screen with two steps, or two screens?

- **Decision**: Two screen scripts. `ui/screens/title_screen.gd` becomes the dragon screen (step 1). A new `ui/screens/rules_screen.gd` holds difficulty and alternate rules (step 2). `main.gd` switches between them with its existing `_switch()`.
- **Rationale**: `_switch()` already fades between screens, applies the layout and keeps overlays on their own layer. With two screens, each script owns one layout and the forward/back moves use the same fade as every other change of screen. The title screen already rebuilds itself whenever the dragon changes, so it stays self-contained.
- **Alternatives considered**: A single `title_screen.gd` with a `step` variable that rebuilds its contents. This means one file holding two layouts, a hand-made transition between them, and a `_build()` that branches on the step everywhere. Rejected.

## R2. Where do the choices live while moving between the two screens?

- **Decision**: In `main.menu`, which already means "the options of the game in progress, or to start next". Each screen gets a copy through `setup(db, menu)`, as today. Moving forward or back sends an intent carrying the screen's current options, and `main` stores them in `menu` before showing the other screen. Only `start_game()` writes them to `Settings.last_options`, so nothing is saved before the player sets out, which matches today's behaviour.
- **Rationale**: This needs no new state holder, and both screens start from the same `menu`. Going back can't lose anything, because the options travel in the intent.
- **Alternatives considered**: Saving to `Settings` on every tap. This would change the meaning of "last options" (the choices of the last game played) and would write to disk on every press. Rejected. Keeping a shared reference to one dictionary in both screens. This mutates state across screens without anyone seeing it, unlike the explicit intent payloads used everywhere else. Rejected.

## R3. Intent names

- **Decision**: Two new intents: `{"type": "setup_rules", "options": {...}}` (step 1 → step 2) and `{"type": "setup_dragon", "options": {...}}` (step 2 → step 1). `start`, `to_title`, `settings` and `glossary` stay as they are.
- **Rationale**: Every press already arrives in `main.dispatch()` as a typed dictionary. Each new name says which screen to show next.

## R4. Android system back and the desktop Escape key

- **Decision**: Set `get_tree().quit_on_go_back = false` in `main._ready()` and handle `NOTIFICATION_WM_GO_BACK_REQUEST` in `main._notification()`:
  - If an overlay is open, close it.
  - Otherwise, on the rules screen, go back to the dragon screen.
  - Otherwise, quit, which is what Godot does today on every screen.

  In `_unhandled_key_input`, Escape on the rules screen (no overlay open) does the same as the on-screen Back button.
- **Rationale**: Today no code handles back, so Godot's default (`quit_on_go_back = true`) quits the app from any screen. The spec only requires back to work on the second setup screen (FR-009), so every other screen keeps quitting and play is unaffected. Escape already closes the top overlay first, and the back gesture follows the same order. iOS has no system back. The browser's back button leaves the page, which is unchanged and out of scope.
- **Alternatives considered**: Turning `quit_on_go_back` on and off as screens change. This needs the same notification handling and adds state that is easy to get wrong when overlays are open. Rejected.

## R5. Layout of each screen

- **Decision**:
  - **Dragon screen**: keep the existing two columns. The left column holds the crest, game name, tagline, Settings/Glossary and credits. The right column now holds only "Hunt a dragon": a 2×2 grid of larger dragon tiles that fill the column height, followed by one primary "Continue" button.
  - **Rules screen**: the left column shows the chosen dragon (crest in its Ether colour, name, title and its figures) so FR-006 holds. The right column has "Difficulty" (3×2 grid) and "Alternate rules" (two toggles), and a bottom row with a quiet "Back" button and the primary "Set out" button.
  - Both screens use `ChoiceTile`, `UI.button`, `T.TAP_MIN` and the existing tokens.
- **Rationale**: Both screens keep the current visual language. With the screen split, the dragon tiles get the height that difficulty and the rules used to take, so the art and figures read larger. The two-column frame already passes the UI check at every size in `Solver.MATRIX`, including `upright-browser` and `phone-small`.
- **Alternatives considered**: A step indicator ("1 of 2"). With only two steps, the Continue/Back/Set out labels make the order clear. Left out to keep it simple; easy to add if wanted.

## R6. Focus and keyboard

- **Decision**: The dragon screen focuses "Continue" when built, and the rules screen focuses "Set out". This mirrors today's `start.grab_focus.call_deferred()`. All tiles keep `FOCUS_ALL`.
- **Rationale**: Meets the spec's keyboard and controller edge case, and gives the two-tap replay in SC-001 (Enter, Enter) on desktop too.

## R7. Verification

- **Decision**: Extend `tools/ui_check.gd` so that, at every matrix size, it inspects both the dragon screen and the rules screen for anything off screen. It also runs a forward/back/forward round trip and checks that the options are kept, and that "Set out" starts a game with those options. Add a `rules` shot to `tools/design_shots.gd` after the `title` shot.
- **Rationale**: The headless unit tests (`tests/`) cover model logic. Behaviour of the screens is already covered by the UI check, which drives the real `main.gd`. This feature adds no model logic.
