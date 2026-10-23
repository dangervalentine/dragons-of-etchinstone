extends SceneTree
## Makes the app icon from a dragon's head alone (art/creatures/<name>-rig-head-whole.svg,
## from tools/split_rig.py), one file per thing each platform asks for. Every platform but
## Windows cuts its own shape (Android's launcher mask, iOS's rounded square, a web app's
## home-screen tile), so those files are full-bleed squares and the corners are left to
## the system; drawing them rounded here would round them twice.
## - icon.svg: the head in ink over the glowing ground. Godot's fallback for every icon
##   slot left empty, and what iOS, the web favicon and the web app's icons use.
## - art/launcher/{foreground,background,monochrome}.svg: Android's adaptive layers, the
##   head sized to the safe circle, and a plain head for themed icons.
## - art/launcher/ios_dark.svg, ios_tinted.svg: iOS 18's dark and tinted home screens. The
##   dark one leaves the ground clear so iOS draws its own dark backdrop; the tinted one is
##   white on black, since iOS keeps only its brightness and tints that.
## - art/launcher/windows.svg: Windows draws icons unmasked, so the shape is drawn here: a
##   rounded tile on a clear square.
## godot --headless --path . -s tools/make_app_icon.gd [-- <dragon>]

## The icon's dragon when none is named. The console's art import reads this to know
## when a new rig means a new icon (tools/console/art_import.py).
const DEFAULT_DRAGON := "grimroch"
## tokens PARCHMENT, the colour of all primary text and icons on stone (specs/019).
const INK := "#f1e3d1"
## The ground glows from behind the head: tokens STONE_RAISED lifted at the centre, through
## STONE, down to WELL (darker than GROUND) at the corners, so the icon has depth without
## leaving the Inkstone and Brass palette (specs/019).
const GROUND := "<defs><radialGradient id=\"ground\" cx=\"0.5\" cy=\"0.42\" r=\"0.75\"><stop offset=\"0\" stop-color=\"#2e4347\"/><stop offset=\"0.55\" stop-color=\"#172225\"/><stop offset=\"1\" stop-color=\"#0a1012\"/></radialGradient></defs>"
## How much of the 1024 square the head's longer side fills: the icon, and the adaptive
## layers, whose outer third can be cut away by the launcher's mask.
const ICON_FILL := 0.8
const LAYER_FILL := 0.56
## Windows' tile: inset from the square's edge, its corner radius, and the head inside it.
const TILE_INSET := 64.0
const TILE_RADIUS := 192.0
const TILE_FILL := 0.68


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 1:
		push_error("usage: godot --headless --path . -s tools/make_app_icon.gd [-- <dragon>]")
		quit(1)
		return
	var dragon: String = args[0] if args.size() == 1 else DEFAULT_DRAGON
	var source := "res://art/creatures/%s-rig-head-whole.svg" % dragon
	var svg := FileAccess.get_file_as_string(source)
	if svg == "":
		push_error("no head at " + source + "; run tools/split_rig.py first")
		quit(1)
		return
	# Where the head is in its 512 canvas, measured from a 4x drawing of it.
	var img := Image.new()
	img.load_svg_from_string(svg, 4.0)
	var used := img.get_used_rect()
	var box := Rect2(Vector2(used.position) / 4.0, Vector2(used.size) / 4.0)
	var inner := svg.substr(svg.find(">", svg.find("<svg")) + 1)
	inner = inner.substr(0, inner.rfind("</svg>"))
	# The masks keep their white; the head itself is drawn in ink.
	var cut := inner.find("</defs>") + "</defs>".length()
	var defs := inner.substr(0, cut)
	var head := inner.substr(cut)
	var inked := defs + head.replace("fill=\"#fff\"", "fill=\"%s\"" % INK)
	var glow := GROUND + "<rect width=\"1024\" height=\"1024\" fill=\"url(#ground)\"/>"
	var black := "<rect width=\"1024\" height=\"1024\" fill=\"#000000\"/>"
	var tile := GROUND + "<rect x=\"%d\" y=\"%d\" width=\"%d\" height=\"%d\" rx=\"%d\" fill=\"url(#ground)\"/>" % [
			int(TILE_INSET), int(TILE_INSET), int(1024.0 - 2.0 * TILE_INSET), int(1024.0 - 2.0 * TILE_INSET), int(TILE_RADIUS)]
	_write("res://icon.svg", _square(box, ICON_FILL, inked, glow))
	_write("res://art/launcher/foreground.svg", _square(box, LAYER_FILL, inked, ""))
	_write("res://art/launcher/monochrome.svg", _square(box, LAYER_FILL, inner, ""))
	_write("res://art/launcher/background.svg", _square(box, 0.0, "", glow))
	_write("res://art/launcher/ios_dark.svg", _square(box, ICON_FILL, inked, ""))
	_write("res://art/launcher/ios_tinted.svg", _square(box, ICON_FILL, inner, black))
	_write("res://art/launcher/windows.svg", _square(box, TILE_FILL, inked, tile))
	print("icon from %s, head at %s" % [source, box])
	quit()


## A 1024 square over `ground` (SVG drawn first, or "" for clear) with the head centred,
## its longer side `fill` of the square.
func _square(box: Rect2, fill: float, head: String, ground: String) -> String:
	var out := "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1024\" height=\"1024\" viewBox=\"0 0 1024 1024\">\n"
	if ground != "":
		out += ground + "\n"
	if head != "":
		var k := 1024.0 * fill / maxf(box.size.x, box.size.y)
		var at := Vector2(512, 512) - box.get_center() * k
		out += "<g transform=\"translate(%.2f %.2f) scale(%.4f)\">%s</g>\n" % [at.x, at.y, k, head]
	return out + "</svg>\n"


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
