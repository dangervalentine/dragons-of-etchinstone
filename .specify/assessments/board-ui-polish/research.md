# Idea Research: Board, Zone and UI Personality Polish

- **Slug**: board-ui-polish
- **Created**: 2026-10-15
- **Evidence confidence (overall)**: medium. The repo has a lot of internal evidence (specs,
  code, screenshots). There is no outside evidence: no playtest data, no user feedback,
  and no external sources were fetched.

## Users & Demand

- The only signal so far is the owner's own ask: "a concentrated effort at improving
  the layout of the game board, the zones, the ui, to give it personality and polish"
  — [source: `intake.md`] (confidence: high that the owner wants it; low for any other user)
- The audience looks like the owner plus people who own or know the physical game.
  This is a fan-made digital version: "Fan-made digital version. Game by Joe Klipfel,
  published by Chip Theory Games. Not affiliated…" — [source: title screen,
  `build/screenshots/android.png`] (confidence: high)
- No playtest findings exist yet. Feature 005's observer checks (3-second Hand focus,
  5-second first look, before/after "which looks more finished", owner recognition)
  are still open as T045. Feature 001's hand walkthrough (T084) is also open — [source:
  `specs/005-playfield-polish/tasks.md:164`, `specs/001-ui-polish/tasks.md:261`]
  (confidence: high)
- This is the third presentation pass in three days. 001 "UI Polish and Presentation
  Overhaul" was created 2026-10-13 and 005 "Playing Field and Card Polish" 2026-10-14.
  That looks like strong, sustained owner interest in how the game looks — [source:
  `specs/001-ui-polish/spec.md`, `specs/005-playfield-polish/spec.md`, git log]
  (confidence: high for the fact; ASSUMPTION on what it means)

## Prior Art

- **Internal: 001-ui-polish** (97/100 tasks done). Moved the game from a single scrolling
  column of text and buttons to a fixed landscape layout, with animation and a theme
  token system. Still open: device performance (T082), all-target build checks (T083)
  and a hand walkthrough (T084) — [source: `specs/001-ui-polish/tasks.md`]
- **Internal: 005-playfield-polish** (43/45 tasks done). Added step-aware highlighting of
  card parts, Ether field shaders on cards and less density on the field. It explicitly
  left the title, rules and ending screens out of scope and kept 001's layout
  assumptions — [source: `specs/005-playfield-polish/spec.md:359-376`, `tasks.md`]
  - Its stated problems included "Regions sit close together with similar weight, so
    the eye has no obvious starting point" and "Colours are flat". Today's screenshots
    suggest the zone-weight problem is only partly solved (see Data & Constraints).
- **Internal: recent commits on 003-dragon-art.** Final Battle road, Reserve and Soak
  polish; card faces and icons matched to the official cards; hover help; haptics;
  a dragon-head app icon — [source: git log `cc19722`…`6b26031`]
- **Internal: an art pipeline exists.** 37 creature and landscape silhouettes in one
  "heraldic woodcut" linocut style, tinted by Ether at runtime and animated by
  `creature_idle.gdshader`. Generation runs on the Windows PC (ComfyUI) — [source:
  `art/STYLE_PROMPT.md`, `tools/generate_art.py`, memory note on Windows-PC art]
- **Internal: physical reference material.** `reference/` holds the rulebook PDF,
  official card scans and a "pixel-card-variant" PDF. Those are possible sources for
  the physical game's look — [source: `reference/`] (contents not reviewed for this note)
- **External:** not researched. No external pages were fetched. Board-game adaptations
  often take their personality from a "table" metaphor (playmat, wood, felt) or from
  the source game's trade dress — ASSUMPTION (confidence: low; general knowledge, uncited)

## Market & Context

- What players use today is the current build. It is fully playable and already has a
  coherent dark theme, so doing nothing costs presentation, not function — [source:
  `specs/001-ui-polish/spec.md` Context; matrix screenshots]
- There is no commercial or distribution context. It's a fan project and nothing says it
  will be published; distribution so far is local emulator, simulator and web builds —
  [source: `install-on-emulators` skill description; title-screen disclaimer] (confidence: medium)

## Data & Constraints

- **The look today** (from `build/screenshots/matrix/desktop/05_challenge_assigned.png`,
  `12_final_journey.png`, `build/design-shots/20_region_banner.png`; captured
  2026-10-14, *before* commits `6b26031`…`cc19722`, so slightly stale):
  - The background is a near-black (`BG_BASE #100e17`). A full-screen
    `backdrop.gdshader` lightens the middle, darkens the edges and adds a faint Ether
    tint at top left. There is no texture, board or table surface — [source:
    screenshots; `ui/theme/tokens.gd`; `ui/fx/shaders/backdrop.gdshader`; `ui/main.gd:74`]
    (confidence: high)
  - Every zone (Encounter, preview, slots, Hand, action bar) is the same kind of
    rounded dark panel (`BG_SURFACE`/`BG_RAISED`, `RADIUS_M 14`). Nothing frames the
    zones as places on a board — [source: screenshots; `tokens.gd`]
  - There are visible dead areas: the preview panel's lower half in
    `05_challenge_assigned` and a band between the slot row and the Hand.
    (confidence: medium; one screen size)
  - The personality lives mostly in the cards (Ether shaders, official-style faces)
    and the creature art. The chrome around them is neutral — ASSUMPTION based on
    the screenshots (confidence: medium)
  - The type pairing is Cinzel (display) and Alegreya Sans (body) — [source: `art/fonts/`]
