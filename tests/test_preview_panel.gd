extends "res://tests/base.gd"
## The box under the Encounter face (specs/011 contracts/left-box.md): before Play
## only the step's tip; once Play is pressed, the sum and the verdict.

const Game = preload("res://engine/game.gd")
const Draft = preload("res://ui/model/turn_draft.gd")
const ViewState = preload("res://ui/model/view_state.gd")
const PreviewPanel = preload("res://ui/widgets/preview_panel.gd")
const T = preload("res://ui/theme/tokens.gd")

var db = CardDB.new()


## A ready Action Set against the first Enemy a seed deals.
func _ready_enemy() -> Dictionary:
	for game_seed in range(1, 60):
		var g = Game.new(db, {"seed": game_seed, "dragon": "rodving", "difficulty": "normal"})
		if g.phase != "challenge" or g.encounter().kind != "enemy":
			continue
		var d = Draft.new()
		d.deal(g.hand)
		d.cycle_boost_to(0)
		var vs: Dictionary = ViewState.build(g, d, db)
		if vs.preview.status == "ready":
			return vs
	return {}


## The text of every label on show: the label and each box it sits in visible.
func _texts(panel) -> Array:
	var out := []
	for l in panel.find_children("*", "Label", true, false):
		var shown := true
		var n: Node = l
		while n != panel:
			shown = shown and (n as CanvasItem).visible
			n = n.get_parent()
		if shown:
			out.append(l.text)
	return out


func test_before_play_nothing_but_the_step() -> void:
	var vs := _ready_enemy()
	ok(not vs.is_empty(), "a ready Enemy set")
	var panel = PreviewPanel.new()
	panel.render(vs)
	var texts := _texts(panel)
	eq(vs.prompt.text, "", "no tip while the set is built (specs/013 FR-006)")
	for s in vs.math.sums:
		ok(not texts.has(s.label), "no %s row before Play" % s.label)
	ok(not texts.has(vs.preview.verdict_text), "no verdict before Play")
	var box: StyleBox = panel.get_theme_stylebox("panel")
	ok(not ("edge" in box) or box.edge != T.BAD, "no red edge before Play")
	panel.free()


func test_play_reveals_the_sum_and_verdict() -> void:
	var vs := _ready_enemy()
	var panel = PreviewPanel.new()
	panel.render(vs)
	var before: float = panel.needed_height(400.0)
	panel.reveal()
	panel.settle()
	var texts := _texts(panel)
	for s in vs.math.sums:
		ok(texts.has(str(s.total)), "the %s total %d once played" % [s.label, s.total])
		ok(texts.has(s.label), "under its name")
	ok(texts.has(vs.preview.verdict_text), "and the verdict")
	eq(panel.needed_height(400.0), before, "the box keeps one height before and after Play")
	panel.free()


## Against an Enemy the Initiative leads, as it is settled first; the verdict follows
## the Attack, then what it means and each cost beside the reason for it.
func test_initiative_first_and_each_cost_explained() -> void:
	var vs := _ready_enemy()
	var panel = PreviewPanel.new()
	panel.render(vs)
	panel.reveal()
	panel.settle()
	var texts := _texts(panel)
	ok(texts.find("Initiative") < texts.find("Attack"), "the Initiative row before the Attack row")
	ok(texts.find(vs.preview.verdict_text) > texts.find("Attack"), "the verdict under the Attack")
	ok(vs.preview.aftermath != "" and texts.has(vs.preview.aftermath), "what the verdict means: %s" % vs.preview.aftermath)
	for c in vs.preview.costs:
		ok(c.why != "" and texts.has(c.why), "%s says why: %s" % [c.id, c.why])
	panel.free()
