extends "res://tests/base.gd"
## Every lesson against the real engine (specs/017 FR-007, FR-020, SC-001, SC-004): its
## table stages, the guided moves give the outcome the lesson is about, and, trying
## every Action Set and Fuse the Hand allows, nothing better is possible where the
## lesson says so. If the card data ever changes under a lesson, this fails.

const Game = preload("res://engine/game.gd")
const Lessons = preload("res://ui/model/lessons.gd")
const Glossary = preload("res://ui/model/glossary.gd")
const Settings = preload("res://ui/model/settings.gd")

const ETHERS := ["fire", "water", "lightning", "shadow"]
const RANK := {"loss": 0, "narrow": 1, "complete": 2}

var db = CardDB.new()


func _stage(i: int):
	var g = Game.new(db, {"dragon": "rodving", "difficulty": "normal", "seed": 0})
	eq(g.stage(Lessons.table(i, db.mage_ids())), "", "lesson %d stages" % i)
	return g


## Every Action Set the Hand allows: each Spell/Element/Boost of three different cards,
## either Boost target, and every Fuse whose top is the Element and whose bottom fills
## no Role, as each Ether.
func _all_actions(g) -> Array:
	var out := []
	var h: Array = g.hand
	for sp in h:
		for el in h:
			for bo in h:
				if sp == el or sp == bo or el == bo:
					continue
				for to in ["attack", "initiative"]:
					out.append({"spell": sp, "element": el, "boost": bo, "boost_to": to})
					for bottom in h:
						if bottom == sp or bottom == el or bottom == bo:
							continue
						for e in ETHERS:
							out.append({"spell": sp, "element": el, "boost": bo, "boost_to": to,
								"fuse": {"top": el, "bottom": bottom, "element": e}})
	return out


## The best outcome over every legal action, with or without Fusing.
func _best(g, with_fuse: bool) -> String:
	var best := -1
	for a in _all_actions(g):
		if a.has("fuse") and not with_fuse:
			continue
		var r = g.preview(a)
		if not r.has("error"):
			best = maxi(best, RANK[r.outcome])
	return RANK.find_key(best) if best >= 0 else "none"


func _step_of(i: int, wait: String) -> Dictionary:
	for s in Lessons.lesson(i).steps:
		if s.wait == wait:
			return s
	return {}


## Plays the lesson's guided moves straight against the engine, as main would send them.
func _follow(i: int):
	var g = _stage(i)
	for s in Lessons.lesson(i).steps:
		var e: Dictionary = s.get("expect", {})
		match s.wait:
			"setup":
				eq(g.choose_setup_cards(e.picks), "", "lesson %d setup" % i)
			"play":
				eq(g.play(e), "", "lesson %d play" % i)
			"soak":
				eq(g.soak(e.picks), "", "lesson %d soak" % i)
			"upgrade":
				for id in e.get("picks", []):
					eq(g.upgrade(id), "", "lesson %d upgrade %s" % [i, id])
				eq(g.finish(), "", "lesson %d finish" % i)
	return g


# --- every lesson ---

func test_every_table_stages() -> void:
	for i in Lessons.count():
		_stage(i)


func test_every_step_is_well_formed() -> void:
	for i in Lessons.count():
		for s in Lessons.lesson(i).steps:
			var where := "%s: %s" % [Lessons.lesson(i).id, s.get("text", "").left(30)]
			ok(s.get("text", "") != "", "text " + where)
			ok(Lessons.WAITS.has(s.get("wait", "")), "wait " + where)
			for target in s.get("target", "").split("|"):
				var known := Lessons.TARGETS.has(target)
				for p in Lessons.TARGET_PREFIXES:
					known = known or (target.begins_with(p) and target.length() > p.length())
				ok(known, "target %s %s" % [target, where])
			for term in Lessons.terms(s.text):
				ok(Glossary.has(term), "term %s %s" % [term, where])
			for c in s.get("concepts", []):
				ok(Lessons.CONCEPTS.has(c), "concept %s %s" % [c, where])
			if not ["next", "sequence", "arrange", "fuse_begin"].has(s.wait) and s.wait != "upgrade":
				ok(s.has("expect"), "expect " + where)
			if s.has("hint"):
				ok(s.hint != "", "hint " + where)


func test_every_concept_is_taught() -> void:
	var taught := []
	for i in Lessons.count():
		for s in Lessons.lesson(i).steps:
			taught.append_array(s.get("concepts", []))
	for c in Lessons.CONCEPTS:
		ok(taught.has(c), "concept taught: " + c)


func test_settings_know_the_lessons() -> void:
	eq(Settings.LESSON_IDS, Lessons.ids(), "Settings.LESSON_IDS")


func test_summary_terms() -> void:
	ok(Lessons.terms(Lessons.SUMMARY).size() > 0, "the summary links terms")
	for term in Lessons.terms(Lessons.SUMMARY):
		ok(Glossary.has(term), "summary term " + term)


func test_text_links_terms() -> void:
	var t := Lessons.text("Your [[deck|Deck]] and the [[key_card]].")
	ok(t.contains("[url=deck][b]Deck[/b][/url]"), "a worded link")
	ok(t.contains("[url=key_card][b]Key Card[/b][/url]"), "a link with the entry's name")


# --- Lesson 1: setting out ---

