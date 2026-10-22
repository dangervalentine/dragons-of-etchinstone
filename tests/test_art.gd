extends "res://tests/base.gd"
## Every Encounter and dragon has its painted picture, each used once, and each credited.

const Art = preload("res://ui/model/art.gd")
const UI = preload("res://ui/theme/theme.gd")


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
	var journeys := []
	for region in range(1, 5):
		journeys.append_array(Art.JOURNEYS[region])
	for name in names:
		if name == Art.FINAL_JOURNEY:
			ok(FileAccess.file_exists("res://art/creatures/%s.svg" % name), name + "'s silhouette exists")
		elif journeys.has(name):
			ok(ResourceLoader.exists("res://art/painted/journeys/%s.png" % name), name + "'s map exists")
		else:
			ok(ResourceLoader.exists("res://art/painted/%s.png" % name), name + "'s picture exists")
		ok(credits.contains("| %s |" % name), name + " is credited")
		ok(not used.has(name), name + " is used once")
		# A Journey's map is drawn still; everything else idles.
		ok(Art.MOTION.has(name) != journeys.has(name), name + " idles if it stands in a panel")
		used[name] = true
	for name in Art.DRAGONS.values():
		for part in ["-full", "-head"]:
			ok(ResourceLoader.exists("res://art/painted/%s%s.png" % [name, part]), name + part + " exists")


func test_every_encounter_has_its_own_name() -> void:
	var seen := {}
	for region in range(1, 5):
		for kind in ["enemy", "journey"]:
			for index in range(1, 5):
				var name: String = Art.encounter_name(region, kind, index)
				ok(name != "" and name.length() <= 18, "%d %s %d is named, briefly" % [region, kind, index])
				ok(not seen.has(name), name + " is used once")
				seen[name] = true


func test_every_bone_is_placed_on_the_art() -> void:
	for name in Art.BONES:
		_check_bones(name)


func test_every_dragon_bends_by_its_own_bones() -> void:
	for name in Art.DRAGONS.values():
		ok(Art.BONES.has(name), name + " has bones measured on its picture")
		ok(Art.BONES.has(name + "-full"), name + " has bones measured on its full-body picture")
		eq(Art.motion(name + "-full"), Art.motion(name), name + "'s full-body picture idles as it does")


func _check_bones(name: String) -> void:
	ok(Art.MOTION.has(name.trim_suffix("-full")), name + " is a picture in use")
	var bones := Art.bones(name)
	ok(bones.size() <= 8, name + " has as many bones as the shader bends")
	for b in bones:
		for at in [b.joint, b.tip]:
			ok(at != Vector2.ZERO and at.x <= 512 and at.y >= 0 and at.y <= 512, "%s's bone is on the art" % name)
		ok(b.reach > 0.0, name + "'s bone reaches")
		ok(Art.MOVES.has(b.motion), name + "'s bone moves in a way the shader knows")
		ok(b.last >= bones.find(b) and b.last < bones.size(), name + "'s bone carries bones in its chain")


func test_every_dragon_has_a_head_region_inside_its_art() -> void:
	for id in CardDB.new().dragon_ids():
		var name: String = Art.dragon(id)
		var r: Rect2 = Art.head(name)
		ok(r != Art.FULL, name + " has a head region")
		ok(r.position.x >= 0 and r.position.y >= 0 and r.end.x <= 512 and r.end.y <= 512, name + " head is inside the art")
		eq(r.size.x, r.size.y, name + " head region is square")
	eq(Art.head("naga"), Art.FULL, "art without a head region is shown whole")


func test_art_crop_cuts_the_head_region_out_of_the_full_art() -> void:
	var head := Art.head("grimroch")
	var cropped := UI.art_crop("grimroch", head)
	ok(cropped is AtlasTexture, "art_crop returns an AtlasTexture")
	var atlas := cropped as AtlasTexture
	ok(atlas.atlas == UI.art("grimroch"), "cut from the dragon's own art")
	var k: float = atlas.atlas.get_width() / 512.0
	eq(atlas.region.position / k, head.position, "region position scales back to the head's own units")
	eq(atlas.region.size / k, head.size, "region size scales back to the head's own units")
