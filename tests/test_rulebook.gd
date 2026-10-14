extends "res://tests/base.gd"
## The rulebook: its order, its links to the Glossary and the engine, and how it pages.

const Rulebook = preload("res://ui/model/rulebook.gd")
const Glossary = preload("res://ui/model/glossary.gd")
const Game = preload("res://engine/game.gd")

const ORDER := ["welcome", "mage_cards", "regions", "dragons", "setup", "encounter", "challenge", "action",
	"enemies", "journeys", "penalty", "upgrade_cleanup", "region_end", "final_journey", "final_enemy",
	"scoring", "ethers", "difficulty"]


func test_sections_in_reading_order() -> void:
	eq(Rulebook.section_count(), ORDER.size(), "section count")
	for i in Rulebook.SECTIONS.size():
		var s: Dictionary = Rulebook.SECTIONS[i]
		eq(s.id, ORDER[i] if i < ORDER.size() else "", "section %d" % i)
		ok(s.title != "", "title for " + s.id)
		ok(s.pages.size() >= 1, "at least one page in " + s.id)
		eq(Rulebook.page_count(i), s.pages.size(), "page count of " + s.id)


func test_find() -> void:
	eq(Rulebook.find("welcome"), 0, "first section")
	eq(Rulebook.find("penalty"), 10, "penalty section")
	eq(Rulebook.find("nope"), -1, "unknown section")


func test_step() -> void:
	var first := {"section": 0, "page": 0}
	eq(Rulebook.step(first, -1), first, "nothing before the first page")
	var last_section := Rulebook.section_count() - 1
	var last := {"section": last_section, "page": Rulebook.page_count(last_section) - 1}
	eq(Rulebook.step(last, 1), last, "nothing after the last page")
	# Walking forward visits every page once, crossing each section boundary.
	var pos := first
	var seen := 1
	while true:
		var next := Rulebook.step(pos, 1)
		if next == pos:
			break
		ok(next.section == pos.section and next.page == pos.page + 1 or next.section == pos.section + 1 and next.page == 0,
			"forward from %s goes to the next page, got %s" % [str(pos), str(next)])
		eq(Rulebook.step(next, -1), pos, "back from %s" % str(next))
		pos = next
		seen += 1
	var total := 0
	for i in Rulebook.section_count():
		total += Rulebook.page_count(i)
	eq(seen, total, "every page visited")
	eq(pos, last, "the walk ends on the last page")


func test_expand() -> void:
	eq(Rulebook.expand("[[soak]] it"), "[b]Soak[/b] it", "a term shows its Glossary name in bold")
	eq(Rulebook.expand("[[soak|Soaking]]"), "[b]Soaking[/b]", "a term can show other words")
	var icon := Rulebook.expand("{icon:fire}")
	ok(icon.begins_with("[img") and icon.contains("res://art/icons/fire.svg") and icon.ends_with("[/img]"), "icon becomes an image: " + icon)
	eq(Rulebook.expand("{n:MAX_DIVERTS}"), str(Game.MAX_DIVERTS), "numbers come from the engine")
	eq(Rulebook.expand("plain"), "plain", "plain text is unchanged")


func test_terms() -> void:
	eq(Rulebook.terms_in(["[[fuse]] and [[soak|Soaking]]", "then [[fuse]] again, [[divert]]"]), ["fuse", "soak", "divert"],
		"terms in first-use order with no repeats")
	for i in Rulebook.section_count():
		for p in Rulebook.page_count(i):
			var t: Array = Rulebook.terms(i, p)
			var unique := {}
			for id in t:
				unique[id] = true
			eq(unique.size(), t.size(), "no repeated terms on %s page %d" % [Rulebook.SECTIONS[i].id, p])


func test_numbers_whitelist() -> void:
	var names: Array = Rulebook.NUMBERS.keys()
	names.sort()
	eq(names, ["FINAL_JOURNEY_HAND", "HAND_SIZE", "KNOCK_OUT_DISCARD", "MAX_DIVERTS"], "whitelisted numbers")
	var constants: Dictionary = load("res://engine/game.gd").get_script_constant_map()
	for name in Rulebook.NUMBERS:
		eq(Rulebook.NUMBERS[name], constants.get(name), name)


