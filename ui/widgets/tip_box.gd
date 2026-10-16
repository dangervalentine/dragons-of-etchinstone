extends HBoxContainer
## A row that explains what it shows on hover, under the help cursor, its tooltip
## wrapping in the shared narrow panel; what is inside it ignores the mouse.

const HelpTip = preload("res://ui/widgets/help_tip.gd")
const UI = preload("res://ui/theme/theme.gd")


## `tip` reads "Name: what it means"; icon_name heads the tooltip.
static func make(tip: String, icon_name := "", separation := 3) -> HBoxContainer:
	var b = load("res://ui/widgets/tip_box.gd").new()
	b.add_theme_constant_override("separation", separation)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	HelpTip.show(b, tip, icon_name)
	return b


## Once filled: the parts stay quiet so the row takes the pointer.
func seal() -> HBoxContainer:
	for child in get_children():
		if child is Control:
			UI.ignore_mouse(child)
	return self


func _make_custom_tooltip(for_text: String) -> Object:
	return HelpTip.tooltip(self, for_text)
