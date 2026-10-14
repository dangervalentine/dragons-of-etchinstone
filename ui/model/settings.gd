extends RefCounted
## The few things remembered between games: the motion preference and the options
## of the last game started. Kept in a small file on the device.

const PATH := "user://settings.cfg"
const MOTION := ["system", "reduced", "full"]
const DEFAULT_OPTIONS := {"dragon": "rodving", "difficulty": "normal", "cavalier": false, "glass_cannon": false}

static var motion := "system"
static var last_options := DEFAULT_OPTIONS.duplicate()


static func load_all() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	var m = cfg.get_value("display", "motion", "system")
	motion = m if MOTION.has(m) else "system"
	var opts = cfg.get_value("game", "last_options", {})
	if opts is Dictionary:
		for key in DEFAULT_OPTIONS:
			if opts.has(key) and typeof(opts[key]) == typeof(DEFAULT_OPTIONS[key]):
				last_options[key] = opts[key]


static func save_all() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "motion", motion)
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
