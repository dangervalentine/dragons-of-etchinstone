extends RefCounted
## How the game's window opens on a desktop: a 16:9 window sized to the monitor, or
## borderless full screen. The window can then be resized and maximised freely; the
## play area keeps its shape inside it. Not used on phones or the web (feature 008).

const Settings = preload("res://ui/model/settings.gd")

## The window sizes tried, largest first.
const SIZES := [Vector2i(3840, 2160), Vector2i(2560, 1440), Vector2i(1920, 1080), Vector2i(1280, 720)]
## The least the window may be dragged down to: at 150% display scaling a design
## unit is still half a point, above the layout's legible scale.
const MIN := Vector2i(960, 540)
## A Windows frame, for when the window cannot report its own (just out of full
## screen, before the frame is back).
const FRAME := Vector2i(16, 39)


## A desktop with a real window: not a phone, the web or a headless run.
static func applies() -> bool:
	return OS.has_feature("pc") and not OS.has_feature("web") and DisplayServer.get_name() != "headless"


## The largest of SIZES that fits in `usable` with its frame, else the largest 16:9
## size that does.
static func start_size(usable: Vector2i, decorations: Vector2i) -> Vector2i:
	for size in SIZES:
		if size.x + decorations.x <= usable.x and size.y + decorations.y <= usable.y:
			return size
	var room := usable - decorations
	var h := mini(room.y, floori(room.x * 9 / 16.0))
	return Vector2i(floori(h * 16 / 9.0), h)


static func min_size(start: Vector2i) -> Vector2i:
	return Vector2i(mini(MIN.x, start.x), mini(MIN.y, start.y))


## The window's mode as the setting names it; a maximised window is still windowed.
static func current_mode() -> String:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		return "fullscreen"
	return "windowed"


## Put the window in `mode`: full screen on its monitor, or a window of the starting
## size with its frame centred in the monitor's room above the taskbar.
static func apply(mode: String) -> void:
	if not applies():
		return
	if mode == "fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var usable := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var deco := DisplayServer.window_get_size_with_decorations() - DisplayServer.window_get_size()
	if deco.x <= 0 or deco.y <= 0:
		deco = FRAME
	var size := start_size(usable.size, deco)
	DisplayServer.window_set_min_size(min_size(size))
	DisplayServer.window_set_size(size)
	# The position is the client area's: past the left border and the title bar.
	var side := deco.x / 2
	DisplayServer.window_set_position(usable.position + (usable.size - size - deco) / 2 + Vector2i(side, deco.y - side))


## Switch between windowed and full screen, and remember it.
static func toggle() -> String:
	Settings.window_mode = "windowed" if current_mode() == "fullscreen" else "fullscreen"
	apply(Settings.window_mode)
	Settings.save_all()
	return Settings.window_mode
