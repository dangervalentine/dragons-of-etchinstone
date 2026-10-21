extends RefCounted
## The words written for this project around the game: the landing page's
## subtitle, a line of flavour for each dragon, and for each what unlocks it. They live in data/flavor.json,
## meant to be edited by hand; a missing or broken file leaves the old tagline and
## no flavour lines rather than stopping the game.

const PATH := "res://data/flavor.json"
const FALLBACK_SUBTITLE := "A solo card game of four Regions and one dragon."

static var _data = null


static func subtitle() -> String:
	var text = _read().get("subtitle", "")
	return text if text is String and text != "" else FALLBACK_SUBTITLE


## The dragon's flavour line, or "" when it has none.
static func line(dragon_id: String) -> String:
	var dragons = _read().get("dragons", {})
	if not (dragons is Dictionary):
		return ""
	var text = dragons.get(dragon_id, "")
	return text if text is String else ""


## What unlocks the dragon, shown under it while it is locked, or "" when unsaid.
static func unlock(dragon_id: String) -> String:
	var dragons = _read().get("unlock", {})
	if not (dragons is Dictionary):
		return ""
	var text = dragons.get(dragon_id, "")
	return text if text is String else ""


static func _read() -> Dictionary:
	if _data == null:
		_data = {}
		if FileAccess.file_exists(PATH):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
			if parsed is Dictionary:
				_data = parsed
	return _data
