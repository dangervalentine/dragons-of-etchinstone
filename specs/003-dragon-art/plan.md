# Dragon art, step 1: full-body art, head crops and jaws — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the four dragon head icons with the new full-body silhouettes, show the head crop where the player faces the dragon, and give each dragon a moving jaw.

**Architecture:** `ui/model/art.gd` names each dragon's art and its head region (in the art's 512 units). `ui/fx/creature.gd` gains a tweenable `crop` rectangle: it scales the full-size layers so the region fills the widget and clips the rest, so pivots and the idle shader are untouched. Widgets that face the dragon set the crop to `Art.head(name)`; the banner, which draws a plain texture, uses an `AtlasTexture` of the same region. Jaws are cut with the existing pipeline (mask, FLUX Fill body, `vectorize_art.py`).

**Tech Stack:** Godot 4.7.2 (GDScript), headless tests in `tests/` run by `tools/test.sh`, Python art tools run with ComfyUI's Python (`$HOME/ComfyUI/.venv/Scripts/python.exe`), ComfyUI with FLUX Fill Q8.

Design: `specs/003-dragon-art/design.md`. Deviation from it: the crop is chosen by each widget (they already know whether they face the dragon), not passed in the view state.

The user commits their own work: no task commits. Each task ends by running the tests.

---

## File map

| File | Change |
|---|---|
| `ui/model/art.gd` | dragons point at the new art; `FULL`, `HEADS`, `head()`; motion and speed for the new names; `PARTS` for the jaws (Task 5) |
| `art/creatures/CREDITS.md` | credit the four new files; drop the four old dragon rows |
| `art/creatures/` | delete the twelve old dragon files and their `.import`s; add `-base`/`-part` for the jaws (Task 5) |
| `ui/fx/creature.gd` | `crop` property; `_fit` scales and offsets the layers to it |
| `ui/theme/theme.gd` | `texture_rect()` (shared by `icon_rect`), `art_crop()` |
| `ui/overlays/stage_banner.gd` | `show_banner` takes an icon name or a texture |
| `ui/main.gd` | banner for the Final Journey/Enemy shows the head crop |
| `ui/widgets/face_frame.gd` | `set_look` takes a crop |
| `ui/screens/play_screen.gd` | the setup face shows the head |
| `ui/screens/ending_screen.gd` | the ending sigil shows the head |
| `ui/widgets/dragon_face.gd` | full body on the road, head in battle, zooming across |
| `tests/test_art.gd` | head regions; new names |
| `tests/test_creature.gd` | new: crop layout maths |

---

### Task 1: Point the dragons at the new art

**Files:**
- Modify: `ui/model/art.gd`
- Modify: `art/creatures/CREDITS.md`
- Modify: `tests/test_art.gd`
- Delete: `art/creatures/{spiked-dragon-head,dragon-head,sea-serpent,wyvern}{,-base,-part}.svg` and their `.svg.import`

- [ ] **Step 1: Write the failing test** — append to `tests/test_art.gd`:

```gdscript
func test_every_dragon_has_a_head_region_inside_its_art() -> void:
	for id in CardDB.new().dragon_ids():
		var name: String = Art.dragon(id)
		var r: Rect2 = Art.head(name)
		ok(r != Art.FULL, name + " has a head region")
		ok(r.position.x >= 0 and r.position.y >= 0 and r.end.x <= 512 and r.end.y <= 512, name + " head is inside the art")
		eq(r.size.x, r.size.y, name + " head region is square")
	eq(Art.head("tortoise"), Art.FULL, "art without a head region is shown whole")
```

- [ ] **Step 2: Run the tests to see it fail**

