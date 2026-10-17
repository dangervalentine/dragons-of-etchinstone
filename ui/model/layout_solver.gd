extends RefCounted
## Works out where everything on the play screen goes for a given window.
## The game is landscape only: one arrangement, laid out at 1280 x 720 design units
## and scaled evenly to the window. Pure, so it is tested without a display.

const T = preload("res://ui/theme/tokens.gd")

const HEADER_H := 48
const GAP := 12
const COLUMN_GAP := 24
const CARD_LIFT := 14          # room above the Hand for a placed card to rise into
## The most room left between the top of the Hand region and its cards; anything
## more goes below them.
const HAND_TOP_AIR := 12.0
## The band of role slots across the top of the right column: two rows of tap
## targets, so the action column beside it holds a 2-row grid (research R3).
const SLOT_BAND_H := 2 * T.TAP_MIN + T.S
## Where a four-card Hand is bound by width and leaves height over, half of it goes to
## the slot band, up to this, so the slots are larger rather than the board emptier.
const SLOT_BAND_MAX := 264.0
## The action column is as wide as this many cells: three beside one Action Set's
## slots, two beside the Final Battle's six, which then keep 88 units each. The
## secondary actions share its top row (a step under way turns its action into
## Cancel, so there are never more than fit) and Play its bottom one.
const ACTION_CELL_W := 118
const ACTION_COLS := 3
const ACTION_COLS_FINAL := 2
## Where Play goes (T009): at the foot of the math box when the Encounter still fits
## above the fullest box, else in the action column's bottom row. Measured at
## 1280 x 720: the Enemy box with Play needs about 336 of the column's 628, leaving
## the Encounter 280, under ENCOUNTER_MIN; the Final Battle has less room still.
## The bottom-right corner under the Hand would cost the Final Battle's two rows of
## cards their baseline size, so Play joins the actions beside the slots.
const PLAY_IN_COLUMN := false
const CARD_MAX_W := 250.0
## Room between Hand cards side by side; a little less once more than four share a row.
const CARD_GAP_MIN := 12.0
const CARD_GAP_CROWDED := 10.0
const CARD_GAP_MAX := 36.0
## Below this many points per design unit, 22-unit text is under about 9 points.
const LEGIBLE_SCALE := 0.41

## Window shapes the game is checked at: name -> [window pixels, safe-area insets
## in pixels as left, top, right, bottom, points per pixel]. The layout is always
## 1280 x 720; these test where its letterbox falls and how the safe area maps in.
const MATRIX := {
	"phone-16x9": [Vector2(1280, 720), [0, 0, 0, 0], 0.5],
	"phone-tall": [Vector2(2532, 1170), [141, 0, 141, 63], 1.0 / 3.0],
	"phone-tall-flipped": [Vector2(2532, 1170), [141, 0, 141, 63], 1.0 / 3.0],
	"phone-small": [Vector2(1334, 750), [0, 0, 0, 0], 0.5],
	"tablet": [Vector2(2048, 1536), [0, 0, 0, 40], 0.5],
	"desktop": [Vector2(1440, 900), [0, 0, 0, 0], 1.0],
	"desktop-ultrawide": [Vector2(3840, 1080), [0, 0, 0, 0], 1.0],
	"upright-browser": [Vector2(720, 1280), [0, 0, 0, 0], 0.5],
}


## The part of a window the 16:9 play area fills, in window pixels, as the
## project's `keep` stretch places it; the rest is letterbox.
static func stage_for_window(window_px: Vector2) -> Rect2:
	var s := minf(window_px.x / T.DESIGN_MIN.x, window_px.y / T.DESIGN_MIN.y)
	var size := T.DESIGN_MIN * s
	return Rect2((window_px - size) / 2.0, size)


## A safe area given in window pixels, in design units: mapped through the play
## area, less whatever of it is letterbox.
static func safe_in_view(window_px: Vector2, safe_px: Rect2) -> Rect2:
	var stage := stage_for_window(window_px)
	var k := stage.size.x / T.DESIGN_MIN.x
	return Rect2((safe_px.position - stage.position) / k, safe_px.size / k).intersection(Rect2(Vector2.ZERO, T.DESIGN_MIN))


## The safe area of a MATRIX row in design units; `flipped` swaps its left and
## right insets, as turning the phone end over end does.
static func matrix_safe(name: String, flipped := false) -> Rect2:
	var m: Array = MATRIX[name]
	var inset: Array = m[1]
	if flipped:
		inset = [inset[2], inset[1], inset[0], inset[3]]
	var px := Rect2(Vector2(inset[0], inset[1]), m[0] - Vector2(inset[0] + inset[2], inset[1] + inset[3]))
	return safe_in_view(m[0], px)


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


## How many Action Sets the role slots show for a view state: one per Action Set
## while building, the recap of the set just played after a battle, or none, when
## the Hand can have the room (setup, the Final Battle's Soak).
static func slot_rows(vs: Dictionary) -> int:
	if vs.is_empty():
		return 1
	if not vs.sets.is_empty():
		return vs.sets.size()
	return 1 if vs.get("played") != null else 0


## The width of the action column beside `set_count` Action Sets.
static func action_width(set_count: int) -> float:
	var cols := ACTION_COLS_FINAL if set_count > 1 else ACTION_COLS
	return cols * ACTION_CELL_W + (cols - 1) * T.S


