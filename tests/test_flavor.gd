extends "res://tests/base.gd"
## The subtitle and the dragons' flavour lines come from data/flavor.json.

const Flavor = preload("res://ui/model/flavor.gd")


func test_the_subtitle_is_written() -> void:
	ok(Flavor.subtitle() != "", "a subtitle")
	ok(Flavor.subtitle() != Flavor.FALLBACK_SUBTITLE, "the subtitle comes from the file")


func test_every_dragon_has_a_flavour_line() -> void:
	for id in CardDB.new().dragon_ids():
		ok(Flavor.line(id) != "", "%s has a flavour line" % id)


func test_an_unknown_dragon_has_none() -> void:
	eq(Flavor.line("no-such-dragon"), "", "no line for an unknown dragon")
