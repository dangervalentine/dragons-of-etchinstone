extends RefCounted
## The ground every screen stands on: one of the generated woodcut patterns in
## art/stone/ (feature 006), chosen in the menu, or, when that file is missing, a
## grain made from noise. Loaded once and shared until the choice changes.

const T = preload("res://ui/theme/tokens.gd")
const Settings = preload("res://ui/model/settings.gd")

const GRAIN_SIZE := 256

static var _grain: Texture2D
static var _grain_image: Image
static var _ground := 0


## The tile for ground `n` (1 to Settings.GROUNDS).
static func ground_file(n: int) -> String:
	return "res://art/stone/ground-%d.png" % n


## Forget the loaded ground, so the next grain() reads the current choice.
static func reset() -> void:
	_grain = null
	_grain_image = null


## Seamless stone grain in colour, its luminance kept between STONE_L_MIN and
## STONE_L_MAX so text keeps its contrast anywhere on it.
static func grain() -> Texture2D:
	if _ground != Settings.ground:
		reset()
	if _grain == null:
		_grain = ImageTexture.create_from_image(grain_image())
	return _grain


static func grain_image() -> Image:
	if _ground != Settings.ground:
		reset()
	if _grain_image != null:
		return _grain_image
	_ground = Settings.ground
	if ResourceLoader.exists(ground_file(_ground)):
		_grain_image = (load(ground_file(_ground)) as Texture2D).get_image()
		return _grain_image
	return noise_image()


## The fallback grain, made from noise: no file needed.
static func noise_image() -> Image:
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