- **Layout constraints:**
  - Landscape only. 1280×720 minimum design units, growing to 1760×990.
  - Seven fixed regions are computed by a pure `layout_solver.gd`.
  - The layout is checked across an 8-entry window matrix (phone, tablet, desktop,
    ultrawide, upright browser) — [source: `ui/model/layout_solver.gd`,
    `ui/screens/play_screen.gd:3`]
- **Legibility floors:** `TAP_MIN 88`, `TEXT_MIN 22`. Contrast is checked by WCAG ratio
  in tokens and tests — [source: `tokens.gd`, `tests/test_card_contrast.gd`]
- **Performance:** the GL Compatibility renderer is used on all targets, including web.
  Feature 005's weak-device check (T043) and 001's frame-time check (T082) were never
  run on a phone. So the cost of adding shaders or textures on low-end targets is
  unknown — [source: `project.godot`, `specs/005-playfield-polish/tasks.md:162`]
- **Size of the work surface:** the UI is about 8,400 lines of GDScript across
  screens, widgets, overlays, model and fx. The biggest pieces are `card_face.gd`
  (759), `main.gd` (648) and `view_state.gd` (554) — [source: `wc -l ui/**/*.gd`]
- **Tooling already in place:** `tools/shot.gd` and `tools/design_shots.gd` for
  screenshots, `tools/ui_check.gd` for layout checks, `tools/field_bench.gd` for
  performance — [source: `tools/`]
- **IP and legal:** this is a fan version of a commercial game. Leaning harder into
  the physical game's trade dress (for personality) raises the question of copying
  more of the publisher's look — ASSUMPTION (confidence: low; no legal review)

## Evidence Against the Idea

- **Diminishing returns and churn.** This would be the third presentation pass in about
  three days. The earlier passes still have open verification tasks (device
  performance, hand walkthroughs, observer checks). Starting another before those
  results exist means designing without feedback on what the last two achieved —
  [source: 001/005 `tasks.md`]
- **"Personality" is not yet defined.** Without a direction (theme, references, mood),
  the work risks becoming open-ended taste iteration with no finish line — [source:
  `intake.md` unknowns] (ASSUMPTION about the risk)
- **Performance risk.** Textures, backgrounds and more shader work on top of 005's
  animated Ether fields could hurt weak phones and the web build. That budget has
  never been measured on a device — [source: 005 T043, 001 T082]
- **Layout lock-in.** The fixed seven-region solver and its 8-size test matrix make
  changes to the zones' structure costlier than restyling them — [source:
  `layout_solver.gd`]
- **Art dependency.** A board or table look may need new raster or vector art. That
  can only be generated on the Windows PC, which adds a hand-off step — [source:
  memory note; `tools/generate_art.py`]

## Gaps & Open Questions

- [NEEDS CLARIFICATION: What specifically feels unpolished or lacking in personality
  in the *current* build (after `cc19722`)? Fresh screenshots would settle this; the
  newest matrix shots are from before the last five commits.]
- [NEEDS CLARIFICATION: Direction for "personality": the physical game's look
  (playmat, card trade dress), the "Etchinstone" etched-stone or woodcut theme that the
  creature art already uses, or something else? Any reference images?]
- [NEEDS CLARIFICATION: Should 005's observer checks (T045) and the device performance
  checks run first, to give a baseline?]
- [NEEDS CLARIFICATION: Is the seven-region structure open to change, or only its
  styling?]
- [NEEDS CLARIFICATION: Are the title, setup, rules, ending and overlay screens in
  scope this time? 005 excluded them.]
- [NEEDS CLARIFICATION: What does `reference/pixel-card-variant-v1.0.pdf` show, and is
  it a style target?]
- [NEEDS CLARIFICATION: How much of the publisher's look is acceptable to reproduce?]

## Sources

- `.specify/assessments/board-ui-polish/intake.md` (repo)
- `specs/001-ui-polish/spec.md`, `specs/001-ui-polish/tasks.md` (repo)
- `specs/005-playfield-polish/spec.md`, `tasks.md`, `quickstart.md`, `baseline.md` (repo)
- `ui/theme/tokens.gd`, `ui/model/layout_solver.gd`, `ui/screens/play_screen.gd`,
  `ui/fx/shaders/` (repo)
- `art/STYLE_PROMPT.md`, `art/fonts/`, `reference/` listing (repo)
- `build/screenshots/android.png`, `build/screenshots/matrix/desktop/*.png`,
  `build/design-shots/20_region_banner.png` (local build output, 2026-10-14)
- `project.godot` (repo); git log on `003-dragon-art`
- No external URLs fetched (policy: none requested)
