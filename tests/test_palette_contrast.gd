extends "res://tests/base.gd"
## Every colour pair the interface sets text or a meaningful rim in keeps the contrast
## its token promises (specs/019 research R4, FR-010): 4.5:1 for text, 3:1 for rims,
## icons and large numerals. The UI check holds every label to these colours (SC-002).

const T = preload("res://ui/theme/tokens.gd")

const GROUNDS := {"GROUND": T.GROUND, "STONE": T.STONE, "STONE_RAISED": T.STONE_RAISED, "WELL": T.WELL,
	"REGION_GROUND 1": T.REGION_GROUND[1], "REGION_GROUND 2": T.REGION_GROUND[2], "REGION_GROUND 3": T.REGION_GROUND[3],
	"REGION_GROUND 4": T.REGION_GROUND[4], "LAIR_GROUND water": T.LAIR_GROUND.water,
	"LAIR_GROUND lightning": T.LAIR_GROUND.lightning, "LAIR_GROUND shadow": T.LAIR_GROUND.shadow, "LAIR_GROUND fire": T.LAIR_GROUND.fire}


func _at_least(fg: Color, bg: Color, need: float, what: String) -> void:
	ok(T.ratio(fg, bg) >= need, "%s: %.2f, at least %.1f" % [what, T.ratio(fg, bg), need])


func test_text_reads_on_every_ground() -> void:
	for g in GROUNDS:
		_at_least(T.PARCHMENT, GROUNDS[g], 4.5, "PARCHMENT on " + g)
		_at_least(T.PARCHMENT_MUTED, GROUNDS[g], 4.5, "PARCHMENT_MUTED on " + g)
		_at_least(T.BRASS, GROUNDS[g], 4.5, "BRASS on " + g)
		_at_least(T.BRASS_BRIGHT, GROUNDS[g], 4.5, "BRASS_BRIGHT on " + g)
		_at_least(T.JADE, GROUNDS[g], 4.5, "JADE on " + g)
		_at_least(T.DANGER, GROUNDS[g], 4.5, "DANGER on " + g)


func test_ink_reads_on_brass_and_paper() -> void:
	for bg in [T.BRASS, T.BRASS_BRIGHT, T.ether_shade("lightning", "base"), T.ether_shade("lightning", "bright")]:
		_at_least(T.ON_BRASS, bg, 4.5, "ON_BRASS on #" + bg.to_html(false))
	_at_least(T.PAPER_INK, T.PAPER, 4.5, "PAPER_INK on PAPER")
	_at_least(T.PAPER_MUTED, T.PAPER, 4.5, "PAPER_MUTED on PAPER")
	_at_least(T.BRASS_DEEP, T.PAPER, 3.0, "a glossary term's underline on PAPER")


func test_ethers_read_as_plates_pills_and_inks() -> void:
	for e in T.ETHER:
		# A plate, or a highlighted basic action's pill, carries a large numeral (3:1).
		_at_least(T.ether_shade(e, "plate_ink"), T.ether_shade(e, "plate"), 3.0, e + " plate")
		_at_least(T.ether_shade(e, "lit"), T.STONE, 3.0, e + " as an icon on STONE")
		_at_least(T.ether_shade(e, "paper"), T.PAPER, 3.0, e + " as an icon on PAPER")


func test_rims_and_icons_stand_off_the_stone() -> void:
	_at_least(T.EDGE, T.STONE, 3.0, "EDGE on STONE")
	_at_least(T.EDGE, T.GROUND, 3.0, "EDGE on GROUND")
	_at_least(T.STAT_HP, T.STONE, 3.0, "STAT_HP on STONE")


func test_faint_is_for_disabled_labels_only() -> void:
	# Deliberately below 4.5:1, so it reads as unavailable.
	ok(T.ratio(T.PARCHMENT_FAINT, T.STONE) < 4.5, "PARCHMENT_FAINT is fainter than live text")
