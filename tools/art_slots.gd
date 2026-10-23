extends SceneTree
## Prints the names of the game's art as one line of JSON, for the console's art import
## (tools/console/art_import.py, specs/018), so the slots it fills are always the ones
## ui/model/art.gd draws and never a copy of them.
## godot --headless --path . -s tools/art_slots.gd

const Art = preload("res://ui/model/art.gd")


func _initialize() -> void:
	var enemies := []
	for region in Art.ENEMIES:
		enemies.append_array(Art.ENEMIES[region])
	var journeys := []
	for region in Art.JOURNEYS:
		journeys.append_array(Art.JOURNEYS[region])
	var out := {"enemies": enemies, "journeys": journeys, "dragons": Art.DRAGONS.values()}
	print("ART_SLOTS " + JSON.stringify(out))
	quit()
