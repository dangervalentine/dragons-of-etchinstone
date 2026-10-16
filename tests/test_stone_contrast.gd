extends "res://tests/base.gd"
## Text on the stone: every text colour keeps its contrast against the boxes' flat
## faces (where text sits, hovered or not), and against the darkest ground.

const T = preload("res://ui/theme/tokens.gd")
const Stone = preload("res://ui/theme/stone.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")
const Settings = preload("res://ui/model/settings.gd")

const TEXT := {"INK": T.INK, "INK_MUTED": T.INK_MUTED, "GOLD": T.GOLD, "GOOD": T.GOOD,
	"CAUTION": T.CAUTION, "BAD": T.BAD, "HP": T.HP}


## Every ground a player can choose, and the noise fallback.
func _images() -> Array:
	var out := [Stone.noise_image()]
	for n in range(1, Settings.GROUNDS + 1):
		ok(ResourceLoader.exists(Stone.ground_file(n)), "ground %d ships" % n)
		if ResourceLoader.exists(Stone.ground_file(n)):
			out.append((load(Stone.ground_file(n)) as Texture2D).get_image())
	return out


func _extremes() -> Array:
	var lo := Color.WHITE
	var hi := Color.BLACK
	for img in _images():
		var e := _extremes_of(img)
		if T.luminance(e[0]) < T.luminance(lo):
			lo = e[0]
		if T.luminance(e[1]) > T.luminance(hi):
			hi = e[1]
	return [lo, hi]


func _extremes_of(img: Image) -> Array:
	var lo := Color.WHITE
	var hi := Color.BLACK
	for y in range(0, img.get_height(), 2):
		for x in range(0, img.get_width(), 2):
			var c := img.get_pixel(x, y)
			if T.luminance(c) < T.luminance(lo):
				lo = c
			if T.luminance(c) > T.luminance(hi):
				hi = c
	return [lo, hi]


func test_the_stone_stays_inside_its_luminance_band() -> void:
	var e := _extremes()
	ok(T.luminance(e[1]) <= T.luminance(T.BG_RAISED) + 0.0005, "brightest stone %.4f is no lighter than BG_RAISED %.4f" % [T.luminance(e[1]), T.luminance(T.BG_RAISED)])
	ok(T.luminance(e[0]) >= T.STONE_L_MIN - 0.002, "darkest stone %.4f is near the floor" % T.luminance(e[0]))
	ok(T.luminance(e[1]) - T.luminance(e[0]) > 0.005, "the stone has some grain to it")


func test_text_reads_on_every_part_of_the_stone() -> void:
	var e := _extremes()
	# The brightest place text sits: a box's face, under a hover's light wash.
	var bright: Color = T.BG_RAISED.lerp(Color.WHITE, 0.04)
	ok(StoneStyle.GLOW_MAX_UNDER_TEXT == 0.0, "no edge colour reaches the face")
	var inks := TEXT.duplicate()
	for el in T.ETHER:
		inks["ether_ink " + el] = T.ether_ink(el)
	for key in inks:
		var c: Color = inks[key]
		# Gold, HP and the Ether inks colour large numerals and icons, which need 3:1.
		var need := 3.0 if key in ["GOLD", "HP"] or key.begins_with("ether_ink") else 4.5
		ok(T.ratio(c, e[0]) >= need, "%s on the darkest stone: %.2f" % [key, T.ratio(c, e[0])])
		ok(T.ratio(c, bright) >= need, "%s on the brightest face: %.2f, at least %.1f" % [key, T.ratio(c, bright), need])
