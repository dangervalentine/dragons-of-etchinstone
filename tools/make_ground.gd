extends SceneTree
## Turns a generated pattern into the play screen's ground tile (feature 006,
## research R5): seamless, three flat tones, fitted to the stone's luminance band so
## text keeps its contrast, 512 units square.
##   godot --headless --path . -s tools/make_ground.gd -- <in.png> [out.png]
## The output defaults to art/stone/ground-1.png; the game ships ground-1 to
## ground-4, one per pattern the menu offers (ui/theme/stone.gd). Prints the tile's
## luminance range, and PASS when it lies inside [STONE_L_MIN, STONE_L_MAX].

const T = preload("res://ui/theme/tokens.gd")
const Stone = preload("res://ui/theme/stone.gd")

const SIZE := 512
const OUT := "res://art/stone/ground-1.png"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("usage: make_ground.gd -- <in.png> [out.png]")
		quit(2)
		return
	var src := Image.load_from_file(args[0])
	if src == null or src.is_empty():
		print("could not read %s" % args[0])
		quit(1)
		return
	var out_path: String = args[1] if args.size() > 1 else OUT
	var tile := make(src)
	var lo := 1.0
	var hi := 0.0
	for y in tile.get_height():
		for x in tile.get_width():
			var l := T.luminance(tile.get_pixel(x, y))
			lo = minf(lo, l)
			hi = maxf(hi, l)
	var path := ProjectSettings.globalize_path(out_path) if out_path.begins_with("res://") else out_path
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	tile.save_png(path)
	var inside := lo >= T.STONE_L_MIN - 0.0005 and hi <= T.STONE_L_MAX + 0.0005
	print("wrote %s: luminance %.4f to %.4f, band %.4f to %.4f: %s" % [path, lo, hi, T.STONE_L_MIN, T.STONE_L_MAX, "PASS" if inside else "FAIL"])
	quit(0 if inside else 1)


## One pass of the seam blend, across (`across`) or down.
static func _wrap_blend(lum: PackedFloat32Array, w: int, h: int, across: bool) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(w * h)
	for y in h:
		for x in w:
			var t := (2.0 * x / (w - 1) - 1.0) if across else (2.0 * y / (h - 1) - 1.0)
			var k := 1.0 - absf(t)
			var sx := (x + w / 2) % w if across else x
			var sy := y if across else (y + h / 2) % h
			out[y * w + x] = lum[y * w + x] * k + lum[sy * w + sx] * (1.0 - k)
	return out


## A heavy blur of a seamless square image that wraps at its edges: tiled 3 x 3,
## shrunk to a few texels and grown back, then the middle tile cut out.
static func _broad(img: Image) -> Image:
	var n := img.get_width()
	var big := Image.create(n * 3, n * 3, false, img.get_format())
	for ty in 3:
		for tx in 3:
			big.blit_rect(img, Rect2i(0, 0, n, n), Vector2i(tx * n, ty * n))
	big.resize(24, 24, Image.INTERPOLATE_BILINEAR)
	big.resize(n * 3, n * 3, Image.INTERPOLATE_CUBIC)
	return big.get_region(Rect2i(n, n, n, n))


## The whole recipe: luminance, seamless, scaled, three tones in the stone's colours.
static func make(src: Image) -> Image:
	var img := src.duplicate() as Image
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	# Luminance only: the pattern's lines, not its colours.
	var lum := PackedFloat32Array()
	lum.resize(w * h)
	for y in h:
		for x in w:
			lum[y * w + x] = T.luminance(img.get_pixel(x, y))
	# Seamless, one direction at a time: blend the image with a copy shifted by half
	# a tile across, weighted toward the copy at the left and right edges (where the
	# copy wraps cleanly) and toward the original down the middle (where the copy
	# has its seam); then the same down the tile.
	lum = _wrap_blend(lum, w, h, true)
	lum = _wrap_blend(lum, w, h, false)
	var blend := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var v := lum[y * w + x]
			blend.set_pixel(x, y, Color(v, v, v))
	blend.resize(SIZE, SIZE, Image.INTERPOLATE_BILINEAR)
	# Take out the broad shading (a model's lit corner, a vignette): what is left is
	# the lines, even across the tile, so no grid shows where tiles meet.
	var broad := _broad(blend)
	# Three flat tones, split at the 33rd and 66th percentiles.
	var values := PackedFloat32Array()
	for y in SIZE:
		for x in SIZE:
			values.append(blend.get_pixel(x, y).r - broad.get_pixel(x, y).r)
	var sorted := values.duplicate()
	sorted.sort()
	var cut1: float = sorted[int(sorted.size() * 0.33)]
	var cut2: float = sorted[int(sorted.size() * 0.66)]
	var tones := [Stone.shade(T.STONE_L_MIN), Stone.shade((T.STONE_L_MIN + T.STONE_L_MAX) / 2.0), Stone.shade(T.STONE_L_MAX)]
	var out := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var v: float = values[y * SIZE + x]
			out.set_pixel(x, y, tones[0] if v < cut1 else (tones[1] if v < cut2 else tones[2]))
	return out
