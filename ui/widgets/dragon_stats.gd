extends RefCounted
## A dragon's figures for the choice of dragon: its Armor, and the tiers of the
## Final Journey and the Final Enemy side by side, drawn with the icons the Final
## Battle uses so they are learned once.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const StatChip = preload("res://ui/widgets/stat_chip.gd")
const TipBox = preload("res://ui/widgets/tip_box.gd")
const HelpTip = preload("res://ui/widgets/help_tip.gd")

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
## them, over the two ladders. With `explain`, each part tells on hover what it
## means; without, it ignores the mouse so whatever holds it takes the press.
static func make(d: Dictionary, explain := false) -> Control:
	var col := UI.vbox(T.XS)
	# Two halves like the ladders below, so Armor starts where Battle does.
	var top := UI.hbox(T.S)
	var opening := UI.hbox(0)
	opening.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opening.add_child(_opening(d, explain))
	top.add_child(opening)
	var armor := UI.hbox(T.XS)
	armor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(armor)
	var name := UI.label("Armor", T.LABEL, T.INK_MUTED)
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	armor.add_child(name)
	for a in d.armor:
		var chip := StatChip.make({"icon": "armor", "text": str(a.value), "color": T.ether(a.element), "ink": T.ether_shade(a.element, "plate_ink"),
			"element": a.element, "min_size": Vector2(40, 34)})
		if explain:
			chip.mouse_filter = Control.MOUSE_FILTER_STOP
			HelpTip.show(chip, armor_text(a), "armor")
		armor.add_child(chip)
	col.add_child(top)
	var ladders := UI.hbox(T.S)
	ladders.add_child(_ladder("Journey", rungs(d, true), true, explain))
	ladders.add_child(_ladder("Battle", rungs(d, false), false, explain))
	col.add_child(ladders)
	if not explain:
		UI.ignore_mouse(col)
	return col


## One Armor shield in words.
static func armor_text(a: Dictionary) -> String:
	var ether: String = a.element.capitalize()
	return "%s Armor %d: An enhanced %s Attack against this dragon is reduced by %d." % [ether, a.value, ether, a.value]


## The dragon's Ether in words.
static func ether_text(d: Dictionary) -> String:
	var ether: String = d.early_damage.element.capitalize()
	return "%s: The dragon's Ether. Its Early Damage is %s damage, which cards with %s Armor Soak doubled." % [ether, ether, ether]


static func initiative_text(d: Dictionary) -> String:
	return "Initiative %d: The dragon's speed. If its Initiative is higher than yours, it deals its Early Damage before you strike." % d.initiative


static func early_damage_text(d: Dictionary) -> String:
	return "Early Damage %d: Dealt before you strike in the Final Battle when the dragon's Initiative is higher than yours, and added to any Combat Damage." % d.early_damage.value


## What a ladder is, in words.
static func ladder_heading_text(journey: bool) -> String:
	if journey:
		return "The Final Journey: The road to the dragon. Each tier names the Move it takes and the time it costs; an enhanced Spell of the Ether shown also adds your Reserve's Boost."
	return "The Final Enemy: The dragon itself. Each tier names the Attack it takes and the damage you suffer there."


static func _ladder(heading: String, tiers: Array, journey: bool, explain := false) -> Control:
	var col := UI.vbox(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name := UI.label(heading, T.LABEL, T.INK_MUTED)
	if explain:
		var tipped := TipBox.make(ladder_heading_text(journey), "move" if journey else "attack")
		tipped.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		tipped.add_child(name)
		col.add_child(tipped.seal())
	else:
		col.add_child(name)
	for rung in tiers:
		col.add_child(_rung(rung, journey, explain))
	return col


static func _rung(rung: Dictionary, journey: bool, explain := false) -> Control:
	var row: HBoxContainer = UI.hbox(3)
	if explain:
		var tier := "Final Journey tier" if journey else "Final Enemy tier"
		row = TipBox.make("%s: %s." % [tier, rung_text(rung, journey)], "time" if journey else "hp")
		row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(UI.icon_rect("move" if journey else "attack", ICON))
	row.add_child(UI.label(str(rung.need), FIGURE))
	if journey:
		row.add_child(UI.icon_rect(rung.element, ICON * 0.8, T.ether_ink(rung.element)))
	row.add_child(UI.label("→", FIGURE, T.INK_MUTED))
	row.add_child(UI.icon_rect("time" if journey else "hp", ICON))
	row.add_child(UI.label(str(rung.cost), FIGURE))
	return row.seal() if explain else row


## Initiative and early damage on one plate of the dragon's early-damage Ether:
## the two figures that open the Final Enemy.
static func _opening(d: Dictionary, explain := false) -> Control:
	var element: String = d.early_damage.element
	var plate := PanelContainer.new()
	plate.custom_minimum_size.y = 34
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var look := UI.box(T.ether(element), Color(0, 0, 0, 0.35), 1, T.RADIUS_S, 0)
	look.content_margin_left = T.S
	look.content_margin_right = T.S
	plate.add_theme_stylebox_override("panel", look)
	var row := UI.hbox(3)
	var speed: HBoxContainer = TipBox.make(initiative_text(d), "initiative") if explain else UI.hbox(3)
	speed.add_child(UI.icon_rect("initiative", ICON, T.BG_BASE))
	speed.add_child(UI.label(str(d.initiative), FIGURE, T.BG_BASE))
	row.add_child(speed.seal() if explain else speed)
	var rule := ColorRect.new()
	rule.color = Color(T.BG_BASE, 0.45)
	rule.custom_minimum_size = Vector2(2, 22)
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var gap := Control.new()
	gap.custom_minimum_size.x = T.XS
	row.add_child(gap)
	row.add_child(rule)
	row.add_child(gap.duplicate())
	var early: HBoxContainer = TipBox.make(early_damage_text(d), "attack") if explain else UI.hbox(3)
	early.add_child(UI.label("+%d" % d.early_damage.value, FIGURE, T.BG_BASE))
	early.add_child(UI.icon_rect("attack", ICON, T.BG_BASE))
	row.add_child(early.seal() if explain else early)
	var ether: HBoxContainer = TipBox.make(ether_text(d), element) if explain else UI.hbox(3)
	ether.add_child(UI.icon_rect(element, ICON, T.BG_BASE))
	row.add_child(ether.seal() if explain else ether)
	plate.add_child(row)
	return plate
