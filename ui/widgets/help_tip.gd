extends RefCounted
## One way to explain a term everywhere: hover shows its explanation in a tooltip,
## the cursor is the help cursor, and a tap (for touch) opens the same help.

const Glossary = preload("res://ui/model/glossary.gd")
const UI = preload("res://ui/theme/theme.gd")


## The term's name and what it means. A Hardship's origin goes unsaid; where it is
## shown already says so.
static func text(id: String) -> String:
	return "%s: %s" % [Glossary.entry(id).name, body(id)]


static func body(id: String) -> String:
	return Glossary.entry(id).text.trim_prefix("A Hardship from the Key Card. ")


## Marks a control as explaining `id`.
static func mark(c: Control, id: String) -> void:
	show(c, text(id), Glossary.entry(id).icon)
	c.set_meta("help_target", true)


## Gives `c` an explanation ("Name: what it means") under the help cursor, or, when
## `tip` is empty, takes it away and puts back `otherwise` as the cursor. Controls
## that explain only parts of themselves, like cards, call this as the pointer moves.
static func show(c: Control, tip: String, icon_name := "", otherwise := Control.CURSOR_ARROW) -> void:
	c.tooltip_text = tip
	c.set_meta("help_icon", icon_name)
	c.mouse_default_cursor_shape = Control.CURSOR_HELP if tip != "" else otherwise


## The tooltip every explaining control builds, in the shared look.
static func tooltip(c: Control, for_text: String) -> Object:
	if for_text.strip_edges() == "":
		return null
	return UI.wrapped_tooltip(for_text, 340.0, c.get_meta("help_icon", ""))
