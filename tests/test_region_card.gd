extends "res://tests/base.gd"
## The Region Card and the Dragon Card as the Deck shows them (specs/013
## data-model.md, contracts/region-card-face.md): eight panels in printed order
## with every figure printed on them, laid out as the printed card, and no card code.

const ViewState = preload("res://ui/model/view_state.gd")
const RegionCard = preload("res://ui/widgets/region_card.gd")

var db = CardDB.new()

const KEYS := ["enemy:1", "enemy:2", "enemy:3", "enemy:4", "journey:1", "journey:2", "journey:3", "journey:4"]


func test_a_region_card_has_its_eight_encounters_in_printed_order() -> void:
	for region in range(1, 5):
		var m: Dictionary = ViewState.region_card_model(db, region)
		eq(m.panels.size(), 8, "Region %d: eight panels" % region)
		var keys := []
		for p in m.panels:
			keys.append(p.key)
		eq(keys, KEYS, "Region %d: Enemies 1-4 then Journeys 1-4" % region)
		for p in m.panels:
			var d: Dictionary = db.encounter(region, p.kind, p.index)
			eq(p.xp, d.xp, "Region %d %s: its XP Reward" % [region, p.key])
			if p.kind == "enemy":
				eq(p.enemy, {"hp": d.hp, "initiative": d.initiative, "attack": d.attack, "armor": d.armor}, "Region %d %s: its figures" % [region, p.key])
				eq(p.effect, d.ability, "Region %d %s: its Ability" % [region, p.key])
				ok(not p.has("journey"), "Region %d %s: no Journey figures" % [region, p.key])
			else:
				eq(p.journey, {"mp": d.mp, "time_penalty": d.time_penalty}, "Region %d %s: its figures" % [region, p.key])
				eq(p.effect, d.peril, "Region %d %s: its Peril" % [region, p.key])
				ok(not p.has("enemy"), "Region %d %s: no Enemy figures" % [region, p.key])


func test_jade_mountains_reads_as_printed() -> void:
	var m: Dictionary = ViewState.region_card_model(db, 1)
	var e1: Dictionary = m.panels[0]
	eq(e1.enemy, {"hp": 7, "initiative": 8, "attack": {"value": 1, "element": "lightning"}, "armor": [{"element": "lightning", "value": 1}]}, "Enemy 1")
	eq(e1.xp, 4, "Enemy 1's star")
	eq(e1.effect, null, "Enemy 1 has no Ability")
	var j1: Dictionary = m.panels[4]
	eq([j1.journey.mp.value, j1.journey.time_penalty, j1.xp], [12, 2, 5], "Journey 1: MP, Time and star")


func test_regions_pair_on_two_cards_and_no_code_is_carried_to_show() -> void:
	var pairs := []
	var sides := []
	for region in range(1, 5):
		var m: Dictionary = ViewState.region_card_model(db, region)
		ok(not m.has("code"), "Region %d: no code to show" % region)
		pairs.append(m.pair)
		sides.append(m.side)
	eq(pairs[0], pairs[1], "1 and 2 on one card")
	eq(pairs[2], pairs[3], "3 and 4 on one card")
	ok(pairs[0] != pairs[2], "two cards")
	eq(sides, [0, 1, 0, 1], "each card turned to one side or the other")


func test_the_dragon_card_is_the_dragons() -> void:
	for id in db.dragon_ids():
		var d: Dictionary = db.dragon(id)
		var m: Dictionary = ViewState.dragon_card_model(d)
		eq(m.kind, "dragon", "%s: a Dragon Card" % d.id)
		ok(not m.has("code"), "%s: no code to show" % d.id)
		eq(m.targets, ["mp", "hp"], "%s: the MP Tiers, then the HP Tiers" % d.id)


func test_the_card_is_five_by_seven() -> void:
	eq(RegionCard.card_size(500.0), Vector2(500, 700), "500 wide")


func test_the_panels_lie_as_printed() -> void:
	var size := RegionCard.card_size(498.0)
	var card := Rect2(Vector2.ZERO, size)
	var rects := {}
	for key in KEYS:
		rects[key] = RegionCard.panel_rect(size, key)
		ok(card.encloses(rects[key]), "%s is on the card" % key)
		ok(rects[key].end.y <= size.y * 0.955 + 0.5, "%s stays clear of the foot" % key)
	for a in KEYS.size():
		for b in range(a + 1, KEYS.size()):
			ok(not rects[KEYS[a]].intersects(rects[KEYS[b]]), "%s and %s do not overlap" % [KEYS[a], KEYS[b]])
	ok(rects["enemy:1"].end.x <= rects["enemy:2"].position.x, "Enemy 1 left of Enemy 2")
	ok(rects["enemy:3"].end.x <= rects["enemy:4"].position.x, "Enemy 3 left of Enemy 4")
	ok(rects["enemy:2"].end.y <= rects["enemy:3"].position.y, "1 and 2 above 3 and 4")
	for i in range(1, 4):
		ok(rects["journey:%d" % i].end.x <= rects["journey:%d" % (i + 1)].position.x, "Journey %d left of %d" % [i, i + 1])
	for i in range(1, 5):
		ok(rects["journey:%d" % i].position.y >= rects["enemy:4"].end.y, "Journey %d below the Enemies" % i)
		var e: Rect2 = rects["enemy:%d" % i]
		var j: Rect2 = rects["journey:%d" % i]
		ok(absf(e.size.x / e.size.y - 1.45) <= 0.08, "Enemy %d is shaped as printed (%.2f)" % [i, e.size.x / e.size.y])
		ok(absf(j.size.x / j.size.y - 0.6) <= 0.08, "Journey %d is shaped as printed (%.2f)" % [i, j.size.x / j.size.y])
