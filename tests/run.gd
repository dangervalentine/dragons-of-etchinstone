extends SceneTree
## Headless test runner: godot --headless --path . -s tests/run.gd -- [name ...]
## Runs every test_* method of every tests/test_*.gd script, or only of the scripts
## whose file names contain one of the names given (`rules` runs test_rules.gd).


func _init() -> void:
	var failed := 0
	var total := 0
	var names_given := OS.get_cmdline_user_args()
	var files := []
	for f in DirAccess.get_files_at("res://tests"):
		if f.begins_with("test_") and f.ends_with(".gd") and _picked(f, names_given):
			files.append(f)
	files.sort()
	for f in files:
		var script = load("res://tests/" + f)
		if script == null or not script.can_instantiate():
			print("FAIL %s: script did not load" % f)
			failed += 1
			total += 1
			continue
		var names := []
		for m in script.get_script_method_list():
			if m.name.begins_with("test_") and not names.has(m.name):
				names.append(m.name)
		for n in names:
			var t = script.new()
			total += 1
			t.call(n)
			if t.checks == 0:
				t.errors.append("no assertions ran")
			if t.errors.size() > 0:
				failed += 1
				print("FAIL %s::%s" % [f, n])
				for e in t.errors:
					print("    " + e)
	print("%d tests, %d failed" % [total, failed])
	if total == 0:
		print("no test files match %s" % [names_given])
	quit(1 if failed > 0 or total == 0 else 0)


static func _picked(file: String, names_given: PackedStringArray) -> bool:
	if names_given.is_empty():
		return true
	for n in names_given:
		if file.contains(n):
			return true
	return false
