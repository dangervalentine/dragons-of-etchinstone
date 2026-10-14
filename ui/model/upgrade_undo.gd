extends RefCounted
## Taking back an Upgrade before the Upgrade step is finished. The engine has no
## undo; an Upgrade changes only the card's Level and the XP left, so recording
## both beforehand is enough to put them back exactly.


static func record(game, id: String) -> Dictionary:
	return {"id": id, "level": game.cards[id].level, "xp": game.xp}


static func undo(game, entry: Dictionary) -> void:
	if game.phase != "upgrade":
		return
	game.cards[entry.id].level = entry.level
	game.xp = entry.xp
