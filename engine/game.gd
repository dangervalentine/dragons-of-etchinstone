extends RefCounted
## One solo game: four Regions and the Final Battle.
##
## Every player action returns "" on success or a message saying why it was refused;
## a refused action changes nothing. `phase` says which actions are open:
##   setup          choose_setup_cards()   (difficulties with a choice to make)
##   challenge      divert(), play()
##   penalty        soak()
##   upgrade        upgrade(), finish()
##   poison         soak()
##   final_journey  regroup(), play_final()
##   final_enemy    play_final()
##   final_soak     soak()
##   won / lost

const Rules = preload("res://engine/rules.gd")

const ROLES := ["spell", "element", "boost"]
const HAND_SIZE := 4
const FINAL_JOURNEY_HAND := 7
const MAX_DIVERTS := 2
const KNOCK_OUT_DISCARD := 4
# [cards drawn and offered, cards changed, new level]
const DIFFICULTY := {
	"casual": [5, 4, 3], "easy": [5, 2, 3], "normal": [5, 0, 2],
	"hard": [5, 2, 1], "impossible": [5, 5, 1], "dont_even_try": [7, 7, 1],
}

var db
var options: Dictionary
var dragon: Dictionary
var cards := {}          # card id -> {"level": 1-4}
var deck: Array = []     # index 0 is the top (the Key Card)
var hand: Array = []
var discard: Array = []
var trash: Array = []
var region := 1
var phase := "challenge"
var diverts := 0
var xp := 0
var damage_due := 0
var damage_element := ""
var downgraded: Array = []  # cards Downgraded this Encounter
var result := {}            # outcome of the last play
var setup_offer: Array = [] # cards the player chooses from during setup
var setup_picks := 0        # how many of them must be chosen
var setup_level := 2        # the Level the chosen cards are set to
var carried_damage := 0     # Final Journey time penalty the deck could not pay
var _action := {}
var _discard_reserve := false
var _pending_poison := 0
var _regrouped := false
var _rng := RandomNumberGenerator.new()


func _init(card_db, opts := {}) -> void:
	db = card_db
	options = opts
	dragon = db.dragon(opts.get("dragon", db.dragon_ids()[0]))
	_rng.seed = opts.get("seed", randi())
	for id in db.mage_ids():
		cards[id] = {"level": 2}
	deck = cards.keys()
	_shuffle(deck)
	var d: Array = DIFFICULTY[opts.get("difficulty", "normal")]
	setup_offer = deck.slice(0, d[0])
	setup_offer.sort()
	setup_picks = d[1]
	setup_level = d[2]
	if setup_picks > 0 and setup_picks < setup_offer.size():
		phase = "setup"
	else:
		_finish_setup(setup_offer.slice(0, setup_picks))


## Setup only: the cards whose starting Level the difficulty changes.
func choose_setup_cards(ids: Array) -> String:
	if phase != "setup":
		return "Setup is already finished."
	if ids.size() != setup_picks:
		return "Choose exactly %d cards." % setup_picks
	for i in ids.size():
		if not setup_offer.has(ids[i]) or ids.find(ids[i]) != i:
			return "Choose different cards from the ones offered."
	_finish_setup(ids)
	return ""


func _finish_setup(ids: Array) -> void:
	for id in ids:
		cards[id].level = setup_level
	if ids.size() > 0:
		_shuffle(deck)
	_draw(HAND_SIZE)
	phase = "challenge"


func key_card():
	return deck[0] if deck.size() > 0 else null


func level_data(id: String) -> Dictionary:
	return db.mage_level(id, cards[id].level)


## The Encounter the Key Card points at: {kind, index, hardship, data}.
func encounter() -> Dictionary:
	var e = level_data(key_card()).encounter
	return {"kind": e.type, "index": e.index, "hardship": level_data(key_card()).hardship,
		"data": db.encounter(region, e.type, e.index)}


func divert(card: String) -> String:
	if phase != "challenge":
		return "You can only Divert in the Challenge Phase."
	if diverts >= MAX_DIVERTS:
		return "You can only Divert twice per Encounter."
	if not hand.has(card):
		return "That card is not in your Hand."
	if deck.size() < 2:
		return "There is no other Key Card to Divert to."
	discard.append(deck.pop_front())
	_move(card, hand, discard)
	diverts += 1
	return ""


