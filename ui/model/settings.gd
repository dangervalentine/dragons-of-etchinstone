extends RefCounted
## The few things remembered between games: the motion preference, whether a
## desktop window is full screen, the options of the
## last game started, which dragons have been unlocked and which lessons are finished
## (specs/017). Kept in a small file on the device.

const PATH := "user://settings.cfg"
## The tools' own settings (use_for_tools).
const TOOL_PATH := "user://tool_settings.cfg"
const MOTION := ["system", "reduced", "full"]
## How a desktop game's window opens (feature 008).
const WINDOW := ["windowed", "fullscreen"]
const DEFAULT_OPTIONS := {"dragon": "rodving", "difficulty": "normal", "cavalier": false, "glass_cannon": false, "persistent_xp": false}

## The dragons locked on a fresh install. What unlocks each is to come; for now,
## in development, a triple tap on the menu's title unlocks them all.
const LOCKED_AT_START := ["vuurhast", "grimroch", "helsang"]

## The lessons, in order (specs/017): kept in step with ui/model/lessons.gd, which a
## test checks, so a saved id that no longer names a lesson is dropped on load.
const LESSON_IDS := ["setting_out", "victory", "narrow", "loss", "fuse", "region_end"]

static var motion := "system"
static var window_mode := "windowed"
static var last_options := DEFAULT_OPTIONS.duplicate()
## Ask before leaving the Upgrade step with XP that could still Upgrade a card; off
## once the player ticks "Don't show this again".
static var warn_unspent_xp := true
## Which edition new games are played in: false for Classic, the rulebook as printed;
## true for House rules, which offers this edition's own rules too (editions.gd).
static var house_rules := false
## The dragons of LOCKED_AT_START unlocked since.
static var unlocked: Array = []
## Every dragon open for this run only, never saved: set by the tools that walk
## every dragon, so they neither meet a lock nor unlock the player's dragons.
static var unlock_for_run := false
## The lessons finished, by id (specs/017).
static var lessons: Array = []
## Set once the summary has shown after the last lesson.
static var tutorial_done := false
## Set once the first Play press has offered the lessons, whatever the answer.
static var tutorial_offered := false
## The file read and written: PATH, or a tool's own file (use_path), so the checks
## never touch the player's settings or lesson progress (specs/017 research R8).
static var path := PATH


static func load_all() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	var m = cfg.get_value("display", "motion", "system")
	motion = m if MOTION.has(m) else "system"
	# display/ground, the stone pattern earlier versions let the player choose, is
	# left unread: the board stands on one ground now (specs/019 FR-006a).
	var w = cfg.get_value("display", "window", "windowed")
	window_mode = w if WINDOW.has(w) else "windowed"
	warn_unspent_xp = cfg.get_value("play", "warn_unspent_xp", true) == true
	house_rules = cfg.get_value("play", "house_rules", false) == true
	var u = cfg.get_value("progress", "unlocked", [])
	unlocked = Array(u).filter(func(id): return LOCKED_AT_START.has(id)) if u is Array else []
	var l = cfg.get_value("progress", "lessons", [])
	lessons = Array(l).filter(func(id): return LESSON_IDS.has(id)) if l is Array else []
	tutorial_done = cfg.get_value("progress", "tutorial_done", false) == true
	tutorial_offered = cfg.get_value("progress", "tutorial_offered", false) == true
	var opts = cfg.get_value("game", "last_options", {})
	if opts is Dictionary:
		for key in DEFAULT_OPTIONS:
			if opts.has(key) and typeof(opts[key]) == typeof(DEFAULT_OPTIONS[key]):
				last_options[key] = opts[key]


static func save_all() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "motion", motion)
	cfg.set_value("display", "window", window_mode)
	cfg.set_value("game", "last_options", last_options)
	cfg.set_value("play", "warn_unspent_xp", warn_unspent_xp)
	cfg.set_value("play", "house_rules", house_rules)
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.set_value("progress", "lessons", lessons)
	cfg.set_value("progress", "tutorial_done", tutorial_done)
	cfg.set_value("progress", "tutorial_offered", tutorial_offered)
	cfg.save(path)


## Points the settings at another file and starts from its contents (or the
## defaults).
static func use_path(p: String) -> void:
	path = p
	motion = "system"
	window_mode = "windowed"
	last_options = DEFAULT_OPTIONS.duplicate()
	warn_unspent_xp = true
	house_rules = false
	unlocked = []
	lessons = []
	tutorial_done = false
	tutorial_offered = false
	load_all()


## For the tools that play through the screens, as HistoryStore.use_empty: settings
## of their own, from the defaults, with the first Play's offer of the lessons
## already made, so a walk that presses Play meets the dragons as it always has.
static func use_for_tools(p := TOOL_PATH) -> void:
	if FileAccess.file_exists(p):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	use_path(p)
	tutorial_offered = true
	save_all()


## Whether the dragon cannot yet be chosen.
static func is_locked(dragon_id: String) -> bool:
	return LOCKED_AT_START.has(dragon_id) and not unlocked.has(dragon_id) and not unlock_for_run


## Unlocks every dragon and remembers it.
static func unlock_all() -> void:
	unlocked = LOCKED_AT_START.duplicate()
	save_all()


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
