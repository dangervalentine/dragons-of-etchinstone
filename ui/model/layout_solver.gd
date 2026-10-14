extends RefCounted
## Works out where everything on the play screen goes for a given window.
## The game is landscape only: one arrangement, at least 1280 x 720 design units,
## that grows on larger screens. Pure, so it is tested without a display.

const T = preload("res://ui/theme/tokens.gd")

const HEADER_H := 56
const BOTTOM_H := 96
const GAP := 8
const COLUMN_GAP := 16
const CARD_LIFT := 14          # room above the Hand for a placed card to rise into
const CARD_MAX_W := 250.0
## Below this many points per design unit, 22-unit text is under about 9 points.
const LEGIBLE_SCALE := 0.41

## Window sizes the layout is checked at: name -> [window pixels, safe-area insets
## in pixels as left, top, right, bottom, points per pixel].
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


## The design-unit size of a window, as the project's stretch settings produce it:
## the 1280 x 720 minimum fits, and the longer axis gets the extra.
static func view_for_window(window_px: Vector2) -> Vector2:
	var s := minf(window_px.x / T.DESIGN_MIN.x, window_px.y / T.DESIGN_MIN.y)
	return window_px / s


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


## view: the viewport in design units. safe: the part clear of notches, in design
## units. points_per_unit: how large a design unit is on this screen.
static func solve(view: Vector2, safe: Rect2, hand_count := 4, set_count := 1, points_per_unit := 0.5) -> Dictionary:
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
	var left_w := clampf(roundf(c.size.x * 0.335), 400.0, 580.0)
	var encounter_h := roundf(body_h * 0.56)
	var right_x := c.position.x + left_w + COLUMN_GAP
	var right_w := c.end.x - right_x
	var slots_h := 120.0 if set_count == 1 else 104.0
	var bottom_y := c.end.y - BOTTOM_H
	var commit_w := clampf(roundf(right_w * 0.3), 220.0, 320.0)
	# Cards are bound by width on tall screens; give the height they cannot use to the slots.
	var trial := _fit_cards(Rect2(right_x, 0, right_w, bottom_y - GAP - (body_y + slots_h + GAP)), hand_count)
	var spare: float = bottom_y - GAP - (body_y + slots_h + GAP) - CARD_LIFT - trial.rows * trial.size.y - (trial.rows - 1) * GAP
	slots_h += clampf(spare - 24.0, 0.0, 96.0)
	var hand_y := body_y + slots_h + GAP
	var regions := {
		"header": Rect2(c.position.x, c.position.y, c.size.x, HEADER_H),
		"encounter": Rect2(c.position.x, body_y, left_w, encounter_h),
		"preview": Rect2(c.position.x, body_y + encounter_h + GAP, left_w, body_h - encounter_h - GAP),
		"slots": Rect2(right_x, body_y, right_w, slots_h),
		"hand": Rect2(right_x, hand_y, right_w, bottom_y - GAP - hand_y),
		"actions": Rect2(right_x, bottom_y, right_w - commit_w - GAP, BOTTOM_H),
		"commit": Rect2(c.end.x - commit_w, bottom_y, commit_w, BOTTOM_H),
	}
	var fit := _fit_cards(regions.hand, hand_count)
	return {
		"view": view, "content": c, "regions": regions,
		"card_size": fit.size, "hand_rows": fit.rows,
		"card_rects": card_rects(regions.hand, fit.size, hand_count, fit.rows),
		"points_per_unit": points_per_unit,
		"undersized": view.y > view.x or points_per_unit < LEGIBLE_SCALE,
	}


## Where each of `count` cards sits in the Hand region, row by row, centred.
static func card_rects(hand: Rect2, card: Vector2, count: int, rows: int) -> Array:
	var out := []
	if count <= 0:
		return out
	var per_row := ceili(count / float(rows))
	var total_h := rows * card.y + (rows - 1) * GAP
	var y0 := hand.position.y + CARD_LIFT + (hand.size.y - CARD_LIFT - total_h) / 2.0
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
		var w: float = (hand.size.x - (cols - 1) * GAP) / cols
		var h: float = (hand.size.y - CARD_LIFT - (rows - 1) * GAP) / rows
		w = floorf(minf(minf(w, h * T.CARD_ASPECT), CARD_MAX_W))
		if w > best.size.x:
			best = {"size": Vector2(w, floorf(w / T.CARD_ASPECT)), "rows": rows}
	return best


static func _card_gap(width: float, card_w: float, in_row: int) -> float:
	if in_row <= 1:
		return 0.0
	return clampf((width - in_row * card_w) / (in_row - 1), GAP, 28.0)
