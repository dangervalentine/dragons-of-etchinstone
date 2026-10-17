extends "res://tests/base.gd"
## The window mode is remembered with the other settings, and a bad value falls back.

const Settings = preload("res://ui/model/settings.gd")


func test_window_mode_is_remembered() -> void:
	var kept: Variant = _keep()
	var before: String = Settings.window_mode
	Settings.window_mode = "fullscreen"
	Settings.save_all()
	Settings.window_mode = "windowed"
	Settings.load_all()
	eq(Settings.window_mode, "fullscreen", "full screen comes back")
	var cfg := ConfigFile.new()
	cfg.load(Settings.PATH)
	cfg.set_value("display", "window", "huge")
	cfg.save(Settings.PATH)
	Settings.load_all()
	eq(Settings.window_mode, "windowed", "an unknown mode opens windowed")
	Settings.window_mode = before
	_restore(kept)
	Settings.load_all()


## The developer's own settings file, to put back after.
func _keep() -> Variant:
	return FileAccess.get_file_as_bytes(Settings.PATH) if FileAccess.file_exists(Settings.PATH) else null


func _restore(kept: Variant) -> void:
	if kept == null:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.PATH))
	else:
		var f := FileAccess.open(Settings.PATH, FileAccess.WRITE)
		f.store_buffer(kept)
		f.close()