Run: `godot --headless --path . -s tests/run.gd 2>&1 | grep -E "FAIL|tests,|SCRIPT ERROR"`
Expected: a script error or FAIL in `test_art.gd` (`Art.head` / `Art.FULL` don't exist).

- [ ] **Step 3: Implement** — in `ui/model/art.gd` replace the `DRAGONS` constant and add the head table after it:

```gdscript
## Each dragon's full-body art, made for this project (art/STYLE_PROMPT.md).
const DRAGONS := {
	"grimroch": "grimroch", "helsang": "helsang",
	"rodving": "rodving", "vuurhast": "vuurhast",
}
## The whole of a piece of art, in its 512 units.
const FULL := Rect2(0, 0, 512, 512)
## Where each dragon's head is in its art, square, for the places that face it.
const HEADS := {
	"grimroch": Rect2(262, 70, 215, 215),
	"helsang": Rect2(262, 8, 200, 200),
	"rodving": Rect2(245, 8, 195, 195),
	"vuurhast": Rect2(240, 0, 200, 200),
}
```

In `MOTION`, replace the `# Dragons` line with:

```gdscript
	"grimroch": "breathe", "helsang": "breathe", "rodving": "breathe", "vuurhast": "sway",
```

In `SPEED`, replace `"spiked-dragon-head": 0.6,` with `"grimroch": 0.6,`.

In `PARTS`, delete the four dragon entries (`spiked-dragon-head`, `dragon-head`, `sea-serpent`, `wyvern`); leave the dictionary with whatever other entries it has (if none remain, `const PARTS := {}`).

Add after `dragon()`:

```gdscript
## The region of `name` to show where the dragon is faced: its head, or all of it.
static func head(name: String) -> Rect2:
	return HEADS.get(name, FULL)
```

- [ ] **Step 4: Credits** — in `art/creatures/CREDITS.md`, delete the rows for `spiked-dragon-head`, `dragon-head`, `sea-serpent` and `wyvern`, and add after the table:

```markdown

## Made for this project

The four dragons were generated for this project with FLUX.1-dev from the subject lines
in `art/STYLE_PROMPT.md`, then converted with `tools/vectorize_art.py`.

| Used for | Art |
|---|---|
| Grimroch | grimroch |
| Helsang | helsang |
| Rodving | rodving |
| Vuurhast | vuurhast |
```

- [ ] **Step 5: Delete the old dragon files**

```bash
cd art/creatures && for n in spiked-dragon-head dragon-head sea-serpent wyvern; do for s in "" -base -part; do rm -f "$n$s.svg" "$n$s.svg.import"; done; done
```

- [ ] **Step 6: Check nothing else names them**

Run: `grep -rn "spiked-dragon-head\|dragon-head\|sea-serpent\|wyvern" --include=*.gd --include=*.tscn --include=*.md . | grep -v "^./specs/\|STYLE_PROMPT"`
Expected: no output. (`art/STYLE_PROMPT.md` keeps the old subject rows as history; the generator still parses them.)

- [ ] **Step 7: Import and run the tests**

Run: `godot --headless --path . --import > /dev/null 2>&1; ./tools/test.sh`
Expected: `N tests, 0 failed` and `ui check: ... 0 failed`.

---

### Task 2: A crop on the creature

**Files:**
- Modify: `ui/fx/creature.gd`
- Test: `tests/test_creature.gd` (new)

- [ ] **Step 1: Write the failing test** — create `tests/test_creature.gd`:

```gdscript
extends "res://tests/base.gd"
## The creature's crop: the region it shows fills the widget, centred.

const Creature = preload("res://ui/fx/creature.gd")
const Art = preload("res://ui/model/art.gd")


func test_whole_art_fills_a_square_widget() -> void:
	var c := Creature.new()
	c.size = Vector2(200, 200)
	c._fit()
	eq(c._picture.position, Vector2.ZERO, "whole art sits at the corner")
	eq(c._picture.size, Vector2(200, 200), "whole art fills the widget")
	ok(not c.clip_contents, "whole art is not clipped")
	c.free()


func test_whole_art_is_centred_in_a_wide_widget() -> void:
	var c := Creature.new()
	c.size = Vector2(300, 200)
	c._fit()
	eq(c._picture.position, Vector2(50, 0), "centred across")
	eq(c._picture.size, Vector2(200, 200), "kept square")
	c.free()


func test_a_crop_fills_the_widget_with_its_region() -> void:
	var c := Creature.new()
	c.size = Vector2(100, 100)
	c.crop = Rect2(256, 0, 256, 256)
	eq(c._picture.size, Vector2(200, 200), "the art is scaled so the region is the widget's size")
	eq(c._picture.position, Vector2(-100, 0), "and moved so the region is at the corner")
	ok(c.clip_contents, "the rest is clipped")
	c.crop = Art.FULL
	ok(not c.clip_contents, "back to whole art, unclipped")
	c.free()
```

- [ ] **Step 2: Run to see it fail**

Run: `godot --headless --path . -s tests/run.gd 2>&1 | grep -E "test_creature|tests,|SCRIPT ERROR"`
Expected: FAIL / script error in `test_creature.gd` (`crop` doesn't exist; and the wide widget case fails because layers fill the whole widget today).

- [ ] **Step 3: Implement** — in `ui/fx/creature.gd`, update the header comment's last sentence and add the property after `var element := ""`:

```gdscript
## The region of the art to show, in its 512 units: all of it, or a part such as a
## dragon's head (Art.head), which then fills the widget and the rest is clipped.
## The layers stay whole, so parts pivot as usual; tweening it zooms.
var crop := Art.FULL:
	set(value):
		crop = value
		clip_contents = crop != Art.FULL
		_fit()
```

Replace the layer loop at the top of `_fit()`:

```gdscript
func _fit() -> void:
	# Each layer is the whole square of art, scaled so `crop` fits the widget and
	# placed so `crop` is centred in it.
	var k := minf(size.x / crop.size.x, size.y / crop.size.y)
	var side := Art.FULL.size.x * k
	var at := (size - crop.size * k) / 2.0 - crop.position * k
	for layer in [_picture, _part]:
		if layer != null:
			layer.position = at
			layer.size = Vector2(side, side)
```

(The particle lines that follow in `_fit()` stay as they are.)

- [ ] **Step 4: Run the tests**

Run: `./tools/test.sh`
Expected: `0 failed` for both the tests and the UI check.

---

### Task 3: The banner shows the head

**Files:**
- Modify: `ui/theme/theme.gd:32-38,72-82`
- Modify: `ui/overlays/stage_banner.gd:4,17-18`
- Modify: `ui/main.gd:493-495`

- [ ] **Step 1: Theme helpers** — in `ui/theme/theme.gd`, add after `art_rect()`:

```gdscript
## Part of a creature's art, `region` in its 512 units, as a texture of its own.
static func art_crop(name: String, region: Rect2) -> Texture2D:
	var tex := art(name)
	var k := tex.get_width() / 512.0
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = Rect2(region.position * k, region.size * k)
	return a
```

and replace `icon_rect()` with a pair:

```gdscript
static func icon_rect(name: String, side: float, color: Color = T.INK) -> TextureRect:
	return texture_rect(icon(name), side, color)


static func texture_rect(texture: Texture2D, side: float, color: Color = T.INK) -> TextureRect:
	var t := TextureRect.new()
	t.texture = texture
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(side, side)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	t.modulate = color
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t
```

- [ ] **Step 2: Banner takes a texture** — in `ui/overlays/stage_banner.gd`, change the signature and the sigil lines:

```gdscript
## sigil: an icon name, a texture, or "" for none.
func show_banner(eyebrow: String, title: String, sigil, colour: Color, duration: float) -> void:
```

```gdscript
	if sigil is Texture2D:
		row.add_child(UI.texture_rect(sigil, 140, colour))
	elif sigil != "":
		row.add_child(UI.icon_rect(sigil, 140, colour))
```

- [ ] **Step 3: Main passes the head** — in `ui/main.gd` `_banner()`, replace the `"../creatures/" + Art.dragon(d.id)` argument with:

```gdscript
			UI.art_crop(Art.dragon(d.id), Art.head(Art.dragon(d.id))),
```

(Check `ui/main.gd` preloads `UI` and `Art`; it already calls `Art.dragon`, and add `const UI = preload("res://ui/theme/theme.gd")` only if it isn't there.)

- [ ] **Step 4: Run the tests**

Run: `./tools/test.sh`
Expected: `0 failed` for both.

---

### Task 4: Faces show the head; the battle zooms in

**Files:**
- Modify: `ui/widgets/face_frame.gd:50-62`
- Modify: `ui/screens/play_screen.gd:243`
- Modify: `ui/screens/ending_screen.gd:42`
- Modify: `ui/widgets/dragon_face.gd` (`_place`)

- [ ] **Step 1: Face frame takes a crop** — in `ui/widgets/face_frame.gd`, add `const Art = preload("res://ui/model/art.gd")` after the `Creature` preload, and change `set_look`:

```gdscript
## The Ether colours the face; `art_name`, a creature from art/creatures/, stands in
## the field, showing `crop` of it, or else the faint `sigil_name` emblem does.
func set_look(ether, sigil_name: String, art_name := "", crop := Art.FULL) -> void:
```

and after the `_creature.setup(...)` block (still inside `if art_name != "":`):

```gdscript
		_creature.crop = crop
```

- [ ] **Step 2: Setup face** — in `ui/screens/play_screen.gd` line 243:

```gdscript
	var art: String = vs.stage.get("art", "")
	setup_face.set_look(vs.stage.get("element", ""), "sigil_" + vs.stage.dragon, art, Art.head(art))
```

(Add `const Art = preload("res://ui/model/art.gd")` to `play_screen.gd` if it isn't already there.)

- [ ] **Step 3: Ending screen** — in `ui/screens/ending_screen.gd`, after `sigil.setup(...)`:

```gdscript
	sigil.crop = Art.head(vs.stage.art)
```

(Add the `Art` preload if missing.)

- [ ] **Step 4: Battle** — in `ui/widgets/dragon_face.gd` `_place()`, after `var beast: Rect2 = ...`:

```gdscript
	# Far off on the road the whole dragon shows; facing it, its head fills the side.
	var look: Rect2 = Art.FULL if journey else Art.head(_beast.art_name)
```

In the `if not crossing:` branch, add `_beast.crop = look` next to the `_beast.size` line. In the crossing tween, add:

```gdscript
	_tween.tween_property(_beast, "crop", look, CROSSING)
```

(Add `const Art = preload("res://ui/model/art.gd")` to `dragon_face.gd`; it extends `face_frame.gd`, so if Step 1's preload is inherited, skip it — GDScript constants are inherited by subclasses.)

- [ ] **Step 5: Run the tests**

Run: `./tools/test.sh`
Expected: `0 failed` for both.

- [ ] **Step 6: Look at it** — `godot --path . -s tools/shot.gd -- build/screenshots/matrix` and open the title, rules, setup, Final Journey, Final Enemy and ending shots. Expected: full bodies on the title and rules crests and the road; heads on the setup face, the Final Enemy and the ending. Tune `Art.HEADS` if a head is cut off or a wing intrudes; rerun the tests after any change.

---

### Task 5: Jaws

For each dragon in turn (`grimroch`, `helsang`, `rodving`, `vuurhast`); `PY=$HOME/ComfyUI/.venv/Scripts/python.exe`, ComfyUI running.

> **Deviation (as built).**
> - **Angle sign:** the angles are positive (16, 14, 18, 14). The shader samples at R(−θ)(uv − pivot) + pivot, so the picture turns by +θ, clockwise on screen (y down). That drops a right-facing jaw. The negative angles in Step 4 would open it upward.
> - **Body layer:** FLUX Fill (Step 2) redrew a second toothed jaw under the upper teeth on all four dragons (seeds 101–103, default and plainer `--fill`). Filling only the throat cut holes in the head (seed 104). The bodies are drawn by `tools/draw_throat.py <name>` instead. It takes the jaw out and draws a solid throat, one curve from the upper jaw about a third of the way along the mouth down into the neck. It writes black only where the whole is black, so base + part is exactly the whole when shut. Step 3 then converts `build/art/<name>-body-hand.png`.
> - **Drawing:** the creature shader draws the part in the same pass as the body (`part_tex`), so a see-through tint is even where they overlap.

**Files:**
- Create: `build/art/<name>-mask.png` (not in git)
- Create: `art/creatures/<name>-base.svg`, `art/creatures/<name>-part.svg`
- Modify: `ui/model/art.gd` (`PARTS`)

- [ ] **Step 1: Mask the lower jaw** — on a 1024 grid render of `build/art/prime/<name>.png`, read off the lower jaw's outline and its hinge (the back corner of the mouth). Write a mask the same size as the prime: black, with a white polygon over the lower jaw that runs ~15 px past the hinge into the head. Save it as `build/art/<name>-mask.png`. Check it by overlaying it at 50% on the prime: the white must cover all lower teeth and the jaw underside and nothing of the upper jaw.

- [ ] **Step 2: Make the body** — *Superseded: the bodies are drawn by `tools/draw_throat.py <name>` (see Deviation above); FLUX Fill drew a second jaw.* Originally: `$PY tools/generate_art.py body <name> --image build/art/prime/<name>.png --mask build/art/<name>-mask.png --q8 --count 1`
Expected: `wrote build/art/<name>-body-<seed>.png`. Check it: the jaw area is solid throat, the rest unchanged. If the fill leaves a hole or a second jaw, run again with another `--seed`.

- [ ] **Step 3: Convert both layers**

```bash
$PY tools/vectorize_art.py build/art/<name>-body-<seed>.png art/creatures/<name>-base.svg
$PY tools/vectorize_art.py build/art/prime/<name>.png --mask build/art/<name>-mask.png art/creatures/<name>-part.svg
```

- [ ] **Step 4: Rig it** — the hinge from Step 1 divided by 2 (1024 px → 512 units) is the pivot. Add to `PARTS` in `ui/model/art.gd`, angle and period as the old dragons had (negative opens a right-facing jaw downward, as `dragon-head` used):

```gdscript
	"<name>": {"motion": "hinge", "pivot": Vector2(<x>, <y>), "angle": -16.0, "period": 4.0},
```

Use angle -16 / period 4.0 for grimroch (heavy), -14 / 3.6 for helsang, -18 / 3.4 for rodving, -14 / 3.2 for vuurhast.

- [ ] **Step 5: Run the tests**

Run: `godot --headless --path . --import > /dev/null 2>&1; ./tools/test.sh`
Expected: `0 failed`; `test_every_moving_part_has_its_body_and_part` covers the new files and pivot.

- [ ] **Step 6: Watch it** — run the game (`godot --path .`), start a game with that dragon, and look at the setup face: the jaw opens downward about its hinge with no hole behind it. Adjust the sign of the angle if it opens upward.

---

### Task 6: Whole check

- [ ] **Step 1:** `./tools/test.sh` — expected `0 failed` twice.
- [ ] **Step 2:** `godot --path . -s tools/shot.gd -- build/screenshots/matrix`; review the dragon screens at every size.
- [ ] **Step 3:** `git status` — expected changes: the files in the file map, the deleted old dragon files, the new SVGs and `.import`s, `specs/003-dragon-art/`. Report to the user; they commit.