func test_setting_out() -> void:
	var g = _stage(0)
	eq(g.phase, "setup", "setup")
	eq(g.setup_offer, ["DOE-A03", "DOE-A06", "DOE-A12", "DOE-A15", "DOE-A16"], "the offer")
	for id in g.setup_offer:
		if id != "DOE-A03":
			ok(g.level_data(id).basic.type != "attack" and g.level_data(id).enhanced.type != "attack",
				"only Destruction fights: " + id)
	g = _follow(0)
	eq(g.phase, "challenge", "a Hand is dealt")
	for id in g.cards:
		eq(g.cards[id].level, 3 if id == "DOE-A03" else 2, "level " + id)


# --- Lesson 2: a Victory ---

func test_victory() -> void:
	var g = _stage(1)
	var play: Dictionary = _step_of(1, "play").expect
	var r = g.preview(play)
	eq(r.outcome, "complete", "Victory")
	eq(r.attack, 11, "10 + 2 - 1")
	eq(r.early, false, "no Early Damage")
	eq(r.damage, 0, "no damage")
	var wins := []
	for a in _all_actions(g):
		var p = g.preview(a)
		if not p.has("error") and p.outcome == "complete":
			wins.append(a)
	eq(wins.size(), 1, "the only winning Action Set")
	g = _follow(1)
	eq(g.phase, "challenge", "on to the next Hand")
	eq(g.hand.size(), 4, "drawn back up")
	ok(g.hand.has("DOE-A10"), "the Reserve stayed")
	eq(g.cards["DOE-A10"].level, 3, "the Reserve was Upgraded")
	eq(g.cards["DOE-A06"].level, 3, "Fleet Footed was Upgraded")
	ok(g.discard.has("DOE-A06"), "and discarded at its new Level")
	eq(g.xp, 0, "no XP wasted")


# --- Lesson 3: a Narrow Victory ---

func test_narrow() -> void:
	var g = _stage(2)
	eq(g.encounter().kind, "journey", "a Journey")
	eq(g.encounter().index, 1, "Journey 1")
	var r = g.preview(_step_of(2, "play").expect)
	eq(r.outcome, "narrow", "Narrow Victory")
	eq(r.move, 9, "6 + 3")
	eq(r.time_penalty, 2, "pays 2")
	eq(_best(g, true), "narrow", "nothing better")
	var before: int = g.deck.size()
	g.play(_step_of(2, "play").expect)
	eq(g.deck.size(), before - 2, "two cards paid from the Deck")


# --- Lesson 4: a Loss ---

func test_loss() -> void:
	var g = _stage(3)
	eq(g.encounter().kind, "enemy", "an enemy")
	eq(g.encounter().index, 4, "Enemy 4")
	eq(_best(g, true), "loss", "nothing can win")
	for id in g.hand:
		ok(g.level_data(id).basic.type == "move" and g.level_data(id).enhanced.type == "move", "only Move spells: " + id)
	var r = g.preview(_step_of(3, "play").expect)
	eq(r.attack, 3, "1 (no action fits) + 2")
	eq(r.damage, 3, "3 damage")
	eq(r.early, false, "no Early Damage")
	g.play(_step_of(3, "play").expect)
	eq(g.phase, "penalty", "damage to Soak")
	eq(g.damage_due, 3, "3 due")
	ok(g.soak(["DOE-A15"]) != "", "Burning Bridges alone cannot Soak 3")
	eq(g.soak(["DOE-A06"]), "", "Fleet Footed can")
	eq(g.cards["DOE-A06"].level, 1, "Downgraded")
	g = _follow(3)
	eq(g.phase, "challenge", "on to the next Hand")


# --- Lesson 5: Fusing ---

func test_fuse() -> void:
	var g = _stage(4)
	eq(g.encounter().kind, "enemy", "an enemy")
	eq(g.encounter().index, 3, "Enemy 3")
	eq(_best(g, false), "narrow", "no plain win")
	eq(_best(g, true), "complete", "a Fuse wins")
	for a in _all_actions(g):
		var p = g.preview(a)
		# Destruction on top as the fire Element also wins, but is too slow: Early Damage.
		if not p.has("error") and p.outcome == "complete" and p.damage == 0:
			eq(a.get("fuse"), {"top": "DOE-A02", "bottom": "DOE-A03", "element": "fire"}, "only this Fuse wins unhurt")
			eq(a.spell, "DOE-A05", "with Rain of Blood")
	var r = g.preview(_step_of(4, "play").expect)
	eq(r.attack, 10, "8 + 2")
	eq(r.early, false, "no Early Damage")
	g = _follow(4)
	ok(g.discard.has("DOE-A02") and g.discard.has("DOE-A03"), "both Fused cards discarded")


# --- Lesson 6: the end of a Region ---

func test_region_end() -> void:
	var g = _stage(5)
	eq(g.deck.size(), 2, "two cards left")
	eq(g.discard.size(), 10, "the rest discarded")
	var r = g.preview(_step_of(5, "play").expect)
	eq(r.outcome, "complete", "Victory")
	eq(r.move, 8, "5 + 3")
	var levels := {}
	for id in g.cards:
		levels[id] = g.cards[id].level
	g = _follow(5)
	eq(g.region, 2, "Region 2")
	eq(g.hand.size(), 4, "a new Hand")
	eq(g.deck.size(), 12, "a new Deck")
	ok(g.discard.is_empty(), "the discard pile gathered")
	for id in g.cards:
		eq(g.cards[id].level, levels[id], "level kept " + id)
