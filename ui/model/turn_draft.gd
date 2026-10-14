extends RefCounted
## The player's uncommitted choices for the current step: which card fills which
## role, the Boost target, a Fuse, and ordered picks for setup and Soak.
## Nothing here touches the game; to_action() is what gets sent to it.

const ROLES := ["spell", "element", "boost"]

var set_count := 1
var sets: Array = [{}, {}]            # role -> card id, one Dictionary per Action Set
var active: Array = [0, "spell"]      # the slot the next tapped card fills
var boost_to: Array = ["attack", "attack"]
var fuse: Variant = null              # {top, bottom, element}
var fuse_pick: Array = []
var mode := "none"                    # none, divert, regroup, fuse_pick, fuse_element
var give_up_reserve := false
var picks: Array = []                 # ordered picks for setup and Soak


func reset(count := 1) -> void:
	set_count = count
	sets = [{}, {}]
	active = [0, "spell"]
	boost_to = ["attack", "attack"]
	fuse = null
	fuse_pick = []
	mode = "none"
	give_up_reserve = false
	picks = []


## [set index, role] of the slot a card fills, or null.
func slot_of(id: String) -> Variant:
	for i in sets.size():
		for role in ROLES:
			if sets[i].get(role) == id:
				return [i, role]
	return null


func is_filled() -> bool:
	for i in set_count:
		if sets[i].size() < ROLES.size():
			return false
	return true


## The empty slots, in order, as [set index, role].
func empty_slots() -> Array:
	var out := []
	for i in set_count:
		for role in ROLES:
			if not sets[i].has(role):
				out.append([i, role])
	return out


## Tapping a Hand card: put it in the active slot, or take it back if it is placed.
## Returns a message when the tap is refused.
func tap(id: String) -> String:
	if slot_of(id) != null:
		take_back(id)
		return ""
	if fuse != null and fuse.bottom == id:
		return "That card is tucked behind another. Unfuse to use it."
	sets[active[0]][active[1]] = id
	_advance()
	return ""


func take_back(id: String) -> void:
	var slot = slot_of(id)
	if slot != null:
		sets[slot[0]].erase(slot[1])
		active = slot


func select_slot(set_index: int, role: String) -> void:
	active = [set_index, role]


func toggle_boost_to(set_index: int) -> void:
	boost_to[set_index] = "initiative" if boost_to[set_index] == "attack" else "attack"


## Enter a mode, or leave it if it is already the current one.
func begin_mode(m: String) -> void:
	fuse_pick = []
	mode = "none" if mode == m else m


func cancel_mode() -> void:
	fuse_pick = []
	mode = "none"


## One of the two cards of a Fuse: first the card to play, then the card to tuck.
func pick_for_fuse(id: String, db) -> String:
	if mode != "fuse_pick" or fuse_pick.has(id):
		return ""
	fuse_pick.append(id)
	if fuse_pick.size() < 2:
		return ""
	if db.mage(fuse_pick[0]).element != db.mage(fuse_pick[1]).element:
		cancel_mode()
		return "Fused cards must share an Ether element."
	mode = "fuse_element"
	return ""


func choose_fuse_element(element: String) -> void:
	if mode != "fuse_element" or fuse_pick.size() != 2:
		return
	fuse = {"top": fuse_pick[0], "bottom": fuse_pick[1], "element": element}
	var slot = slot_of(fuse.bottom)
	if slot != null:
		sets[slot[0]].erase(slot[1])
	cancel_mode()
	_advance()


func unfuse() -> void:
	fuse = null
	cancel_mode()


## Forget a card that has left the Hand.
func drop(id: String) -> void:
	var slot = slot_of(id)
	if slot != null:
		sets[slot[0]].erase(slot[1])
	if fuse != null and (fuse.top == id or fuse.bottom == id):
		fuse = null
	picks.erase(id)
	_advance()


func toggle_pick(id: String) -> void:
	if picks.has(id):
		picks.erase(id)
	else:
		picks.append(id)


## The action Dictionary the engine's play() or play_final() takes.
func to_action() -> Dictionary:
	if set_count == 1:
		var a: Dictionary = sets[0].duplicate()
		a["boost_to"] = boost_to[0]
		a["ranged_discard"] = give_up_reserve
		if fuse != null:
			a["fuse"] = fuse
		return a
	var out := {"sets": []}
	for i in 2:
		var s: Dictionary = sets[i].duplicate()
		s["boost_to"] = boost_to[i]
		out.sets.append(s)
	if fuse != null:
		out["fuse"] = fuse
	return out


func duplicate_draft():
	var d = get_script().new()
	d.set_count = set_count
	d.sets = sets.duplicate(true)
	d.active = active.duplicate()
	d.boost_to = boost_to.duplicate()
	d.fuse = fuse.duplicate() if fuse != null else null
	d.fuse_pick = fuse_pick.duplicate()
	d.mode = mode
	d.give_up_reserve = give_up_reserve
	d.picks = picks.duplicate()
	return d


func _advance() -> void:
	var empty := empty_slots()
	if not empty.is_empty():
		active = empty[0]
