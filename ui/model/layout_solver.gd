extends RefCounted
## Works out where everything on the play screen goes for a given window.
## The game is landscape only: one arrangement, laid out at 1280 x 720 design units
## and scaled evenly to the window. Pure, so it is tested without a display.

const T = preload("res://ui/theme/tokens.gd")

const HEADER_H := 48
const GAP := 12
const COLUMN_GAP := 24
## How far a picked-up card rises out of its row; less than GAP, so it never
## reaches the band above.
const HELD_LIFT := 10.0
## The role strip across the top of the card side: one tap target tall, half the
## two-row slot band it replaced (feature 009, research R4).
const STRIP_H := 88.0
## The least height an empty place's outline keeps, under its badge, when the
## floating cards need the rest of the band (a full Final Enemy Hand).
const PLACE_EMPTY_H := 56.0
## The action row at the foot of the card side: two secondary cells a quarter of
## the row each, then Play across the right half (research R5).
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


## How many places the card side shows for a view state: the ordered places while
## building or in the recap after a battle, none in setup and Soak.
static func place_count(vs: Dictionary) -> int:
	if vs.is_empty():
		return 4
	return vs.get("places", []).size()


## Whether a view state is in the Final Battle, where the left side narrows.
static func is_final(vs: Dictionary) -> bool:
	return not vs.is_empty() and ["final_journey", "final_enemy", "final_soak"].has(vs.get("phase", ""))


## view: the viewport in design units. safe: the part clear of notches, in design
## units. hand_count: cards in the Hand. place_count: the ordered places (0 in setup
## and Soak, which have no role strip). points_per_unit: how large a design unit is
## on this screen. preview_needed: the height the preview asks for; 0 keeps the
## fixed split. encounter_min: the least height the face on show needs
## (T.ENCOUNTER_MIN, or T.DRAGON_MIN in the Final Battle); the preview never takes
## that from it. upright: the window is taller than it is wide, so the play area is
## a thin strip and the layout is undersized. final: the Final Battle, where the left
## side narrows to FINAL_LEFT_W.
##
## The card side, top to bottom: the role strip ("slots"), the band of cards (the
## places under the strip, the floating cards at its foot), and the action row.
static func solve(view: Vector2, safe: Rect2, hand_count := 4, place_count := 4, points_per_unit := 0.5, preview_needed := 0.0, encounter_min: int = T.ENCOUNTER_MIN, upright := false, final := false) -> Dictionary:
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
	# The preview takes what its state asks for, within limits; the Encounter the rest.
	var preview_h := body_h - roundf(body_h * 0.56) - GAP
	if preview_needed > 0.0:
		# Never so tall that the Encounter face drops under its own minimum.
		var most := minf(roundf(body_h * 0.56), body_h - GAP - encounter_min)
		preview_h = clampf(roundf(preview_needed), T.PREVIEW_MIN, most)
	var encounter_h := body_h - preview_h - GAP
	var right_x := c.position.x + left_w + COLUMN_GAP
	var right_w := c.end.x - right_x

	# The action row: a quarter each for the two secondary actions, Play the rest.
	var actions := Rect2(right_x, c.end.y - ACTION_ROW_H, right_w, ACTION_ROW_H)
	var quarter := floorf((right_w - 2 * T.S) / 4.0)
	var secondary := [Rect2(right_x, actions.position.y, quarter, ACTION_ROW_H),
		Rect2(right_x + quarter + T.S, actions.position.y, quarter, ACTION_ROW_H)]
	var commit_x: float = right_x + 2 * (quarter + T.S)
	var commit := Rect2(commit_x, actions.position.y, c.end.x - commit_x, ACTION_ROW_H)
	var strip_h := STRIP_H if place_count > 0 else 0.0
	var strip := Rect2(right_x, body_y, right_w, strip_h)
	var cards_y: float = body_y + (strip_h + GAP if place_count > 0 else 0.0)
	var cards := Rect2(right_x, cards_y, right_w, actions.position.y - GAP - cards_y)
	var regions := {
		"header": Rect2(c.position.x, c.position.y, c.size.x, HEADER_H),
		"encounter": Rect2(c.position.x, body_y, left_w, encounter_h),
		"preview": Rect2(c.position.x, body_y + encounter_h + GAP, left_w, preview_h),
		"slots": strip,
		"hand": cards,
		"actions": actions,
		"commit": commit,
		"secondary": secondary,
	}
	var card := card_size_for(cards.size, hand_count, place_count)
	return {
		"view": view, "content": c, "regions": regions,
		# What the screens other than the play screen have, under the header.
		"body": Rect2(c.position.x, body_y, c.size.x, body_h),
		"card_size": card, "hand_count": hand_count, "place_count": place_count,
		"left_w": left_w,
		"place_rects": _row(cards, card, place_count, cards.position.y),
		"points_per_unit": points_per_unit,
		"undersized": upright or points_per_unit < LEGIBLE_SCALE,
	}


