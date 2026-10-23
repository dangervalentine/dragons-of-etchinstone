extends SceneTree
## Draws every app icon variant tools/make_app_icon.gd writes side by side, on a mid
## green so clear areas show, into one picture to look over (specs/018).
## godot --headless --path . -s tools/icon_sheet.gd -- build/icon-preview.png

const FILES := ["icon.svg", "art/launcher/background.svg", "art/launcher/foreground.svg",
	"art/launcher/monochrome.svg", "art/launcher/ios_dark.svg", "art/launcher/ios_tinted.svg",
	"art/launcher/windows.svg"]
const CELL := 256
const GAP := 10


func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var sheet := Image.create((CELL + GAP) * FILES.size() + GAP, CELL + 2 * GAP, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("6a8a6a"))
	for i in FILES.size():
		var img := Image.new()
		img.load_svg_from_buffer(FileAccess.get_file_as_bytes("res://" + FILES[i]), CELL / 1024.0)
		img.convert(Image.FORMAT_RGBA8)
		sheet.blend_rect(img, Rect2i(0, 0, CELL, CELL), Vector2i(GAP + i * (CELL + GAP), GAP))
	sheet.save_png(out)
	quit()
