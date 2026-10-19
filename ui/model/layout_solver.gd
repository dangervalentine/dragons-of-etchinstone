extends RefCounted
## Works out where everything on the play screen goes for a given window.
## The game is landscape only: one arrangement, at least 1280 x 720 design units.
## On desktop and web the view is exactly that, scaled evenly to the window; on
## phones and tablets it fills the screen and the layout grows, up to
## T.DESIGN_MAX. Pure, so it is tested without a display.

const T = preload("res://ui/theme/tokens.gd")

const HEADER_H := 48
const GAP := 12
const COLUMN_GAP := 24
## How far a picked-up card rises out of its row; less than GAP, so it never
## reaches the band above.
const HELD_LIFT := 10.0
## The label over each place of the Hand: its Role's icon and name, in text no
## smaller than T.TEXT_MIN (feature 010, research R6).
const LABEL_H := 36.0
## The Hand's well is drawn this far round its places; they sit this far below the
## top of the Hand's region (and above its foot), so the well's top is level with the
## left side's. Across, the places keep the region's full width, as cards are bound
## by it; the well reaches this far past it on each side.
const HAND_PAD := 10.0
## The action row at the foot of the card side. Up to three cells: the secondary
## actions a quarter each, Play the right half; more cells share the row evenly, Play
## always last (feature 010, research R5).
const ACTION_ROW_H := float(T.TAP_MIN)
## In the Final Battle the left side narrows to this, so every card fits (R6).
const FINAL_LEFT_W := 380.0
const CARD_MAX_W := 250.0
## Room between Hand cards side by side; a little less once more than four share a row.
const CARD_GAP_MIN := 12.0
const CARD_GAP_CROWDED := 10.0
const CARD_GAP_MAX := 36.0
## Below this many points per design unit, 22-unit text is under about 9 points.
const LEGIBLE_SCALE := 0.41

## Window shapes the game is checked at: name -> [window pixels, safe-area insets
## in pixels as left, top, right, bottom, points per pixel, fills]. `fills`: the
## device runs the mobile app, whose view fills the screen; the others are locked
## to 1280 x 720 and test where its letterbox falls.
const MATRIX := {
	"phone-16x9": [Vector2(1280, 720), [0, 0, 0, 0], 0.5, true],
	"phone-tall": [Vector2(2532, 1170), [141, 0, 141, 63], 1.0 / 3.0, true],
	"phone-tall-flipped": [Vector2(2532, 1170), [141, 0, 141, 63], 1.0 / 3.0, true],
	"phone-small": [Vector2(1334, 750), [0, 0, 0, 0], 0.5, true],
	"tablet": [Vector2(2048, 1536), [0, 0, 0, 40], 0.5, true],
	"desktop": [Vector2(1440, 900), [0, 0, 0, 0], 1.0, false],
	"desktop-ultrawide": [Vector2(3840, 1080), [0, 0, 0, 0], 1.0, false],
	"upright-browser": [Vector2(720, 1280), [0, 0, 0, 0], 0.5, false],
}


## The view a window gets, in design units, as the project's stretch settings make
## it. Locked (`keep`, desktop and web): always 1280 x 720. Filling (`expand`, the
## mobile apps): the 1280 x 720 minimum fits, and the longer axis gets the extra.
static func view_for_window(window_px: Vector2, fills: bool) -> Vector2:
	if not fills:
		return T.DESIGN_MIN
	var s := minf(window_px.x / T.DESIGN_MIN.x, window_px.y / T.DESIGN_MIN.y)
	return (window_px / s).floor()


## The part of a window a view of `view` units is drawn in, in window pixels:
## scaled evenly and centred. A locked view leaves letterbox round it; a filling
## one already has the window's shape, so it covers the window.
static func stage_for_window(window_px: Vector2, view := T.DESIGN_MIN) -> Rect2:
	var s := minf(window_px.x / view.x, window_px.y / view.y)
	var size := view * s
	return Rect2((window_px - size) / 2.0, size)


## A safe area given in window pixels, in design units: mapped through the play
## area, less whatever of it is letterbox.
static func safe_in_view(window_px: Vector2, safe_px: Rect2, view := T.DESIGN_MIN) -> Rect2:
	var stage := stage_for_window(window_px, view)
	var k := stage.size.x / view.x
	return Rect2((safe_px.position - stage.position) / k, safe_px.size / k).intersection(Rect2(Vector2.ZERO, view))


## The view of a MATRIX row in design units.
static func matrix_view(name: String) -> Vector2:
	var m: Array = MATRIX[name]
	return view_for_window(m[0], m[3])