## view: the viewport in design units. safe: the part clear of notches, in design
## units. points_per_unit: how large a design unit is on this screen. set_count:
## Action Sets in the slot band, 0 to give its room to the Hand. preview_needed: the
## height the preview asks for; 0 keeps the fixed split. encounter_min: the least
## height the face on show needs (T.ENCOUNTER_MIN, or T.DRAGON_MIN in the Final
## Battle); the preview never takes that from it. upright: the window is taller
## than it is wide, so the play area is a thin strip and the layout is undersized.
##
## The right column: the Hand at the top, and under it the slot band with the action
## column beside it (secondary actions in its top row, Play in its bottom row, both
## full width), at the foot of the column. With no sets the band shrinks to the
## action column's one row.
static func solve(view: Vector2, safe: Rect2, hand_count := 4, set_count := 1, points_per_unit := 0.5, preview_needed := 0.0, encounter_min: int = T.ENCOUNTER_MIN, upright := false) -> Dictionary:
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
	var left_w := clampf(roundf(c.size.x * 0.32), 400.0, 548.0)
	# The preview takes what its state asks for, within limits; the Encounter the rest.
	var preview_h := body_h - roundf(body_h * 0.56) - GAP
	if preview_needed > 0.0:
		# Never so tall that the Encounter face drops under its own minimum.
		var most := minf(roundf(body_h * 0.5), body_h - GAP - encounter_min)
		preview_h = clampf(roundf(preview_needed), T.PREVIEW_MIN, most)
	var encounter_h := body_h - preview_h - GAP
	var right_x := c.position.x + left_w + COLUMN_GAP
	var right_w := c.end.x - right_x

	var action_w := action_width(set_count)
	var band_h: float = SLOT_BAND_H if set_count > 0 else float(T.TAP_MIN)
	if set_count == 1:
		# Worked out for the standard four-card Hand, so the band does not move
		# between building a set and the recap after it.
		var room := c.end.y - body_y - SLOT_BAND_H - GAP
		# A Hand bound by height (five or more cards) keeps its height: the band only
		# takes what both it and the four-card Hand leave over.
		var spare := INF
		for n in [4, hand_count]:
			var fit: Dictionary = _fit_cards(Rect2(0, 0, right_w, room), n)
			var used: float = CARD_LIFT + fit.rows * fit.size.y + (fit.rows - 1) * GAP + HAND_TOP_AIR
			spare = minf(spare, room - used)
		band_h = minf(SLOT_BAND_H + floorf(maxf(0.0, spare) / 2.0), SLOT_BAND_MAX)
	# The band sits at the foot of the right column, under the Hand (owner, stage C).
	var band_y := c.end.y - band_h
	var actions := Rect2(c.end.x - action_w, band_y, action_w, band_h)
	# One column: the secondary actions in a row across the top half, Play across the
	# bottom half, both the column's full width. With no sets Play has it all.
	var commit_h: float = band_h if set_count == 0 else floorf((band_h - T.S) / 2.0)
	var commit := Rect2(actions.position.x, actions.end.y - commit_h, action_w, commit_h)
	var slots := Rect2(right_x, band_y, actions.position.x - GAP - right_x, band_h if set_count > 0 else 0.0)
	var regions := {
		"header": Rect2(c.position.x, c.position.y, c.size.x, HEADER_H),
		"encounter": Rect2(c.position.x, body_y, left_w, encounter_h),
		"preview": Rect2(c.position.x, body_y + encounter_h + GAP, left_w, preview_h),
		"slots": slots,
		"hand": Rect2(right_x, body_y, right_w, band_y - GAP - body_y),
		"actions": actions,
		"commit": commit,
	}
	var fit: Dictionary = _fit_cards(regions.hand, hand_count)
	return {
		"view": view, "content": c, "regions": regions,
		# What the screens other than the play screen have, under the header.
		"body": Rect2(c.position.x, body_y, c.size.x, body_h),
		"card_size": fit.size, "hand_rows": fit.rows,
		"card_rects": card_rects(regions.hand, fit.size, hand_count, fit.rows),
		"points_per_unit": points_per_unit,
		"undersized": upright or points_per_unit < LEGIBLE_SCALE,
	}


## Where each of `count` cards sits in the Hand region, row by row, centred across
## and close under the top, just below the role slots; the height the cards cannot
## use is left at the bottom.
static func card_rects(hand: Rect2, card: Vector2, count: int, rows: int) -> Array:
	var out := []
	if count <= 0:
		return out
	var per_row := ceili(count / float(rows))
	var total_h := rows * card.y + (rows - 1) * GAP
	var spare := hand.size.y - CARD_LIFT - total_h
	var y0 := hand.position.y + CARD_LIFT + minf(spare / 2.0, HAND_TOP_AIR)
	for i in count:
		var row := i / per_row
		var in_row := mini(per_row, count - row * per_row)
		var col := i - row * per_row
		var gap := _card_gap(hand.size.x, card.x, in_row)
		var row_w := in_row * card.x + (in_row - 1) * gap
		var x0 := hand.position.x + (hand.size.x - row_w) / 2.0
		out.append(Rect2(Vector2(x0 + col * (card.x + gap), y0 + row * (card.y + GAP)).round(), card))
	return out


## The largest card that fits `count` cards in one or two rows.
static func _fit_cards(hand: Rect2, count: int) -> Dictionary:
	var best := {"size": Vector2.ZERO, "rows": 1}
	var n := maxi(count, 1)
	for rows: int in [1, 2]:
		if rows == 2 and n <= 4:
			continue
		var cols := ceili(n / float(rows))
		var w: float = (hand.size.x - (cols - 1) * _gap_min(cols)) / cols
		var h: float = (hand.size.y - CARD_LIFT - (rows - 1) * GAP) / rows
		w = floorf(minf(minf(w, h * T.CARD_ASPECT), CARD_MAX_W))
		if w > best.size.x:
			best = {"size": Vector2(w, floorf(w / T.CARD_ASPECT)), "rows": rows}
	return best


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