## action: {spell, element, boost} card ids, plus optional boost_to ("attack"/"initiative"),
## fuse {top, bottom, element} and ranged_discard.
func play(action: Dictionary) -> String:
	var r := preview(action)
	if r.get("error", "") != "":
		return r.error
	var fuse = action.get("fuse")
	var reserve = _reserve([action], fuse)
	result = r
	_action = {"cards": _roles(action), "reserve": reserve, "fuse": fuse}
	_discard_reserve = result.get("discard_reserve", false)
	xp = result.xp
	damage_element = result.damage_element
	var damage: int = result.damage + _pay_time(result.time_penalty)
	var poison: int = result.get("poison", 0)
	if poison > 0:
		var kept := 1 if reserve != null and not _discard_reserve else 0
		if kept + deck.size() < HAND_SIZE + 1:
			damage += poison  # no next Hand this Region: it lands on this one
		else:
			_pending_poison = poison
	result["knocked_out"] = false
	_take_damage(damage, "upgrade")
	return ""


## What play(action) would resolve to, without doing it. A refused action
## comes back as {"error": message}.
func preview(action: Dictionary) -> Dictionary:
	if phase != "challenge":
		return {"error": "There is no Encounter to play."}
	var err := _check_fuse(action.get("fuse"), [action])
	if err == "":
		err = _check_set(action)
	if err == "" and not action.has("spell"):
		err = "An Action Set needs a Spell."
	if err != "":
		return {"error": err}
	var fuse = action.get("fuse")
	if fuse != null and hand.size() < HAND_SIZE:
		return {"error": "You need a full Hand to Fuse."}
	var free := hand.size() - (1 if fuse != null else 0)
	if free >= ROLES.size() and _roles(action).size() < ROLES.size():
		return {"error": "Assign a Spell, an Element and a Boost."}

	var reserve = _reserve([action], fuse)
	var s := _set_stats(action, fuse)
	s["reserve_boost"] = level_data(reserve).boost if reserve != null else 0
	s["has_reserve"] = reserve != null
	s["ranged_discard"] = action.get("ranged_discard", false)
	var enc := encounter()
	if enc.kind == "enemy":
		return Rules.resolve_enemy(enc.data, enc.hardship, s)
	return Rules.resolve_journey(enc.data, enc.hardship, s)


## Downgrade the given Hand cards, in order, to Soak the damage due.
func soak(ids: Array) -> String:
	if not ["penalty", "poison", "final_soak"].has(phase):
		return "There is no damage to Soak."
	var total := 0
	for i in ids.size():
		var id = ids[i]
		if not hand.has(id) or ids.find(id) != i:
			return "Choose different cards from your Hand."
		if downgraded.has(id):
			return "A card can only be Downgraded once per Encounter."
		if total >= damage_due:
			return "That is more cards than the damage needs."
		total += _soak_value(id)
	if total < damage_due:
		return "Those cards do not Soak all of the damage."
	for id in ids:
		_downgrade(id)
	damage_due = 0
	match phase:
		"penalty":
			phase = "upgrade"
		"poison":
			downgraded = []
			phase = "challenge"
		"final_soak":
			phase = "won"
	return ""


func upgrade(card: String) -> String:
	if phase != "upgrade":
		return "You can only Upgrade in the Upgrade Phase."
	if not hand.has(card):
		return "You can only Upgrade cards in your Hand."
	if downgraded.has(card):
		return "A card Downgraded this Encounter cannot be Upgraded."
	var cost = level_data(card).upgrade_cost
	if cost == null:
		return "That card is already at its highest Level."
	if cost > xp:
		return "Not enough XP."
	xp -= cost
	cards[card].level += 1
	return ""


## End the Upgrade Phase: Cleanup, then the next Encounter, Region or the Final Battle.
func finish() -> String:
	if phase != "upgrade":
		return "Finish the current phase first."
	var spent: Array = _action.cards.values()
	if _action.fuse != null:
		spent.append(_action.fuse.bottom)
	if _discard_reserve and _action.reserve != null:
		spent.append(_action.reserve)
	for id in spent:
		if hand.has(id):
			_move(id, hand, discard)
	xp = 0
	diverts = 0
	downgraded = []
	_action = {}
	if hand.size() + deck.size() < HAND_SIZE + 1:
		_pending_poison = 0
		_gather()
		# A Region needs a Hand and a Key Card; with fewer cards left, go straight to the dragon.
		if region < 4 and deck.size() >= HAND_SIZE + 1:
			region += 1
			phase = "challenge"
			_draw(HAND_SIZE)
		else:
			region = 4
			phase = "final_journey"
			_draw(FINAL_JOURNEY_HAND)
		return ""
	_draw(HAND_SIZE - hand.size())
	phase = "challenge"
	if _pending_poison > 0:
		damage_element = ""
		_take_damage(_pending_poison, "challenge")
		if phase == "penalty":
			phase = "poison"
		_pending_poison = 0
	return ""


