extends SceneTree
## A screenshot of every printed card, each alone on the table: the sixteen Mage
## Cards at their starting Level, both sides of both Region Cards (Regions 1 to 4),
## each Enemy and Journey panel of them alone, as the Deck zooms into it, and each
## dragon's Dragon Card. The cards are the game's own widgets, filled from the card
## data as play fills them, drawn over the running game's theme.
## godot --path . -s tools/card_shots.gd -- <out dir> [mage|region|enemy|journey|dragon ...]
## (every kind when none are named)

const T = preload("res://ui/theme/tokens.gd")
const ViewState = preload("res://ui/model/view_state.gd")
const CardView = preload("res://ui/widgets/card_view.gd")
const RegionCard = preload("res://ui/widgets/region_card.gd")
const RegionPanel = preload("res://ui/widgets/region_panel.gd")
const DragonCard = preload("res://ui/widgets/dragon_card.gd")
const Game = preload("res://engine/game.gd")
const HistoryStore = preload("res://ui/model/history_store.gd")

const WINDOW := Vector2i(1440, 900)
## Each kind's width on the table, in design units; the height follows its shape.
const MAGE_W := 320.0
const BIG_W := 440.0
## A panel alone is shown at the scale of a Region Card this wide.
const PANEL_CARD_W := 900.0
const MARGIN := 24.0

var out := "."
var ui
var _stage: Control


func _initialize() -> void:
	HistoryStore.use_empty("user://tool_history/")
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var kinds: Array = Array(args.slice(1)) if args.size() > 1 else ["mage", "region", "enemy", "journey", "dragon"]
	_run(kinds)


func _run(kinds: Array) -> void:
	DisplayServer.window_set_size(WINDOW)
	root.size = WINDOW
	for i in 3:
		await process_frame
	# The game itself, for its theme and card data; the cards are drawn over it.
	ui = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui)
	for i in 3:
		await process_frame
	var layer := CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	var table := ColorRect.new()
	table.color = T.BG_BASE
	table.size = Vector2(WINDOW)
	layer.add_child(table)
	_stage = Control.new()
	layer.add_child(_stage)
	if kinds.has("mage"):
		await _mages()
	if kinds.has("region"):
		await _regions()
	for kind in ["enemy", "journey"]:
		if kinds.has(kind):
			await _panels(kind)
	if kinds.has("dragon"):
		await _dragons()
	quit()


## Every Mage Card at the Level a game starts it at, in Ether then name order.
func _mages() -> void:
	DirAccess.make_dir_recursive_absolute("%s/mage" % out)
	var game = Game.new(ui.db, {"seed": 1, "dragon": ui.db.dragon_ids()[0], "difficulty": "normal"})
	var ids: Array = ui.db.mage_ids()
	ids.sort_custom(func(a, b):
		var ea: String = ui.db.mage(a).element
		var eb: String = ui.db.mage(b).element
		return ea < eb if ea != eb else ui.db.mage(a).name < ui.db.mage(b).name)
	for i in ids.size():
		var v := CardView.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := ViewState.plain_card(game, ui.db, ids[i])
		await _shoot(v, Vector2(MAGE_W, MAGE_W / T.CARD_ASPECT), "mage/%02d_%s" % [i + 1, ids[i]], func():
			v.home = Rect2(v.position, v.size)
			v.set_model(m)
			v.snap_home())


## Both sides of both Region Cards: Regions 1 to 4.
func _regions() -> void:
	DirAccess.make_dir_recursive_absolute("%s/region" % out)
	for r in range(1, 5):
		var c := RegionCard.new()
		var m := ViewState.region_card_model(ui.db, r)
		await _shoot(c, RegionCard.card_size(BIG_W), "region/region_%d" % r, func(): c.render(m))


## Each `kind` panel ("enemy" or "journey") of Regions 1 to 4 alone, at its size on
## a Region Card PANEL_CARD_W wide, its number plate faded as the zoomed Deck fades it.
func _panels(kind: String) -> void:
	DirAccess.make_dir_recursive_absolute("%s/%s" % [out, kind])
	for r in range(1, 5):
		var m := ViewState.region_card_model(ui.db, r)
		for p in m.panels:
			if p.kind != kind:
				continue
			var v := RegionPanel.new()
			var size := RegionCard.panel_rect(RegionCard.card_size(PANEL_CARD_W), p.key).size
			await _shoot(v, size, "%s/region_%d_%d" % [kind, r, p.index], func():
				v.number_alpha = 0.0
				v.render(p))


## Each dragon's Dragon Card.
func _dragons() -> void:
	DirAccess.make_dir_recursive_absolute("%s/dragon" % out)
	for id in ui.db.dragon_ids():
		var c := DragonCard.new()
		var m := ViewState.dragon_card_model(ui.db.dragon(id))
		await _shoot(c, DragonCard.card_size(BIG_W), "dragon/%s" % id, func(): c.render(m))


## `card` alone on the table at `size`, filled by `fill` once it is there (the cards
## lay themselves out as they are sized in the tree), saved as `file`.
func _shoot(card: Control, size: Vector2, file: String, fill: Callable) -> void:
	for c in _stage.get_children():
		c.queue_free()
	_stage.add_child(card)
	card.position = Vector2(MARGIN, MARGIN)
	card.size = size
	fill.call()
	# Long enough for its art and Ether to settle in.
	await create_timer(0.5).timeout
	await process_frame
	var img: Image = root.get_texture().get_image()
	# The canvas is stretched to the window: canvas units to its pixels, each way.
	var k := Vector2(img.get_size()) / root.get_visible_rect().size
	var r := Rect2(Vector2.ZERO, size + Vector2(MARGIN, MARGIN) * 2.0)
	var px := Rect2i(Vector2i((r.position * k).floor()), Vector2i((r.size * k).ceil())).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	if px.size != Vector2i((r.size * k).ceil()):
		push_warning("%s is cut by the window (%s of %s)" % [file, px.size, r.size * k])
	var path := "%s/%s.png" % [out, file]
	img.get_region(px).save_png(path)
	print("saved ", path)
