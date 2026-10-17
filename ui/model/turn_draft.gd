extends RefCounted
## The player's uncommitted choices for the current step: which card fills which
## role, the Boost target, a Fuse, and ordered picks for setup and Soak.
## Nothing here touches the game; to_action() is what gets sent to it.

const ROLES := ["spell", "element", "boost"]

var set_count := 1
var sets: Array = [{}, {}]            # role -> card id, one Dictionary per Action Set
var active: Array = [0, "spell"]      # the slot the next tapped card fills
var boost_to: Array = [null, null]       # "attack", "initiative", or null until chosen
var fuse: Variant = null              # {top, bottom, element}
var fuse_pick: Array = []
var mode := "none"                    # none, divert, regroup, fuse_pick, fuse_element
var give_up_reserve := false
var picks: Array = []                 # ordered picks for setup and Soak
var held: Variant = null              # the card picked up, waiting for a place
var reserve: Variant = null           # the card the player put in the Reserve place
var with_reserve := true              # false in the Final Enemy, which keeps no Reserve


func reset(count := 1, reserve_place := true) -> void:
	set_count = count
	with_reserve = reserve_place
	sets = [{}, {}]
	active = [0, "spell"]
	boost_to = [null, null]
	fuse = null
	fuse_pick = []
	mode = "none"
	give_up_reserve = false
	picks = []
	held = null
	reserve = null


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


## Whether the Hand has a Reserve place: one card more than the Action Sets take
## (four in a Region, seven on the Final Journey). After a Divert the Hand is too
## small, and the Final Enemy keeps no Reserve.
func reserve_offered(hand: Array) -> bool:
	return with_reserve and hand.size() > set_count * ROLES.size()


## The card in the Reserve place: the one the player put there, or, once every Role
## is filled, the one card left over, which has nowhere else to go.
func reserve_card(hand: Array) -> Variant:
	if not reserve_offered(hand):
		return null
	if reserve != null and hand.has(reserve):
		return reserve
	if not is_filled():
		return null
	var left := _unplaced(hand)
	return left[0] if left.size() == 1 else null


## The Hand cards waiting for a place, in Hand order.
func floating(hand: Array) -> Array:
	var left := _unplaced(hand)
	var r = reserve_card(hand)
	if r != null:
		left.erase(r)
	return left


## Where a card is: [set, role], "reserve", or null while it floats.
func place_of(id: String, hand: Array) -> Variant:
	var slot = slot_of(id)
	if slot != null:
		return slot
	return "reserve" if reserve_card(hand) == id else null


func _unplaced(hand: Array) -> Array:
	var out := []
	for id in hand:
		if slot_of(id) == null and id != reserve and not (fuse != null and fuse.bottom == id):
			out.append(id)
	return out


## Pick a card up to put it somewhere; picking it again puts it down.
## Returns a message when the card cannot be moved.
func pick(id: String) -> String:
	if fuse != null and fuse.bottom == id:
		return "That card is tucked behind another. Unfuse to use it."
	held = null if held == id else id
	return ""


func put_down() -> void:
	held = null


## Put the held card at `target`: [set, role], "reserve" or "floating". A card
## already there trades places with it, going where the held card came from.
## Returns a message when the place cannot take it.
func put(target: Variant, hand: Array) -> String:
	if held == null:
		return ""
	if typeof(target) == TYPE_STRING and target == "reserve" and not reserve_offered(hand):
		return "There is no Reserve with this Hand."
	var id: String = held
	var from = place_of(id, hand)
	var occupant = null
	if typeof(target) == TYPE_ARRAY:
		occupant = sets[target[0]].get(target[1])
	elif target == "reserve":
		occupant = reserve_card(hand)
	held = null
	if occupant == id or (from == null and typeof(target) == TYPE_STRING and target == "floating"):
		return ""
	_clear(id)
	if occupant != null:
		_clear(occupant)
	_place(id, target)
	if occupant != null:
		_place(occupant, from if from != null else "floating")
	_advance()
	return ""


func _clear(id: String) -> void:
	var slot = slot_of(id)
	if slot != null:
		sets[slot[0]].erase(slot[1])
	if reserve == id:
		reserve = null


func _place(id: String, target: Variant) -> void:
	if typeof(target) == TYPE_ARRAY:
		sets[target[0]][target[1]] = id
	elif typeof(target) == TYPE_STRING and target == "reserve":
		reserve = id


func select_slot(set_index: int, role: String) -> void:
	active = [set_index, role]


## Send a set's Boost to "attack" or "initiative". Against an Enemy it starts
## unchosen, so the player decides rather than a default deciding for them.
func set_boost_to(set_index: int, to: String) -> void:
	boost_to[set_index] = to


## The keyboard's switch: Attack first, then back and forth.
func toggle_boost_to(set_index: int) -> void:
	boost_to[set_index] = "initiative" if boost_to[set_index] == "attack" else "attack"


## The sets whose Boost is placed but not yet sent anywhere, as indexes.
func boost_unchosen() -> Array:
	var out := []
	for i in set_count:
		if sets[i].has("boost") and boost_to[i] == null:
			out.append(i)
	return out


## Enter a mode, or leave it if it is already the current one.
func begin_mode(m: String) -> void:
	fuse_pick = []
	held = null
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
	_clear(fuse.bottom)
	if held == fuse.bottom:
		held = null
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
	if held == id:
		held = null
	if reserve == id:
		reserve = null
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
		a["boost_to"] = boost_to[0] if boost_to[0] != null else "attack"
		a["ranged_discard"] = give_up_reserve
		if fuse != null:
			a["fuse"] = fuse
		return a
	var out := {"sets": []}
	for i in 2:
		var s: Dictionary = sets[i].duplicate()
		s["boost_to"] = boost_to[i] if boost_to[i] != null else "attack"
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
	d.held = held
	d.reserve = reserve
	d.with_reserve = with_reserve
	return d


func _advance() -> void:
	var empty := empty_slots()
	if not empty.is_empty():
		active = empty[0]
