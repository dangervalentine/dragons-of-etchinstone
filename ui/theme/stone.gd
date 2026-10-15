extends RefCounted
## The stone every screen stands on: a grain made from noise once, the first time
## it is asked for, and shared. A bitmap at art/stone/grain.png, if present, is
## used instead.

const T = preload("res://ui/theme/tokens.gd")

const GRAIN_SIZE := 256
const GRAIN_FILE := "res://art/stone/grain.png"

static var _grain: Texture2D
static var _grain_image: Image


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


## The stone's colour at a relative luminance: the hue of BG_SURFACE, scaled in
## linear light.
static func shade(target_luminance: float) -> Color:
	var base := T.BG_SURFACE.srgb_to_linear()
	var k := target_luminance / T.luminance(T.BG_SURFACE)
	return Color(base.r * k, base.g * k, base.b * k).linear_to_srgb()
