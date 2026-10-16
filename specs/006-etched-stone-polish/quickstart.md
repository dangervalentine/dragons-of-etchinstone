# Quickstart: Verifying Raised Stone and the Math in Plain Sight (revision 2)

How to check each stage against the spec. Commands run from the repository root.
The results gathered under revision 1 are kept at the bottom.

## 0. Baseline

The "before" screenshots are in `build/006-before/` (taken on `cdae3d2`). The space
baseline is in `baseline.md` and `baseline.json`. Before stage A, also take a
"stage 1" reference of the current board:

```sh
godot --path . -s tools/shot.gd -- build/006-rev1 phone-16x9 desktop
```

## 1. Every stage: automated gates (SC-007)

```sh
tools/test.sh
godot --path . -s tools/space_audit.gd -- --compare specs/006-etched-stone-polish/baseline.json
godot --path . -s tools/field_bench.gd
```

**Expected**:
- All tests pass, and `ui check` reports 0 failures at every matrix size, including
  the space checks.
- The space audit passes (no zone over a third empty).
- The bench passes.

**New and changed tests**:
- `test_terms` (the sums add up; outcomes unchanged);
- `test_role_slots` (replaces `test_role_rail`);
- the extended `test_layout_solver` (slots, action column, Play);
- `test_stone_contrast` on the shipped ground.

## 2. Stage A: numbers that go where they count (US1; SC-001, SC-004)

**By hand** (desktop build, then the `install-on-emulators` skill):
1. Start an Encounter. Above the Hand are three full-size slots, with the next one
   edged in focus colour. Fuse and Divert (and Give up Reserve against a Ranged
   Enemy) sit in a grid beside the slots. There is no button row under the Hand.
2. Tap a Spell card. A number flies from the card to the Spell slot and stays there,
   large, over the Attack or Move icon. No card name is in the slot.
3. Tap an Element whose Ether matches the Spell's enhanced action. The Spell slot's
   number changes to the enhanced value.
4. Tap a Boost. `+n` lands in its slot. Against an Enemy, tap its target icon: it
   switches between Attack and Initiative.
5. Tap a filled slot, then a lifted card. Each takes the card back, and the number
   leaves.
6. Reach the Final Battle. Six slots and the actions fit side by side, and the Hand
   cards are no smaller than before.
7. Turn on reduced motion: numbers appear at once.

## 3. Stage A: the math, shown (US2; SC-002, SC-003)

1. **Terms add up (SC-002).** `test_terms` passes, so the terms add up to the
   engine's totals in every state it generates. In the standard screenshot set, read
   each box: the terms visibly add up to the total.
2. **Each modifier.** Against an Enemy with Armor in the Spell's Ether, an Armor line
   shows. On a Journey under Night Travel, a Night Travel line shows. Find a Steep
   Journey and check the MP target shows Steep.
3. **First-time viewer (SC-003).** Show a state with a Hardship in effect to someone
   who has not seen the box. Ask what changed the result; they find it within
   10 seconds.
4. **Incomplete set.** With a role empty, the box shows the terms so far and "Still
   needed", with no verdict; Play is disabled with the reason.
