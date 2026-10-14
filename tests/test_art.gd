extends "res://tests/base.gd"
## Every Encounter and dragon has a silhouette, each used once, and each credited.

const Art = preload("res://ui/model/art.gd")


func test_every_encounter_and_dragon_has_art_that_exists_and_is_credited() -> void:
	var credits := FileAccess.get_file_as_string("res://art/creatures/CREDITS.md")
	var used := {}
	var names := []
	for region in range(1, 5):
		for kind in ["enemy", "journey"]:
			for index in range(1, 5):
				names.append(Art.encounter(region, kind, index))
	for id in CardDB.new().dragon_ids():
		names.append(Art.dragon(id))
	names.append(Art.FINAL_JOURNEY)
	eq(names.size(), 37, "32 Encounters, 4 dragons and the Final Journey")
	for name in names:
		ok(FileAccess.file_exists("res://art/creatures/%s.svg" % name), name + " exists")
		ok(credits.contains("| %s |" % name), name + " is credited")
		ok(not used.has(name), name + " is used once")
		ok(Art.MOTION.has(name), name + " has an idle motion")
		used[name] = true


func test_every_encounter_has_its_own_name() -> void:
	var seen := {}
	for region in range(1, 5):
		for kind in ["enemy", "journey"]:
			for index in range(1, 5):
				var name: String = Art.encounter_name(region, kind, index)
				ok(name != "" and name.length() <= 18, "%d %s %d is named, briefly" % [region, kind, index])
				ok(not seen.has(name), name + " is used once")
				seen[name] = true


func test_every_moving_part_has_its_body_and_part() -> void:
	for name in Art.PARTS:
		var rig: Dictionary = Art.PARTS[name]
		ok(Art.MOTION.has(name), name + " is a silhouette in use")
		ok(FileAccess.file_exists("res://art/creatures/%s-base.svg" % name), name + " has a body")
		ok(FileAccess.file_exists("res://art/creatures/%s-part.svg" % name), name + " has a part")
		eq(rig.motion, "hinge", name + " moves in a way the shader knows")
		var p: Vector2 = rig.pivot
		ok(p.x >= 0 and p.x <= 512 and p.y >= 0 and p.y <= 512, name + " pivots on the art")