## The largest card for `hand_count` cards and `place_count` places in a band of
## `band` size such that every stage of building fits at once: with k cards placed,
## the places row (an outline row while none is), then the rest floating in as many
## rows as they need. Fixed for the Hand, so the cards never resize while placing.
static func card_size_for(band: Vector2, hand_count: int, place_count: int) -> Vector2:
	var n := maxi(hand_count, 1)
	var across := maxi(place_count, 1)
	var w := floorf(minf(CARD_MAX_W, (band.x - (across - 1) * _gap_min(across)) / across))
	while w > 8.0:
		var h := floorf(w / T.CARD_ASPECT)
		if _stages_fit(band, Vector2(w, h), n, place_count):
			return Vector2(w, h)
		w -= 1.0
	return Vector2(8, floorf(8 / T.CARD_ASPECT))


static func _stages_fit(band: Vector2, card: Vector2, n: int, place_count: int) -> bool:
	var cols := _cols(band.x, card.x)
	if cols < 1:
		return false
	for k in range(0, mini(place_count, n) + 1):
		var rows := ceili((n - k) / float(cols))
		var need := rows * card.y + maxi(0, rows - 1) * GAP
		if place_count > 0:
			need += (card.y if k > 0 else PLACE_EMPTY_H) + (GAP if rows > 0 else 0)
		if need > band.y:
			return false
	return true


## How many cards of width `w` fit side by side across `width`.
static func _cols(width: float, w: float) -> int:
	var cols := 0
	while (cols + 1) * w + cols * _gap_min(cols + 1) <= width:
		cols += 1
	return cols


## `count` cards of `card` size in one row centred across `band`, at `y`.
static func _row(band: Rect2, card: Vector2, count: int, y: float) -> Array:
	var out := []
	if count <= 0:
		return out
	var gap := _card_gap(band.size.x, card.x, count)
	var row_w := count * card.x + (count - 1) * gap
	var x0 := band.position.x + (band.size.x - row_w) / 2.0
	for i in count:
		out.append(Rect2(Vector2(x0 + i * (card.x + gap), y).round(), card))
	return out


## Where `count` floating cards sit: at the foot of the band of cards, centred, in as
## few rows as hold them, filled from the top row down.
static func floating_rects(plan: Dictionary, count: int) -> Array:
	var out := []
	if count <= 0:
		return out
	var band: Rect2 = plan.regions.hand
	var card: Vector2 = plan.card_size
	var cols := maxi(1, _cols(band.size.x, card.x))
	var rows := ceili(count / float(cols))
	var y0 := band.end.y - rows * card.y - (rows - 1) * GAP
	for r in rows:
		var in_row := mini(cols, count - r * cols)
		out.append_array(_row(band, card, in_row, y0 + r * (card.y + GAP)))
	return out


## The height an empty place's outline takes while `floating` cards are unplaced:
## the card's height, or what the floating rows leave above them.
static func outline_height(plan: Dictionary, floating: int) -> float:
	var band: Rect2 = plan.regions.hand
	var card: Vector2 = plan.card_size
	var rects := floating_rects(plan, floating)
	var top: float = rects[0].position.y if not rects.is_empty() else band.end.y + GAP
	return clampf(top - GAP - band.position.y, PLACE_EMPTY_H, card.y)


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