## The safe area of a MATRIX row in design units; `flipped` swaps its left and
## right insets, as turning the phone end over end does.
static func matrix_safe(name: String, flipped := false) -> Rect2:
	var m: Array = MATRIX[name]
	var inset: Array = m[1]
	if flipped:
		inset = [inset[2], inset[1], inset[0], inset[3]]
	var px := Rect2(Vector2(inset[0], inset[1]), m[0] - Vector2(inset[0] + inset[2], inset[1] + inset[3]))
	return safe_in_view(m[0], px, matrix_view(name))


## How far inside a rounded screen corner the safe area stops, as a share of its
## radius. Phones report a circle, but their corners are smoother curves that begin
## bending sooner, so touching the circle is not enough.
const CORNER_CLEARANCE := 0.25


## Shrink `safe` (within a window of `window` pixels) so none of its corners falls
## outside the screen's rounded corners. `radii` are the screen's corner radii in
## pixels: top left, top right, bottom right, bottom left.
static func clear_corners(safe: Rect2, window: Vector2, radii: Array) -> Rect2:
	var inset := [safe.position.x, safe.position.y, window.x - safe.end.x, window.y - safe.end.y]
	# Each corner and the two edges (left, top, right, bottom) that meet there.
	for corner: Array in [[0, 0, 1], [1, 2, 1], [2, 2, 3], [3, 0, 3]]:
		var r: float = radii[corner[0]]
		var a: float = inset[corner[1]]
		var b: float = inset[corner[2]]
		var reach := r * (1.0 - CORNER_CLEARANCE)
		if a >= r or b >= r or pow(r - a, 2) + pow(r - b, 2) <= reach * reach:
			continue
		# Step in until the corner of the safe area is the clearance inside the curve.
		var d := r - reach * sqrt(0.5)
		inset[corner[1]] = maxf(a, d)
		inset[corner[2]] = maxf(b, d)
	return Rect2(inset[0], inset[1], window.x - inset[0] - inset[2], window.y - inset[1] - inset[3])


## How many places the card side shows for a view state: the ordered places while
## building or in the recap after a battle, none in setup and Soak. The Final
## Enemy's extras are not counted: they have no Role, so no column of their own in
## the sets' grid, and are laid out after it (hand_count covers them).
static func place_count(vs: Dictionary) -> int:
	if vs.is_empty():
		return 4
	return vs.get("places", []).filter(func(pl): return pl.get("role") != "extra").size()


## Whether a view state is in the Final Battle, where the left side narrows.
static func is_final(vs: Dictionary) -> bool:
	return not vs.is_empty() and ["final_journey", "final_enemy", "final_soak"].has(vs.get("phase", ""))


## view: the viewport in design units. safe: the part clear of notches, in design
## units. hand_count: cards in the Hand. place_count: the labelled places (0 in setup
## and Soak, which show no labels). points_per_unit: how large a design unit is
## on this screen. upright: the window is taller than it is wide, so the play area is
## a thin strip and the layout is undersized. final: the Final Battle, where the left
## side narrows to FINAL_LEFT_W.
##
## `action_cells`: how many cells the action row holds, Play included.
##
## The card side, top to bottom: the Hand, one labelled place per card in as few
## rows as give the largest cards, then the action row.
static func solve(view: Vector2, safe: Rect2, hand_count := 4, place_count := 4, points_per_unit := 0.5, upright := false, final := false, action_cells := 3) -> Dictionary:
	var left := maxf(safe.position.x, T.M)
	var top := maxf(safe.position.y, T.M)
	var right := minf(safe.end.x, view.x - T.M)
	var bottom := minf(safe.end.y, view.y - T.M)
	var c := Rect2(left, top, right - left, bottom - top)
	# Past the maximum the content stops growing and sits in the middle.
	if c.size.x > T.DESIGN_MAX.x:
		c.position.x += (c.size.x - T.DESIGN_MAX.x) / 2.0
		c.size.x = T.DESIGN_MAX.x
	if c.size.y > T.DESIGN_MAX.y:
		c.position.y += (c.size.y - T.DESIGN_MAX.y) / 2.0
		c.size.y = T.DESIGN_MAX.y
	c = Rect2(c.position.round(), c.size.floor())

	var body_y := c.position.y + HEADER_H + GAP
	var body_h := c.end.y - body_y
	var left_w := FINAL_LEFT_W if final else clampf(roundf(c.size.x * 0.32), 400.0, 548.0)
	var right_x := c.position.x + left_w + COLUMN_GAP
	var right_w := c.end.x - right_x

	var actions := Rect2(right_x, c.end.y - ACTION_ROW_H, right_w, ACTION_ROW_H)
	var row := action_cells_for(actions, action_cells)
	var hand := Rect2(right_x, body_y, right_w, actions.position.y - GAP - body_y)
	var regions := {
		"header": Rect2(c.position.x, c.position.y, c.size.x, HEADER_H),
		# The whole left column is the Deck (specs/013 research R5).
		"encounter": Rect2(c.position.x, body_y, left_w, body_h),
		"hand": hand,
		"actions": actions,
		"commit": row.commit,
		"secondary": row.secondary,
	}
	# Every card has a place: the ordered places, then the Final Enemy's extras; in
	# setup and Soak the cards alone, without labels.
	var n := maxi(maxi(hand_count, place_count), 1)
	var label_h := LABEL_H if place_count > 0 else 0.0
	var band := hand.grow_individual(0, -HAND_PAD, 0, -HAND_PAD)
	var laid: Dictionary
	if final and (place_count == 6 or place_count == 7):
		# The Final Battle's two sets, one row each, under one row of labels.
		laid = _set_grid(band, place_count, n, label_h)
	else:
		# Building a Region set keeps one row (FR-001); setup and Soak may wrap when
		# that gives larger cards.
		laid = _positions(band, n, label_h, 1 if place_count > 0 else 3)
	return {
		"view": view, "content": c, "regions": regions,
		# What the screens other than the play screen have, under the header.
		"body": Rect2(c.position.x, body_y, c.size.x, body_h),
		"card_size": laid.card, "hand_count": hand_count, "place_count": place_count,
		"action_cells": action_cells,
		"left_w": left_w,
		"positions": laid.positions,
		"label_h": label_h,
		"set_rows": laid.get("set_rows", false),
		"points_per_unit": points_per_unit,
		"undersized": upright or points_per_unit < LEGIBLE_SCALE,
	}


