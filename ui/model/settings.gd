extends RefCounted
## The few things remembered between games: the motion preference, the ground the
## board stands on, whether a desktop window is full screen and the options of the
## last game started. Kept in a small file on the device.

const PATH := "user://settings.cfg"
const MOTION := ["system", "reduced", "full"]
## How a desktop game's window opens (feature 008).
const WINDOW := ["windowed", "fullscreen"]
const DEFAULT_OPTIONS := {"dragon": "rodving", "difficulty": "normal", "cavalier": false, "glass_cannon": false}

## The ground patterns (feature 006): art/stone/ground-<n>.png, picked in the menu.
const GROUNDS := 4

static var motion := "system"
static var ground := 1
static var window_mode := "windowed"
static var last_options := DEFAULT_OPTIONS.duplicate()


static func load_all() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	var m = cfg.get_value("display", "motion", "system")
	motion = m if MOTION.has(m) else "system"
	var g = cfg.get_value("display", "ground", 1)
	ground = g if g is int and g >= 1 and g <= GROUNDS else 1
	var w = cfg.get_value("display", "window", "windowed")
	window_mode = w if WINDOW.has(w) else "windowed"
	var opts = cfg.get_value("game", "last_options", {})
	if opts is Dictionary:
		for key in DEFAULT_OPTIONS:
			if opts.has(key) and typeof(opts[key]) == typeof(DEFAULT_OPTIONS[key]):
				last_options[key] = opts[key]


static func save_all() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "motion", motion)
	cfg.set_value("display", "ground", ground)
	cfg.set_value("display", "window", window_mode)
	cfg.set_value("game", "last_options", last_options)
	cfg.save(PATH)


## Whether to replace travel and shaking with fades: the player's choice, or the
## device's accessibility setting when they left it to the device.
static func reduced_motion() -> bool:
	match motion:
		"reduced":
			return true
		"full":
			return false
	var device := DisplayServer.accessibility_should_reduce_animation()
	if device == 1:
		return true
	if device == 0:
		return false
	if OS.has_feature("web"):
		var r = JavaScriptBridge.eval("window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches", true)
		return r == true
	return false
