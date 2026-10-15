extends Button
## A button that explains a term: its tooltip wraps in the shared narrow panel.

const HelpTip = preload("res://ui/widgets/help_tip.gd")


func _make_custom_tooltip(for_text: String) -> Object:
	return HelpTip.tooltip(self, for_text)