## Final Journey only, once per game: discard one card and redraw the rest.
func regroup(card: String) -> String:
	if phase != "final_journey":
		return "You can only Regroup on the Final Journey."
	if _regrouped:
		return "You can only Regroup once per game."
	if not hand.has(card):
		return "That card is not in your Hand."
	_move(card, hand, discard)
	_shuffle(hand)
	deck.append_array(hand)
	hand = []
	_draw(FINAL_JOURNEY_HAND)
	_regrouped = true
	return ""


## action: {sets: [set, set], fuse}. Each set is {spell, element, boost, boost_to}.
func play_final(action: Dictionary) -> String:
	var r := preview_final(action)
	if r.get("error", "") != "":
		return r.error
	result = r
	if r.tier < 0:
		phase = "lost"
	elif phase == "final_journey":
		discard.append_array(hand)
		hand = []
		carried_damage += _pay_time(r.time_penalty)
		_draw(deck.size())
		phase = "final_enemy"
	else:
		damage_element = dragon.early_damage.element
		damage_due = r.damage
		downgraded = []
		phase = "final_soak" if r.survivable else "lost"
	return ""


## What play_final(action) would resolve to, without doing it.
func preview_final(action: Dictionary) -> Dictionary:
	if phase != "final_journey" and phase != "final_enemy":
		return {"error": "This is not the Final Battle."}
	var sets: Array = action.get("sets", [])
	if sets.size() != 2:
		return {"error": "Build two Action Sets."}
	var fuse = action.get("fuse")
	var err := _check_fuse(fuse, sets)
	var role_count := 0
	var used := []
	for s in sets:
		if err == "":
			err = _check_set(s, used)
		used.append_array(_roles(s).values())
		role_count += _roles(s).size()
	if err != "":
		return {"error": err}
	var free := hand.size() - (1 if fuse != null else 0)
	if role_count < mini(2 * ROLES.size(), free):
		return {"error": "Assign a Spell, an Element and a Boost in both Action Sets."}
	var stats := sets.map(func(s): return _set_stats(s, fuse))
	if phase == "final_journey":
		return _final_journey(sets, stats, fuse)
	return _final_enemy(sets, stats)


## Sum of the Levels of every card not Trashed; zero unless the game is won.
func score() -> int:
	if phase != "won":
		return 0
	var total := 0
	for id in cards:
		if not trash.has(id):
			total += cards[id].level
	return total


func _final_journey(sets: Array, stats: Array, fuse) -> Dictionary:
	var tiers: Array = dragon.mp_tiers
	var move := 0
	var matched := false
	for s in stats:
		var act := Rules.action(s.spell, s.element, ["move"])
		move += act.value + s.boost
		matched = matched or (act.enhanced and act.element == tiers[0].mp.element)
	var reserve = _reserve(sets, fuse)
	if matched and reserve != null:
		move += level_data(reserve).boost
	var tier := _tier(move, tiers.map(func(t): return t.mp.value))
	return {"move": move, "tier": tier,
		"time_penalty": tiers[tier].time_penalty if tier >= 0 else 0}


func _final_enemy(sets: Array, stats: Array) -> Dictionary:
	var attack := 0
	var initiative := 0
	var elements := []
	for i in stats.size():
		var s: Dictionary = stats[i]
		var to_initiative: bool = sets[i].get("boost_to", "attack") == "initiative"
		var act := Rules.action(s.spell, s.element, ["attack"])
		attack += act.value + (0 if to_initiative else s.boost)
		initiative += s.initiative + (s.boost if to_initiative else 0)
		if act.enhanced:
			elements.append(act.element)
	attack = maxi(0, attack - Rules._armor(dragon.armor, elements))
	var tiers: Array = dragon.hp_tiers
	var tier := _tier(attack, tiers.map(func(t): return t.hp))
	var early: bool = initiative < dragon.initiative
	var out := {"attack": attack, "initiative": initiative, "tier": tier, "early": early,
		"damage": 0, "survivable": false}
	if tier < 0:
		return out
	out.damage = tiers[tier].attack.value + (dragon.early_damage.value if early else 0) + carried_damage
	var capacity := 0
	for id in hand:
		capacity += Rules.soak_value(level_data(id), dragon.early_damage.element, options.get("glass_cannon", false))
	out.survivable = capacity >= out.damage
	return out


