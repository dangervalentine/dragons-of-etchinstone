extends "res://tests/base.gd"
## Every symbol the game shows can explain itself.

const Glossary = preload("res://ui/model/glossary.gd")


func _effect_ids(v, found: Dictionary) -> void:
	if v is Dictionary:
		for k in v:
			if ["hardship", "ability", "peril"].has(k) and v[k] != null:
				found[v[k]] = true
			_effect_ids(v[k], found)
	elif v is Array:
		for x in v:
			_effect_ids(x, found)


func test_every_effect_in_the_card_data_has_an_entry() -> void:
	var found := {}
	_effect_ids(JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json")), found)
	ok(found.size() >= 10, "found the effects in the card data (%d)" % found.size())
	for id in found:
		ok(Glossary.has(id), "entry for " + id)
		ok(Glossary.entry(id).short != "", "one-line form for " + id)


func test_every_game_icon_has_an_entry() -> void:
	for f in DirAccess.get_files_at("res://art/icons"):
		if not f.ends_with(".svg"):
			continue
		var id := f.get_basename()
		if id.begins_with("sigil_") or Glossary.NOT_SYMBOLS.has(id):
			continue
		ok(Glossary.has(id), "entry for icon " + id)


func test_entries_are_short_and_complete() -> void:
	for e in Glossary.all():
		ok(e.name != "", "name for " + e.id)
		ok(e.text != "", "text for " + e.id)
		ok(e.text.length() <= 240, "%s is brief (%d characters)" % [e.id, e.text.length()])
		if e.icon != "":
			ok(FileAccess.file_exists("res://art/icons/%s.svg" % e.icon), "icon exists for " + e.id)
