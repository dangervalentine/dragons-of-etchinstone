extends RefCounted
## A short buzz under the finger on phones, so a selection is felt as well as seen.
## Silent on desktop and web, where there is nothing to vibrate.

## A light tick for a press or a tap.
static func tap() -> void:
	_buzz(12, 0.35)


## A firmer pulse for a long press that opens a card.
static func hold() -> void:
	_buzz(25, 0.6)


## A heavier buzz when the game refuses what was tapped.
static func refuse() -> void:
	_buzz(45, 0.9)


static func _buzz(ms: int, amplitude: float) -> void:
	if OS.has_feature("android") or OS.has_feature("ios"):
		Input.vibrate_handheld(ms, amplitude)