func test_difficulty_rows() -> void:
	var rows: Array = Rulebook.difficulty_rows()
	eq(rows.size(), Game.DIFFICULTY.size(), "one row per difficulty")
	var keys: Array = Game.DIFFICULTY.keys()
	for i in rows.size():
		var d: Array = Game.DIFFICULTY[keys[i]]
		eq(rows[i].id, keys[i], "row %d" % i)
		eq([rows[i].offered, rows[i].changed, rows[i].level], d, "numbers for " + keys[i])
		ok(rows[i].name != "", "name for " + keys[i])


func test_position_default() -> void:
	eq(Rulebook.position, {"section": 0, "page": 0}, "starts at the first page")


func test_page_is_expanded() -> void:
	for i in Rulebook.section_count():
		for p in Rulebook.page_count(i):
			var page: Dictionary = Rulebook.page(i, p)
			ok(page.has("text") and page.has("aside") and page.has("terms"), "page shape for %s %d" % [Rulebook.SECTIONS[i].id, p])
			for s in _strings(page.text) + _strings(page.aside):
				ok(not (s.contains("[[") or s.contains("{icon:") or s.contains("{n:")), "unexpanded token in %s: %s" % [Rulebook.SECTIONS[i].id, s.left(40)])


## Every string inside a list of blocks.
func _strings(blocks: Array) -> Array:
	var out := []
	for b in blocks:
		for key in b:
			_collect(b[key], out)
	return out


func _collect(v, out: Array) -> void:
	if v is String:
		out.append(v)
	elif v is Array:
		for x in v:
			_collect(x, out)
	elif v is Dictionary:
		for k in v:
			_collect(v[k], out)


# ---------------------------------------------------------------- content

func _effect_ids(v, found: Dictionary) -> void:
	if v is Dictionary:
		for k in v:
			if ["hardship", "ability", "peril"].has(k) and v[k] != null:
				found[v[k]] = true
			_effect_ids(v[k], found)
	elif v is Array:
		for x in v:
			_effect_ids(x, found)


## Every raw string in the book, before expansion.
func _raw_strings() -> Array:
	var out := []
	for s in Rulebook.SECTIONS:
		for p in s.pages:
			_collect(p, out)
	return out


func _all_terms() -> Array:
	return Rulebook.terms_in(_raw_strings())


## Plain words of a raw string: marks reduced to the words they show.
func _plain(raw: String) -> String:
	var out := RegEx.create_from_string(r"\[\[[a-z_]+\|([^\]]+)\]\]").sub(raw, "$1", true)
	out = RegEx.create_from_string(r"\[\[([a-z_]+)\]\]").sub(out, "$1", true)
	out = RegEx.create_from_string(r"\{icon:[a-z_]+\}").sub(out, "", true)
	out = RegEx.create_from_string(r"\{n:[A-Z_]+\}").sub(out, "4", true)
	return out


func _words(text: String) -> Array:
	return Array(text.to_lower().split(" ", false)).map(func(w): return w.strip_edges()).filter(func(w): return w != "")


