extends RefCounted
## A dragon's figures for the choice of dragon: its Armor, and the tiers of the
## Final Journey and the Final Enemy side by side, drawn with the icons the Final
## Battle uses so they are learned once.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const StatChip = preload("res://ui/widgets/stat_chip.gd")

const ICON := 20.0
const FIGURE := ["body_bold", 24]


## The tiers of one ladder, easiest first, as {need, cost, element}: on the
## journey, Move of `element` needed and time lost; in battle, Attack needed and
## damage taken.
static func rungs(d: Dictionary, journey: bool) -> Array:
	var out := []
	for tier in (d.mp_tiers if journey else d.hp_tiers):
		if journey:
			out.append({"need": tier.mp.value, "cost": tier.time_penalty, "element": tier.mp.element})
		else:
			out.append({"need": tier.hp, "cost": tier.attack.value, "element": ""})
	return out


## How a tier reads in words, as the Final Battle's ladder explains it.
static func rung_text(rung: Dictionary, journey: bool) -> String:
	return ("Move %d or more: lose %d time" if journey else "Attack %d or more: take %d damage") % [rung.need, rung.cost]


## The figures in words, one per line, for a tooltip.
static func ladder_text(d: Dictionary) -> String:
	var lines := ["Initiative %d · early damage %d" % [d.initiative, d.early_damage.value]]
	for journey in [true, false]:
		for rung in rungs(d, journey):
			lines.append(rung_text(rung, journey))
	return "\n".join(lines)


## The dragon's Initiative, early damage and Armor as the Final Battle shows
## them, over the two ladders; it ignores the mouse so the tile holding it takes
## the press.
static func make(d: Dictionary) -> Control:
	var col := UI.vbox(T.XS)
	var armor := UI.hbox(T.XS)
	armor.add_child(_opening(d))
	var name := UI.label("Armor", T.LABEL, T.INK_MUTED)
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	armor.add_child(name)
	for a in d.armor:
		armor.add_child(StatChip.make({"icon": "armor", "text": str(a.value), "color": T.ether(a.element), "ink": T.ether_shade(a.element, "plate_ink"),
			"element": a.element, "min_size": Vector2(40, 34)}))
	col.add_child(armor)
	var ladders := UI.hbox(T.S)
	ladders.add_child(_ladder("Journey", rungs(d, true), true))
	ladders.add_child(_ladder("Battle", rungs(d, false), false))
	col.add_child(ladders)
	UI.ignore_mouse(col)
	return col


static func _ladder(heading: String, tiers: Array, journey: bool) -> Control:
	var col := UI.vbox(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UI.label(heading, T.LABEL, T.INK_MUTED))
	for rung in tiers:
		col.add_child(_rung(rung, journey))
	return col


static func _rung(rung: Dictionary, journey: bool) -> Control:
	var row := UI.hbox(3)
	row.add_child(UI.icon_rect("move" if journey else "attack", ICON))
	row.add_child(UI.label(str(rung.need), FIGURE))
	if journey:
		row.add_child(UI.icon_rect(rung.element, ICON * 0.8, T.ether_ink(rung.element)))
	row.add_child(UI.label("→", FIGURE, T.INK_MUTED))
	row.add_child(UI.icon_rect("time" if journey else "hp", ICON))
	row.add_child(UI.label(str(rung.cost), FIGURE))
	return row


## Initiative and early damage on one plate of the dragon's early-damage Ether:
## the two figures that open the Final Enemy.
static func _opening(d: Dictionary) -> Control:
	var element: String = d.early_damage.element
	var plate := PanelContainer.new()
	plate.custom_minimum_size.y = 34
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var look := UI.box(T.ether(element), Color(0, 0, 0, 0.35), 1, T.RADIUS_S, 0)
	look.content_margin_left = T.S
	look.content_margin_right = T.S
	plate.add_theme_stylebox_override("panel", look)
	var row := UI.hbox(3)
	row.add_child(UI.icon_rect("initiative", ICON, T.BG_BASE))
	row.add_child(UI.label(str(d.initiative), FIGURE, T.BG_BASE))
	var rule := ColorRect.new()
	rule.color = Color(T.BG_BASE, 0.45)
	rule.custom_minimum_size = Vector2(2, 22)
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var gap := Control.new()
	gap.custom_minimum_size.x = T.XS
	row.add_child(gap)
	row.add_child(rule)
	row.add_child(gap.duplicate())
	row.add_child(UI.label("+%d" % d.early_damage.value, FIGURE, T.BG_BASE))
	row.add_child(UI.icon_rect("attack", ICON, T.BG_BASE))
	row.add_child(UI.icon_rect(element, ICON, T.BG_BASE))
	plate.add_child(row)
	return plate
