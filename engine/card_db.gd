extends RefCounted
## Read-only access to data/cards.json.

const PATH := "res://data/cards.json"

var _mages := {}
var _regions := {}
var _dragons := {}


func _init() -> void:
	var data = _ints(JSON.parse_string(FileAccess.get_file_as_string(PATH)))
	for m in data.mage_cards:
		_mages[m.id] = m
	for r in data.regions:
		_regions[r.region] = r
	for d in data.dragons:
		_dragons[d.id] = d


func mage_ids() -> Array:
	return _mages.keys()


func mage(id: String) -> Dictionary:
	return _mages[id]


func mage_level(id: String, level: int) -> Dictionary:
	return _mages[id].levels[level - 1]


func region(number: int) -> Dictionary:
	return _regions[number]


## kind is "enemy" or "journey"; index is 1-4 as printed on the Key Card.
func encounter(region_number: int, kind: String, index: int) -> Dictionary:
	var list = _regions[region_number].enemies if kind == "enemy" else _regions[region_number].journeys
	return list[index - 1]


func dragon_ids() -> Array:
	return _dragons.keys()


func dragon(id: String) -> Dictionary:
	return _dragons[id]


# JSON numbers parse as floats; every number in the card data is a whole number.
func _ints(v):
	match typeof(v):
		TYPE_FLOAT:
			return int(v)
		TYPE_ARRAY:
			return v.map(_ints)
		TYPE_DICTIONARY:
			var out := {}
			for k in v:
				out[k] = _ints(v[k])
			return out
	return v
