extends SceneTree
## Times the living Ether fields: eleven Mage Card faces (a seven-card offer, three
## slots and the hover detail) moving at once in a 1280 x 720 window, for ten seconds.
## Prints the average, 99th-percentile and worst frame time, and PASS when the
## average holds 60 fps and the 99th percentile stays under two frames. A single
## stall from the operating system shows as the worst frame without failing it.
## godot --path . -s tools/field_bench.gd

const SECONDS := 10.0
const FACES := 11

var _frames: Array = []


func _initialize() -> void:
	_run()


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	# Let the window render as fast as it can, so the frame time is the real cost.
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var db = load("res://engine/card_db.gd").new()
	# Behind the faces, the stone backdrop (feature 006), as on the play screen.
	var bg := ColorRect.new()
	bg.color = Color("100e17")
	bg.size = Vector2(1280, 720)
	bg.material = ShaderMaterial.new()
	bg.material.shader = load("res://ui/fx/shaders/backdrop.gdshader")
	root.add_child(bg)
	var layer = load("res://ui/fx/backdrop_layer.gd").new()
	layer.size = Vector2(1280, 720)
	root.add_child(layer)
	layer.setup(bg.material)
	layer.material_ref.set_shader_parameter("view_size", Vector2(1280, 720))
	layer.set_stone(true)
	var ids: Array = db.mage_ids()
	for i in FACES:
		var id: String = ids[(i * 5) % ids.size()]
		var m: Dictionary = db.mage(id)
		var face = load("res://ui/widgets/card_face.gd").new()
		face.size = Vector2(160, 224)
		face.position = Vector2(20 + (i % 7) * 178, 30 + (i / 7) * 250)
		face.set_model({"id": id, "name": m.name, "element": m.element, "level": 2, "stats": db.mage_level(id, 2)})
		face.motion = true
		bg.add_child(face)
	for i in 30:
		await process_frame
	var start := Time.get_ticks_usec()
	var last := start
	while (Time.get_ticks_usec() - start) / 1e6 < SECONDS:
		await process_frame
		var now := Time.get_ticks_usec()
		_frames.append((now - last) / 1000.0)
		last = now
	var total := 0.0
	var worst := 0.0
	for f in _frames:
		total += f
		worst = maxf(worst, f)
	var avg := total / _frames.size()
	var sorted := _frames.duplicate()
	sorted.sort()
	var p99: float = sorted[int(sorted.size() * 0.99)]
	print("field bench: %d frames, average %.2f ms, 99th percentile %.2f ms, worst %.2f ms" % [_frames.size(), avg, p99, worst])
	print("PASS" if avg <= 16.7 and p99 <= 33.0 else "FAIL")
	quit()
