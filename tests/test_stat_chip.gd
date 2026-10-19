extends "res://tests/base.gd"
## The figures on the Encounter and dragon badges: each number is centred on its
## shape's window by its own ink, and fits inside it with its outline.

const StatChip = preload("res://ui/widgets/stat_chip.gd")
const Numerals = preload("res://ui/theme/numerals.gd")

## The badge sizes in use: the column badges and the dragon's small ones.
const SIDES := [44.0, 52.0, 72.0, 96.0]


func test_numbers_sit_in_the_middle_of_their_window() -> void:
	for icon in StatChip.WINDOW:
		for side in SIDES:
			var window := StatChip.window_rect(icon, Rect2(Vector2(3, 5), Vector2(side, side)))
			for n in range(0, 100):
				var f: Dictionary = Numerals.fit(str(n), window)
				var ink: Rect2 = f.ink
				ok(ink.get_center().distance_to(window.get_center()) <= 1.0,
					"%s %d at %d: ink centre %s, window centre %s" % [icon, n, side, ink.get_center(), window.get_center()])


func test_numbers_fit_their_window_with_the_outline() -> void:
	for icon in StatChip.WINDOW:
		for side in SIDES:
			var window := StatChip.window_rect(icon, Rect2(Vector2.ZERO, Vector2(side, side)))
			for n in range(0, 100):
				var f: Dictionary = Numerals.fit(str(n), window)
				var ink: Rect2 = f.ink.grow(f.fs * Numerals.OUTLINE)
				ok(window.grow(1.0).encloses(ink), "%s %d at %d: %s outside %s" % [icon, n, side, ink, window])


func test_one_and_eleven_centre_alike() -> void:
	# A "1" carries side spacing; centring on the advance would push it off-centre.
	var window := StatChip.window_rect("hp", Rect2(0, 0, 72, 72))
	for text in ["1", "11", "4", "10"]:
		var f: Dictionary = Numerals.fit(text, window)
		ok(absf(f.ink.get_center().x - window.get_center().x) <= 0.5, "%s centred across" % text)
