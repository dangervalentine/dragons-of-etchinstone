extends "res://tests/base.gd"
## Settings saved by an earlier version still load (specs/019 FR-006a): the stone
## ground the player could once choose is ignored, not an error.

const Settings = preload("res://ui/model/settings.gd")

const TEST_PATH := "user://tool_settings_ground_test.cfg"


func test_an_old_ground_choice_is_ignored() -> void:
	var before: String = Settings.path
	var cfg := ConfigFile.new()
	cfg.set_value("display", "ground", 3)
	cfg.set_value("display", "motion", "reduced")
	cfg.save(TEST_PATH)
	Settings.use_path(TEST_PATH)
	Settings.load_all()
	eq(Settings.motion, "reduced", "the rest of the file still loads")
	ok(not FileAccess.get_file_as_string("res://ui/model/settings.gd").contains("static var ground"), "there is no ground setting any more")
	Settings.save_all()
	var saved := ConfigFile.new()
	saved.load(TEST_PATH)
	ok(not saved.has_section_key("display", "ground"), "saving drops the old key")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	Settings.use_path(before)