## The action row's cells (research R5): up to three, the secondary actions a quarter
## each and Play the right half; four, a quarter each; five, a fifth each. Play is
## always the last cell, on the right.
static func action_cells_for(actions: Rect2, cells: int) -> Dictionary:
	var parts := 4 if cells <= 4 else cells
	var each := floorf((actions.size.x - (parts - 1) * T.S) / parts)
	var secondary := []
	for i in maxi(2, cells - 1):
		secondary.append(Rect2(actions.position.x + i * (each + T.S), actions.position.y, each, actions.size.y))
	var commit_x: float = secondary[-1].end.x + T.S
	return {"secondary": secondary, "commit": Rect2(commit_x, actions.position.y, actions.end.x - commit_x, actions.size.y)}


## The Final Battle's places as a grid: one row per Action Set, its Element, Spell and
## Boost in the same columns, so one row of labels names both (the cards say which
## set). The Final Journey's Reserve leads Set 1's row; the Final Enemy's extras
## fill columns after the Boosts, top to bottom. Only the first row has labels.
static func _set_grid(band: Rect2, place_count: int, n: int, label_h: float) -> Dictionary:
	var lead := 1 if place_count == 7 else 0
	var extras := maxi(0, n - place_count)
	var cols := lead + 3 + ceili(extras / 2.0)
	var cells := []
	if lead == 1:
		cells.append([0, 0])
	for row in 2:
		for c in 3:
			cells.append([row, lead + c])
	for k in extras:
		cells.append([k % 2, lead + 3 + k / 2])
	var w := floorf(minf(CARD_MAX_W, (band.size.x - (cols - 1) * _gap_min(cols)) / cols))
	var h := floorf(w / T.CARD_ASPECT)
	var tallest := floorf((band.size.y - label_h - GAP) / 2.0)
	if h > tallest:
		h = tallest
		w = floorf(h * T.CARD_ASPECT)
	var gap := _card_gap(band.size.x, w, cols)
	var x0 := band.position.x + (band.size.x - (cols * w + (cols - 1) * gap)) / 2.0
	var out := []
	for cell in cells:
		var x: float = roundf(x0 + cell[1] * (w + gap))
		var y: float = band.position.y + label_h + cell[0] * (h + GAP)
		out.append({"label": Rect2(x, band.position.y if cell[0] == 0 else y, w, label_h if cell[0] == 0 else 0.0),
			"card": Rect2(x, y, w, h)})
	return {"card": Vector2(w, h), "positions": out, "set_rows": true}