## Index of the highest tier reached, or -1.
func _tier(value: int, thresholds: Array) -> int:
	var tier := -1
	for i in thresholds.size():
		if value >= thresholds[i]:
			tier = i
	return tier


func _check_set(s: Dictionary, used := []) -> String:
	var ids := _roles(s).values()
	if ids.is_empty():
		return ""
	if not s.has("spell") or s.spell == null:
		return "An Action Set needs a Spell."
	for i in ids.size():
		if not hand.has(ids[i]):
			return "That card is not in your Hand."
		if ids.find(ids[i]) != i or used.has(ids[i]):
			return "A card can only fill one Role."
	return ""


func _check_fuse(fuse, sets: Array) -> String:
	if fuse == null:
		return ""
	if options.get("cavalier", false):
		return "The Cavalier rule forbids Fusing."
	if fuse.top == fuse.bottom or not hand.has(fuse.top) or not hand.has(fuse.bottom):
		return "Fuse two different cards from your Hand."
	if db.mage(fuse.top).element != db.mage(fuse.bottom).element:
		return "Fused cards must share an Ether element."
	for s in sets:
		if _roles(s).values().has(fuse.bottom):
			return "The bottom Fused card cannot fill a Role."
	return ""


func _roles(s: Dictionary) -> Dictionary:
	var out := {}
	for r in ROLES:
		if s.get(r) != null:
			out[r] = s[r]
	return out


## The single Hand card left without a Role, or null.
func _reserve(sets: Array, fuse):
	var left := hand.duplicate()
	for s in sets:
		for id in _roles(s).values():
			left.erase(id)
	if fuse != null:
		left.erase(fuse.bottom)
	return left[0] if left.size() == 1 else null


func _set_stats(s: Dictionary, fuse) -> Dictionary:
	var out := {"spell": null, "element": "", "initiative": 0, "boost": 0,
		"boost_to": s.get("boost_to", "attack")}
	if s.get("spell") != null:
		out.spell = level_data(s.spell)
	if s.get("element") != null:
		var fused: bool = fuse != null and fuse.top == s.element
		out.element = fuse.element if fused else db.mage(s.element).element
		out.initiative = level_data(s.element).initiative
	if s.get("boost") != null:
		out.boost = level_data(s.boost).boost
	return out


## Discard from the top of the deck; returns how many cards were missing.
func _pay_time(count: int) -> int:
	var paid := mini(count, deck.size())
	for i in paid:
		discard.append(deck.pop_front())
	return count - paid


func _take_damage(amount: int, next_phase: String) -> void:
	damage_due = amount
	if amount <= 0:
		phase = next_phase
		return
	var capacity := 0
	for id in hand:
		if not downgraded.has(id):
			capacity += _soak_value(id)
	if capacity >= amount:
		phase = "penalty"
		return
	# Knocked Out
	for id in hand.duplicate():
		if not downgraded.has(id):
			_downgrade(id)
	_pay_time(KNOCK_OUT_DISCARD)
	damage_due = 0
	result["knocked_out"] = true
	phase = next_phase


func _soak_value(id: String) -> int:
	return Rules.soak_value(level_data(id), damage_element, options.get("glass_cannon", false))


func _downgrade(id: String) -> void:
	downgraded.append(id)
	if cards[id].level == 1:
		_move(id, hand, trash)
	else:
		cards[id].level -= 1


func _gather() -> void:
	deck.append_array(hand)
	deck.append_array(discard)
	hand = []
	discard = []
	_shuffle(deck)


func _draw(count: int) -> void:
	for i in mini(count, deck.size()):
		hand.append(deck.pop_front())


func _move(id: String, from: Array, to: Array) -> void:
	from.erase(id)
	to.append(id)


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp
