extends SceneTree
## Headless test runner: godot --headless --path . -s tests/run.gd
## Runs every test_* method of every tests/test_*.gd script.


func _init() -> void:
	var failed := 0
	var total := 0
	var files := []
	for f in DirAccess.get_files_at("res://tests"):
		if f.begins_with("test_") and f.ends_with(".gd"):
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
	quit(1 if failed > 0 else 0)
