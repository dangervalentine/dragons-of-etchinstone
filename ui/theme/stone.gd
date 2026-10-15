extends RefCounted
## The carved stone every screen is cut into, and the cracks the rift light comes
## through. Both are made from noise once, the first time they are asked for, and
## shared. Bitmaps at art/stone/grain.png and art/stone/cracks.png, if present,
## are used instead.

const T = preload("res://ui/theme/tokens.gd")

const GRAIN_SIZE := 256
const CRACK_SIZE := 512
const GRAIN_FILE := "res://art/stone/grain.png"
const CRACK_FILE := "res://art/stone/cracks.png"

static var _grain: Texture2D
static var _grain_image: Image
static var _cracks: Texture2D


## Seamless stone grain in colour, its luminance kept between STONE_L_MIN and
## STONE_L_MAX so text keeps its contrast anywhere on it.
static func grain() -> Texture2D:
	if _grain == null:
		_grain = ImageTexture.create_from_image(grain_image())
	return _grain


static func grain_image() -> Image:
	if _grain_image != null:
		return _grain_image
	if ResourceLoader.exists(GRAIN_FILE):
		_grain_image = (load(GRAIN_FILE) as Texture2D).get_image()
		return _grain_image
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = 7
	noise.frequency = 0.02
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.fractal_gain = 0.55
	var raw := noise.get_seamless_image(GRAIN_SIZE, GRAIN_SIZE, false, false, 0.1, true)
	# A second, finer layer: the chisel marks in the stone.
	var fine := FastNoiseLite.new()
	fine.noise_type = FastNoiseLite.TYPE_CELLULAR
	fine.seed = 11
	fine.frequency = 0.09
	fine.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
	var marks := fine.get_seamless_image(GRAIN_SIZE, GRAIN_SIZE, false, false, 0.1, true)
	var low := shade(T.STONE_L_MIN)
	var high := shade(T.STONE_L_MAX)
	var img := Image.create(GRAIN_SIZE, GRAIN_SIZE, false, Image.FORMAT_RGB8)
	for y in GRAIN_SIZE:
		for x in GRAIN_SIZE:
			var v := raw.get_pixel(x, y).r * 0.8 + marks.get_pixel(x, y).r * 0.2
			img.set_pixel(x, y, low.lerp(high, clampf(v, 0.0, 1.0)))
	_grain_image = img
	return img


## Thin bright lines where the stone is cracked, dark elsewhere: the mask the rift
## light shows through.
static func cracks() -> Texture2D:
	if _cracks != null:
		return _cracks
	if ResourceLoader.exists(CRACK_FILE):
		_cracks = load(CRACK_FILE)
		return _cracks
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.seed = 3
	noise.frequency = 0.007
	noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	noise.domain_warp_enabled = true
	noise.domain_warp_amplitude = 18.0
	noise.domain_warp_frequency = 0.02
	_cracks = ImageTexture.create_from_image(noise.get_seamless_image(CRACK_SIZE, CRACK_SIZE, true, false, 0.1, true))
	return _cracks


## The stone's colour at a relative luminance: the hue of BG_SURFACE, scaled in
## linear light.
static func shade(target_luminance: float) -> Color:
	var base := T.BG_SURFACE.srgb_to_linear()
	var k := target_luminance / T.luminance(T.BG_SURFACE)
	return Color(base.r * k, base.g * k, base.b * k).linear_to_srgb()
