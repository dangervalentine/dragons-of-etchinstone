extends "res://tests/base.gd"
## Where the parts of a Mage Card face sit: inside the card, apart from each other,
## and with numerals no smaller than before the official-style rebuild.

const CardFace = preload("res://ui/widgets/card_face.gd")

const REGIONS := ["level", "name", "key", "cost", "initiative", "basic", "enhanced", "boost", "armor", "ether"]
## Then the Hand's cards in a Region, the Final Battle, and a full nine-card Final
## Enemy Hand since the ordered Hand (specs/009 research R4, R6), and a Region's on a
## long phone since the one-row Hand (specs/010 research R6).
const SIZES := [Vector2(197, 275), Vector2(170, 238), Vector2(280, 392), Vector2(314, 440),
	Vector2(149, 208), Vector2(112, 156), Vector2(96, 134), Vector2(220, 308)]
## Numeral size on a 197 x 275 Hand card before the rebuild
## (specs/005-playfield-polish/baseline.md).
const BASELINE_NUMERAL := 30.1

var db = CardDB.new()


func _one_of_each_ether() -> Array:
	var seen := {}
	for id in db.mage_ids():
		var e: String = db.mage(id).element
		if not seen.has(e):
			seen[e] = id
	return seen.values()


func _face(id: String, sz: Vector2):
	var f = CardFace.new()
	var m: Dictionary = db.mage(id)
	f.size = sz
	f.set_model({"id": id, "name": m.name, "element": m.element, "level": 1, "stats": db.mage_level(id, 1)})
	return f


func test_regions_sit_inside_the_card_and_apart() -> void:
	for id in _one_of_each_ether():
		for sz in SIZES:
			var f = _face(id, sz)
			var card := Rect2(Vector2.ZERO, sz)
			for key in REGIONS:
				var r: Rect2 = f.region_rect(key)
				ok(r.size.x > 0 and r.size.y > 0, "%s %s has a size" % [key, str(sz)])
				ok(card.grow(0.5).encloses(r), "%s inside a %s card, got %s" % [key, str(sz), str(r)])
			for i in REGIONS.size():
				for j in range(i + 1, REGIONS.size()):
					if REGIONS[i] == "ether" or REGIONS[j] == "ether":
						continue
					ok(not f.region_rect(REGIONS[i]).grow(-1).intersects(f.region_rect(REGIONS[j]).grow(-1)),
						"%s and %s apart on a %s card" % [REGIONS[i], REGIONS[j], str(sz)])
			f.free()


func test_numerals_are_no_smaller_than_before() -> void:
	var f = _face(_one_of_each_ether()[0], SIZES[0])
	ok(f.numeral_size() >= BASELINE_NUMERAL, "Hand card numeral %.1f, at least %.1f" % [f.numeral_size(), BASELINE_NUMERAL])
	f.free()


func test_reduced_motion_holds_the_field_still() -> void:
	var Settings = load("res://ui/model/settings.gd")
	var before: String = Settings.motion
	Settings.motion = "reduced"
	var f = _face(_one_of_each_ether()[0], SIZES[0])
	f.motion = true
	eq(f._field.material.get_shader_parameter("motion"), 0.0, "still under reduced motion")
	Settings.motion = "full"
	f.motion = true
	eq(f._field.material.get_shader_parameter("motion"), 1.0, "moving otherwise")
	f.motion = false
	eq(f._field.material.get_shader_parameter("motion"), 0.0, "still when covered")
	Settings.motion = before
	f.free()


func test_longest_line_is_the_widest_so_every_name_fits_two_lines() -> void:
	var font: Font = CardFace._name_font(100)
	var widest := font.get_string_size(CardFace.LONGEST_LINE, HORIZONTAL_ALIGNMENT_LEFT, -1, 100).x
	for id in db.mage_ids():
		var name: String = db.mage(id).name.to_upper()
		var lines: Array = CardFace.name_lines(name, 100, widest)
		ok(lines.size() <= 2, "%s takes at most two lines" % name)
		for line in lines:
			ok(font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 100).x <= widest,
				"%s is no wider than %s" % [line, CardFace.LONGEST_LINE])


func test_names_are_legible_on_a_long_phone() -> void:
	# A Region's Hand card on the phone-tall shape since feature 010 (SC-002): every
	# name, the longest included, at least 17 design units.
	var sz := Vector2(220, 308)
	for name in ["MOTIVATED FLIGHT", "DETERMINED MARCH"]:
		var f = _face(db.mage_ids()[0], sz)
		var n: Rect2 = f.region_rect("name")
		var band: float = f.region_rect("level").size.y / 0.68
		var text_w: float = n.size.x - band * 0.3 - roundf(sz.x * 0.045) * 0.1
		var fs: int = CardFace.name_size(Vector2(text_w, n.size.y))
		ok(fs >= 17, "%s drawn at %d, at least 17" % [name, fs])
		eq(CardFace.name_lines(name, fs, text_w).size() <= 2, true, "%s fits in two lines" % name)
		f.free()
