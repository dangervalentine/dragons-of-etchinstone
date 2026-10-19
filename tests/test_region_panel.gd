extends "res://tests/base.gd"
## One printed Encounter panel (specs/013 contracts/region-card-face.md): where each
## part sits, as a share of the panel, so it reads alike on the card and zoomed in.

const RegionPanel = preload("res://ui/widgets/region_panel.gd")


func _all(at: Dictionary) -> Array:
	var out := [at.art, at.xp, at.discs, at.number]
	for row in at.badges:
		out.append_array(row)
	return out


func test_every_part_is_inside_the_panel() -> void:
	for kind in ["enemy", "journey"]:
		for s in [Vector2(167, 115), Vector2(92, 158), Vector2(376, 259), Vector2(300, 500)]:
			var frame := Rect2(Vector2.ZERO, s).grow(0.5)
			for r in _all(RegionPanel.parts(s, kind, 2)):
				ok(frame.encloses(r), "%s at %s: %s inside" % [kind, s, r])


func test_the_parts_grow_with_the_panel() -> void:
	for kind in ["enemy", "journey"]:
		var a := RegionPanel.parts(Vector2(150, 110), kind, 2)
		var b := RegionPanel.parts(Vector2(300, 220), kind, 2)
		var ra := _all(a)
		var rb := _all(b)
		for i in ra.size():
			ok(rb[i].position.is_equal_approx(ra[i].position * 2.0) and rb[i].size.is_equal_approx(ra[i].size * 2.0),
				"%s part %d doubles with the panel" % [kind, i])


func test_an_enemy_has_its_four_badge_rows_down_the_left() -> void:
	var s := Vector2(220, 152)
	var one := RegionPanel.parts(s, "enemy", 1)
	eq(one.badges.size(), 4, "HP, Initiative, Attack, Armor")
	for row in one.badges:
		ok(row[0].end.x <= s.x * 0.25, "down the left edge")
	for i in 3:
		ok(one.badges[i][0].end.y <= one.badges[i + 1][0].position.y + 0.01, "row %d above row %d" % [i, i + 1])
	var two := RegionPanel.parts(s, "enemy", 2)
	eq(two.badges[3].size(), 2, "two Armor shields")
	ok(two.badges[3][0].end.x <= two.badges[3][1].position.x + 1.0 and is_equal_approx(two.badges[3][0].position.y, two.badges[3][1].position.y), "side by side")
	ok(is_equal_approx(two.badges[3][0].size.x, one.badges[3][0].size.x * 0.92), "each a little smaller")
	ok(one.xp.position.x > s.x * 0.6 and one.xp.position.y > s.y * 0.6, "the star at the bottom right")
	ok(one.discs.position.x > s.x * 0.6 and one.discs.end.y < s.y * 0.4, "the Ability at the top right")
	ok(one.number.position.x >= one.art.position.x and one.number.end.y < s.y * 0.3, "the number at the art's top left")


func test_a_journey_has_its_figures_in_the_top_strip() -> void:
	var s := Vector2(120, 208)
	var at := RegionPanel.parts(s, "journey")
	eq(at.badges.size(), 2, "MP and Time")
	for row in at.badges:
		ok(row[0].end.y <= s.y * 0.25 + 0.01, "in the top quarter")
	ok(at.badges[0][0].end.x <= at.badges[1][0].position.x, "MP left of Time")
	ok(absf(at.xp.get_center().x - s.x / 2.0) < 0.5 and at.xp.position.y > s.y * 0.7, "the star at the foot, centred")
	ok(at.art.position.y >= s.y * 0.25 - 0.01, "the landscape below the strip")


func test_discs_show_only_for_an_effect() -> void:
	var p := {"key": "enemy:1", "kind": "enemy", "index": 1, "title": "", "art": "", "element": "fire", "xp": 4, "effect": null,
		"enemy": {"hp": 7, "initiative": 8, "attack": {"value": 1, "element": "fire"}, "armor": [{"element": "fire", "value": 1}]}}
	var v = RegionPanel.new()
	v.render(p)
	eq(v.discs().size(), 0, "no Ability, no disc")
	p.effect = "ranged"
	v.render(p, "ambush")
	eq(v.discs().size(), 2, "the Ability and the Hardship")
	v.free()
