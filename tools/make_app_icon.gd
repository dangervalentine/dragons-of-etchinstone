extends SceneTree
## Makes the app icon from a dragon's head alone (art/creatures/<name>-rig-head-whole.svg,
## from tools/split_rig.py): icon.svg, the head in ink on the app's dark ground, and
## Android's adaptive launcher layers in art/launcher/, the head sized to the safe circle
## over a solid ground, and a plain head for themed icons.
## godot --headless --path . -s tools/make_app_icon.gd -- grimroch

const INK := "#f1ecdf"
const GROUND := "#100e17"
## How much of the 1024 square the head's longer side fills: the icon, and the adaptive
## layers, whose outer third can be cut away by the launcher's mask.
const ICON_FILL := 0.8
const LAYER_FILL := 0.56


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("usage: godot --headless --path . -s tools/make_app_icon.gd -- <dragon>")
		quit(1)
		return
	var source := "res://art/creatures/%s-rig-head-whole.svg" % args[0]
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
	_write("res://icon.svg", _square(box, ICON_FILL, inked, true))
	_write("res://art/launcher/foreground.svg", _square(box, LAYER_FILL, inked, false))
	_write("res://art/launcher/monochrome.svg", _square(box, LAYER_FILL, inner, false))
	_write("res://art/launcher/background.svg", _square(box, 0.0, "", true))
	print("icon from %s, head at %s" % [source, box])
	quit()


## A 1024 square with the head centred, its longer side `fill` of the square.
func _square(box: Rect2, fill: float, head: String, ground: bool) -> String:
	var out := "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1024\" height=\"1024\" viewBox=\"0 0 1024 1024\">\n"
	if ground:
		out += "<rect width=\"1024\" height=\"1024\" fill=\"%s\"/>\n" % GROUND
	if head != "":
		var k := 1024.0 * fill / maxf(box.size.x, box.size.y)
		var at := Vector2(512, 512) - box.get_center() * k
		out += "<g transform=\"translate(%.2f %.2f) scale(%.4f)\">%s</g>\n" % [at.x, at.y, k, head]
	return out + "</svg>\n"


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