func test_covers_every_effect() -> void:
	var found := {}
	_effect_ids(JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json")), found)
	ok(found.size() >= 10, "found the effects in the card data (%d)" % found.size())
	var terms := _all_terms()
	for id in found:
		ok(terms.has(id), "the rulebook explains " + id)


func test_covers_difficulty_and_rules() -> void:
	var s: Dictionary = Rulebook.SECTIONS[Rulebook.find("difficulty")]
	var has_table := false
	var text := ""
	for p in s.pages:
		for b in p.get("aside", []) + p.get("text", []):
			if b.get("table") is String and b.table == "difficulty":
				has_table = true
		var strings := []
		_collect(p, strings)
		text += " ".join(strings)
	ok(has_table, "the difficulty section has the generated difficulty table")
	ok(text.contains("Cavalier"), "Cavalier is described")
	ok(text.contains("Glass Cannon"), "Glass Cannon is described")


func test_terms_and_icons_resolve() -> void:
	for id in _all_terms():
		ok(Glossary.has(id), "term %s has a Glossary entry" % id)
	var icon_re := RegEx.create_from_string(r"\{icon:([a-z_]+)\}")
	var number_re := RegEx.create_from_string(r"\{n:([A-Z_]+)\}")
	for raw in _raw_strings():
		for m in icon_re.search_all(raw):
			ok(FileAccess.file_exists("res://art/icons/%s.svg" % m.get_string(1)), "icon %s exists" % m.get_string(1))
		for m in number_re.search_all(raw):
			ok(Rulebook.NUMBERS.has(m.get_string(1)), "number %s is whitelisted" % m.get_string(1))


func test_length() -> void:
	var total := 0
	for s in Rulebook.SECTIONS:
		for i in s.pages.size():
			var strings := []
			_collect(s.pages[i].get("text", []), strings)
			var words := 0
			for raw in strings:
				words += _words(_plain(raw)).size()
			ok(words <= 130, "%s page %d has %d words in its text column, over 130" % [s.id, i + 1, words])
			var aside := []
			_collect(s.pages[i].get("aside", []), aside)
			for raw in aside:
				words += _words(_plain(raw)).size()
			total += words
	ok(total <= 3500, "the rulebook has %d words, over 3,500" % total)


func test_not_verbatim() -> void:
	var path := "res://reference/rulebook.txt"
	if not FileAccess.file_exists(path):
		ok(true, "reference rulebook absent; skipped")
		return
	var clean := func(t: String) -> Array:
		var letters := RegEx.create_from_string("[^a-z0-9 ]").sub(t.to_lower().replace("\n", " "), " ", true)
		return Array(letters.split(" ", false))
	var ref: Array = clean.call(FileAccess.get_file_as_string(path))
	var runs := {}
	for i in ref.size() - 7:
		runs[" ".join(ref.slice(i, i + 8))] = true
	for raw in _raw_strings():
		var w: Array = clean.call(_plain(raw))
		for i in w.size() - 7:
			var run := " ".join(w.slice(i, i + 8))
			ok(not runs.has(run), "copied from the printed rulebook: '%s'" % run)


# ---------------------------------------------------------------- the digital game

const BANNED := ["rotate", "flip", "left hand", "right hand", "behind the", "dized", "co-op", "tracking crystal", "challenge mode"]
## Physical steps the game does itself: they may appear only as something "the game" does.
const AUTOMATIC := ["orient", "shuffle"]


func test_digital_wording() -> void:
	for raw in _raw_strings():
		var text := _plain(raw).to_lower()
		for phrase in BANNED:
			ok(not text.contains(phrase), "'%s' in: %s" % [phrase, text.left(60)])
		for sentence in text.split(". "):
			for word in AUTOMATIC:
				if sentence.contains(word):
					ok(sentence.contains("the game"), "'%s' without saying the game does it: %s" % [word, sentence.left(60)])


func test_explains_decisions() -> void:
	var terms := _all_terms()
	for id in ["divert", "fuse", "boost_role", "regroup", "upgrade", "reserve", "ranged"]:
		ok(terms.has(id), "the rulebook explains the decision " + id)


# ---------------------------------------------------------------- figures and tables

const FIGURES := ["mage", "enemy", "journey", "dragon"]


func _blocks_of(section_id: String) -> Array:
	var out := []
	for p in Rulebook.SECTIONS[Rulebook.find(section_id)].pages:
		out.append_array(p.get("text", []) + p.get("aside", []))
	return out


func test_figures() -> void:
	for s in Rulebook.SECTIONS:
		for i in s.pages.size():
			var aside: Array = s.pages[i].get("aside", [])
			ok(aside.size() <= 1, "%s page %d has one aside at most" % [s.id, i + 1])
			for b in s.pages[i].get("text", []) + aside:
				if b.has("figure"):
					ok(FIGURES.has(b.figure), "%s: known figure %s" % [s.id, b.figure])
	for pair in [["mage_cards", "mage"], ["regions", "enemy"], ["dragons", "dragon"], ["journeys", "journey"]]:
		ok(_blocks_of(pair[0]).any(func(b): return b.get("figure") == pair[1]), "%s shows the %s figure" % pair)
	for id in ["enemies", "journeys", "final_journey", "final_enemy"]:
		ok(_blocks_of(id).any(func(b): return b.has("table")), "%s sets out its outcomes as a table" % id)
