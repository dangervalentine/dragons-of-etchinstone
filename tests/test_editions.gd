extends "res://tests/base.gd"
## Classic or House rules: what each edition offers and lets a game start with.

const Editions = preload("res://ui/model/editions.gd")
const Settings = preload("res://ui/model/settings.gd")
const Game = preload("res://engine/game.gd")


func test_classic_offers_only_the_rulebook() -> void:
	var was: bool = Settings.house_rules
	Settings.house_rules = false
	ok(Editions.offers("cavalier") and Editions.offers("glass_cannon"), "the rulebook's rules")
	ok(not Editions.offers("persistent_xp"), "no house rule")
	var opts := Editions.apply({"difficulty": "hard", "cavalier": true, "persistent_xp": true})
	eq(opts.persistent_xp, false, "a remembered house rule is turned off")
	eq(opts.cavalier, true, "the rulebook's rules are kept")
	eq(opts.difficulty, "hard", "and everything else")
	eq(Editions.text("{house}Kept"), "", "a house line is left out")
	eq(Editions.text("Plain"), "Plain", "any other line is as it is")
	Settings.house_rules = was


func test_house_rules_offer_and_keep_everything() -> void:
	var was: bool = Settings.house_rules
	Settings.house_rules = true
	ok(Editions.offers("persistent_xp"), "the house rule")
	eq(Editions.apply({"persistent_xp": true}).persistent_xp, true, "kept")
	eq(Editions.text("{house}Kept"), "Kept", "a house line, unmarked")
	Settings.house_rules = was


## Every house rule is a game option the engine reads; the engine has no edition.
func test_every_house_rule_is_off_by_default_in_a_game() -> void:
	var g = Game.new(CardDB.new(), {"seed": 1, "dragon": "rodving"})
	for key in Editions.HOUSE_RULES:
		eq(g.options.get(key, false), false, key + " off unless asked for")
	ok(not g.keeps_xp(), "a game without the option is Classic")