5. **Play.** Play sits at the foot of the box with the verdict on it ("Play · Narrow
   victory"). If the R3 fallback was taken, Play is in the bottom-right corner, and
   this file records why.

## 4. Stage B: raised boxes and flat ground (US3, US4)

1. **Generate the ground** on this Mac (about 4 minutes an image; `--count 4` takes
   about 16 minutes):

   ```sh
   python3 tools/generate_art.py pattern ground --count 4
   godot --headless --path . -s tools/make_ground.gd -- build/art/pattern/ground-<n>.png
   ```

   The second command writes `art/stone/grain.png`. Run it for each candidate and
   show the owner a screenshot with each.
2. **Idle (SC-006).** Watch the play screen for 10 s: nothing moves or glows except
   the waiting zone's edge.
3. **Responses (SC-006).** Do each action in
   [contracts/board-life.md](contracts/board-life.md) and name the response.
4. **Reduced motion (SC-009).** Menu → Motion → Reduced: nothing moves anywhere.
5. **Stutter (SC-008).** On the served web build and the Android emulator: no
   visible stutter while placing cards or during a resolution.

## 5. Stage B exit point: owner sign-off (US3 scenario 4)

Put `build/006-before/phone-16x9/05_challenge_assigned.png`, `12_final_journey.png`
and `07_soak.png` above the stage B shots of the same states (the comparison stacker
in the session scratchpad, or any image tool), and send them to the owner.

- **After preferred**: continue to stage C.
- **Not preferred**: stop. Stages A's layout and math stay. Record the outcome here.

## 6. Stage C: every screen (US5; SC-005)

```sh
godot --path . -s tools/shot.gd -- build/006-after
godot --path . -s tools/design_shots.gd -- build/006-after/design
```

For every row of [contracts/screens-and-lore.md](contracts/screens-and-lore.md):
1. Lay out the before and after.
2. The owner prefers the after.
3. Every "Must keep" item is present.

## Results

_Record observer results, bench numbers and the owner's decisions here._

- **Pre-feature bench (T004, 2026-10-15, Apple M5 Pro, Compatibility renderer)**:
  `field_bench` average 2.14 ms, p99 3.88 ms, worst 6.67 ms: PASS.
- **Stage 2 bench (T038, 2026-10-15, same machine)**: with the stone backdrop, rift
  seams (Fire) and motes behind the 11 faces, `field_bench` gives average 2.15 ms,
  p99 3.79 ms, worst 13.12 ms: PASS. That is about 0.01 ms over the pre-feature
  average (C2's ≤ 1 ms budget). No phone or web build has been measured.
- **Viewer checks (T039, SC-004, SC-005)**: not run yet. They need someone other
  than the developer.
- **Stutter on web and Android (SC-008)**: not checked yet. No emulator was running,
  and the web build was not opened in a browser.

- **Where Play goes (T009, revision 2)**: `ENCOUNTER_MIN` is 310, measured on an
  Enemy face with an Ability and a Hardship at 400 wide. A Journey needs 202. With
  Play inside it, the fullest Enemy math box needs about 336 of the 628-unit column,
  which leaves the Encounter 280, so the R3 gate fails. The bottom-right fallback
  would shrink the Final Battle's cards to 107 wide (baseline 137). Play therefore
  sits in the bottom-right cells of the action column beside the slots (research R3,
  Outcome). `PLAY_IN_COLUMN` is false.
- **Space audit after US1 (revision 2)**: PASS. No zone is over a third empty at
  `phone-16x9` or `phone-small`; the emptiest is the preview, at 25%. The old check
  that the role display stays under half the old band is now report-only, because
  the full-size slots replace the compact rail on purpose.
- **US1 walkthrough (T017, revision 2)**: a scratch script drove quickstart §2 steps
  1–5 and 7 against the real slot buttons at 1280 × 720. All 18 checks passed:
  - a number flies in and shows on landing;
  - the Spell's number goes from 3 to 8 when the matching Element lands, and counts
    there;
  - the Boost's switch moves it to Initiative;
  - tapping a slot takes its card back;
  - under reduced motion the number shows at once.

  Step 6 (the Final Battle) was checked by screenshot and by the solver tests.

- **The math box (T021, revision 2)**: a scratch script found each state through the
  engine and shot it at 1280 × 720. In each one the terms add up to the total shown:
  - Armor: `10 + 2 − 1 = 11 / 7 HP`, the Armor line in red;
  - Night Travel: `6 + 2 − 1 = 7`, named "Night Travel";
  - Steep: the target line `MP 9 + Steep 5 = 14`;
  - an Ambush, shown in the damage pill's terms;
  - the Final Journey and the Final Enemy, adding both sets.
- **Final Battle room**: the dragon's face needs 332 to 384 units (Grimroch's Final
  Enemy), so its box gets as little as 232. For that reason:
  - the Final Battle rows are smaller and stop at the total, since the face lists the
    tiers;
  - the separate defeat line gives way to the red edge, verdict and Play.

  A check over every dragon, both steps and several two-set Hands found nothing
  overflowing.
- **First-time viewer (SC-003)**: pending. It needs someone who has not seen the box;
  the Armor and Night Travel screenshots are ready for it. Ask again at the stage B
  sign-off (T031).

- **Stage B so far (revision 2)**:
  - **Bench:** average 1.90 ms, p99 3.00 ms: PASS. A run during generation gave
    3.53 ms / p99 18.2 ms, because ComfyUI was using the GPU.
  - **Idle check (SC-006):** two frames a second apart, after 10 s, are identical over
    the bare ground.
  - **Ground candidates:** seeds 6001–6004, about 3½ minutes each on this Mac. Each
    made a tile inside the luminance band. They are in `build/art/pattern/`, and
    nothing is in `art/stone/` until the owner picks.
  - **Not checked:** stutter on Android (no emulator running) and on the served web
    build.

### Stage 2 sign-off (T040), 2026-10-15

The owner saw the before/after play screens (placing cards, the Final Journey, Soak)
and redirected rather than approving:

- **Effects rejected.** The lit cracks, rift glow and motes "look like early 2000's
  flash animation". They want flat lines, perhaps a consistent pattern generated in
  ComfyUI (allowed on this Mac now), and strong raised boxes.
- **A bigger layout shift**, after their reference (`~/Downloads/unnamed-2.png`):
  - Full-size role slots above the Hand, with Fuse and Divert moved up beside them.
  - Tapping a card sends its number (for example the Spell's damage) up into its slot.
  - The left box shows the math adding up to the result, including Hardships and
    any other modifiers.
- **Cards.** Shown in the proportions and layout of the printed cards, one Level per
  face.

Actions taken:
- **Removed:** the cracks, glow, motes and seam responses. Board responses now play
  only at the zones' rims.
- **Kept:** the chamfered, raised boxes and the plain stone grain as a starting point.
- **Bench after removal:** average 2.07 ms, p99 3.29 ms: PASS.

The new layout needs the spec revised before more tasks: the full slot band
reverses US1's compact rail.