## `n` labelled places in `band`: in up to `most_rows` rows, as many as give the widest
## card, each row centred across the band, from its top. Every place is a label
## `label_h` tall over a card.
static func _positions(band: Rect2, n: int, label_h: float, most_rows: int) -> Dictionary:
	var best := {}
	for rows in range(1, most_rows + 1):
		if rows > n:
			break
		var cols := ceili(n / float(rows))
		var w := floorf(minf(CARD_MAX_W, (band.size.x - (cols - 1) * _gap_min(cols)) / cols))
		var h := floorf(w / T.CARD_ASPECT)
		var tallest := floorf((band.size.y - (rows - 1) * GAP) / rows - label_h)
		if h > tallest:
			h = tallest
			w = floorf(h * T.CARD_ASPECT)
		if w < 8.0:
			continue
		if best.is_empty() or w > best.card.x:
			best = {"card": Vector2(w, h), "rows": rows, "cols": cols}
	if best.is_empty():
		best = {"card": Vector2(8, floorf(8 / T.CARD_ASPECT)), "rows": 1, "cols": n}
	var card: Vector2 = best.card
	var cell_h: float = label_h + card.y
	# The first row's labels line up with the top of the left side.
	var y0 := band.position.y
	var out := []
	for r in best.rows:
		var in_row := mini(best.cols, n - r * best.cols)
		for rect in _row(band, Vector2(card.x, cell_h), in_row, y0 + r * (cell_h + GAP)):
			out.append({"label": Rect2(rect.position, Vector2(card.x, label_h)),
				"card": Rect2(rect.position + Vector2(0, label_h), card)})
	return {"card": card, "positions": out}


## `count` cells of `cell` size in one row centred across `band`, at `y`.
static func _row(band: Rect2, cell: Vector2, count: int, y: float) -> Array:
	var out := []
	if count <= 0:
		return out
	var gap := _card_gap(band.size.x, cell.x, count)
	var row_w := count * cell.x + (count - 1) * gap
	var x0 := band.position.x + (band.size.x - row_w) / 2.0
	for i in count:
		out.append(Rect2(Vector2(x0 + i * (cell.x + gap), y).round(), cell))
	return out


static func _card_gap(width: float, card_w: float, in_row: int) -> float:
	if in_row <= 1:
		return 0.0
	return clampf((width - in_row * card_w) / (in_row - 1), _gap_min(in_row), CARD_GAP_MAX)


static func _gap_min(in_row: int) -> float:
	return CARD_GAP_MIN if in_row <= 4 else CARD_GAP_CROWDED


## How much of `zone` (a global rect) is empty: the share of its height, in 16-unit
## rows, with nothing drawn across it. Room beside a short line of text is not
## counted; a band with nothing in it is. "What is drawn" is every visible leaf
## Control under `root` (a Label only where its text is), so a container filling
## the zone does not count as content.
static func empty_fraction(zone: Rect2, root: Control) -> float:
	const ROW := 16.0
	var rows := maxi(1, int(zone.size.y / ROW))
	var used := PackedByteArray()
	used.resize(rows)
	for r in _drawn_rects(root):
		var hit: Rect2 = zone.intersection(r)
		if hit.size.x <= 0.0 or hit.size.y <= 0.0:
			continue
		var y0 := clampi(int((hit.position.y - zone.position.y) / ROW), 0, rows - 1)
		var y1 := clampi(int(ceilf((hit.end.y - zone.position.y) / ROW)), 1, rows)
		for y in range(y0, y1):
			used[y] = 1
	var count := 0
	for b in used:
		count += b
	return 1.0 - count / float(rows)


static func _drawn_rects(root: Control) -> Array:
	var out := []
	for node in root.find_children("*", "Control", true, false):
		var c := node as Control
		if not c.is_visible_in_tree() or c.modulate.a < 0.1 or c.size == Vector2.ZERO:
			continue
		# Layout containers, spacers and bare panels are background, not content; a
		# panel that draws its own box inside the zone (a chip, a recap) is content.
		if c.get_class() == "Panel" or (c is Container and not c is BaseButton and not c is PanelContainer):
			continue
		if c.get_class() == "Control" and c.get_script() == null and c.get_signal_connection_list("draw").is_empty():
			continue
		var leaf := true
		for child in c.get_children():
			if child is Control and child.visible:
				leaf = false
				break
		if not leaf and not c is BaseButton and not c is PanelContainer:
			continue
		if c is Label:
			if c.text == "":
				continue
			var font: Font = c.get_theme_font("font")
			var fs: int = c.get_theme_font_size("font_size")
			var width := c.size.x if c.autowrap_mode != TextServer.AUTOWRAP_OFF else -1.0
			var ts := font.get_multiline_string_size(c.text, HORIZONTAL_ALIGNMENT_LEFT, width, fs)
			ts = Vector2(minf(ts.x, c.size.x), minf(ts.y, c.size.y))
			var g := c.get_global_rect()
			var x := g.position.x
			if c.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
				x += (g.size.x - ts.x) / 2.0
			elif c.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
				x += g.size.x - ts.x
			var y := g.position.y
			if c.vertical_alignment == VERTICAL_ALIGNMENT_CENTER:
				y += (g.size.y - ts.y) / 2.0
			elif c.vertical_alignment == VERTICAL_ALIGNMENT_BOTTOM:
				y += g.size.y - ts.y
			out.append(Rect2(x, y, ts.x, ts.y))
		else:
			out.append(c.get_global_rect())
	return out
