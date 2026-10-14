extends "res://tests/base.gd"
## The dragon choice shows each dragon's tiers as the Final Battle reads them.

const DragonStats = preload("res://ui/widgets/dragon_stats.gd")


func test_rungs_read_the_tiers_easiest_first() -> void:
	var d: Dictionary = CardDB.new().dragon("grimroch")
	var journey: Array = DragonStats.rungs(d, true)
	eq(journey.size(), 3, "three journey tiers")
	eq(journey[0], {"need": 15, "cost": 4, "element": "water"}, "the first journey tier")
	var battle: Array = DragonStats.rungs(d, false)
	eq(battle.size(), 3, "three battle tiers")
	eq(battle[0], {"need": 22, "cost": 26, "element": ""}, "the first battle tier")
	eq(DragonStats.rung_text(journey[0], true), "Move 15 or more: lose 4 time", "a journey tier in words")
	eq(DragonStats.rung_text(battle[0], false), "Attack 22 or more: take 26 damage", "a battle tier in words")
	var lines: PackedStringArray = DragonStats.ladder_text(d).split("\n")
	eq(lines.size(), 7, "the figures and every tier in the tooltip")
	eq(lines[0], "Initiative 10 · early damage 4", "the figures in words")


func test_every_dragon_has_three_tiers_on_each_ladder() -> void:
	var db = CardDB.new()
	for id in db.dragon_ids():
		for journey in [true, false]:
			var tiers: Array = DragonStats.rungs(db.dragon(id), journey)
			eq(tiers.size(), 3, "%s has three tiers" % id)
			for i in range(1, tiers.size()):
				ok(tiers[i].need > tiers[i - 1].need, "%s needs more for each tier" % id)
