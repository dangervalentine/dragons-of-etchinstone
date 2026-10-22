extends "res://tests/base.gd"
## Every Encounter and dragon has a silhouette, each used once, and each credited.

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


func test_every_rig_has_its_layers_and_pivots() -> void:
	for name in Art.RIGS:
		ok(Art.MOTION.has(name), name + " is a silhouette in use")
		var layers := Art.layers(name)
		ok(layers.size() >= 2 and layers.size() <= 6, name + " has as many layers as the shader draws")
		var arts: Array = layers.map(func(l): return l.art)
		for part in Art.RIGS[name]:
			ok(arts.has("%s-rig-%s" % [name, part]), "%s's %s is one of its layers" % [name, part])
		for i in layers.size():
			var l: Dictionary = layers[i]
			ok(FileAccess.file_exists("res://art/creatures/%s.svg" % l.art), l.art + " exists")
			ok(Art.MOVES.has(l.motion), l.art + " moves in a way the shader knows")
			ok(l.parent >= -1 and l.parent < layers.size() and l.parent != i, l.art + " has a parent in the rig, or none")
			if l.motion != "still":
				var p: Vector2 = l.pivot
				ok(p != Vector2.ZERO and p.x <= 512 and p.y >= 0 and p.y <= 512, l.art + " pivots on the art")
				ok(l.period > 0.0, l.art + " has a period")


func test_every_bone_is_placed_on_the_art() -> void:
	for painted in [false, true]:
		for name in (Art.PAINTED_BONES if painted else Art.BONES):
			_check_bones(name, painted)


func test_every_painted_dragon_bends_by_its_own_bones() -> void:
	for name in Art.DRAGONS.values():
		ok(Art.PAINTED_BONES.has(name), name + " has bones measured on its painted picture")
		ok(Art.bones(name, true) != Art.bones(name), name + "'s painted bones are not the silhouette's")
		ok(Art.PAINTED_BONES.has(name + "-full"), name + " has bones measured on its full-body picture")
		eq(Art.motion(name + "-full"), Art.motion(name), name + "'s full-body picture idles as it does")


func _check_bones(name: String, painted: bool) -> void:
	ok(Art.MOTION.has(name.trim_suffix("-full")), name + " is a silhouette in use")
	var bones := Art.bones(name, painted)
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



func test_a_head_drawn_in_layers_is_shown_alone() -> void:
	eq(Art.head_art("grimroch"), "grimroch-rig-head-whole", "grimroch's head without the body behind it")
	eq(Art.head_art("naga"), "naga", "art not drawn in layers gives its head from the whole")


func test_art_crop_cuts_the_head_region_out_of_the_full_art() -> void:
	var head := Art.head("grimroch")
	var cropped := UI.art_crop("grimroch", head)
	ok(cropped is AtlasTexture, "art_crop returns an AtlasTexture")
	var atlas := cropped as AtlasTexture
	ok(atlas.atlas == UI.art("grimroch"), "cut from the dragon's own art")
	var k: float = atlas.atlas.get_width() / 512.0
	eq(atlas.region.position / k, head.position, "region position scales back to the head's own units")
	eq(atlas.region.size / k, head.size, "region size scales back to the head's own units")
