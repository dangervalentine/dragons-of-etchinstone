extends Control
## The rift: the Ether light that glows through the cracks in the stone backdrop,
## and the motes that drift from it. It holds the backdrop shader's rift settings
## (which Ether, where the light comes from, which zones it stays out from under)
## and runs its clock, which stops under reduced motion and while an overlay
## covers the screen.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const Stone = preload("res://ui/theme/stone.gd")
const BoardResponse = preload("res://ui/model/board_response.gd")

var material_ref: ShaderMaterial
var _clock := 0.0
var _live := true
var _busy := false
var _ether = null
var _tweens := {}
var _motes := CPUParticles2D.new()
var _burst := CPUParticles2D.new()
var _seam_base: Color = T.SEAM_NEUTRAL
var _stone := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Motes of Ether drifting up from the rift, few and faint.
	var dot := GradientTexture2D.new()
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(1.0, 0.5)
	dot.width = 16
	dot.height = 16
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	dot.gradient = g
	for p in [_motes, _burst]:
		p.texture = dot
		p.local_coords = false
		p.direction = Vector2(0, -1)
		p.gravity = Vector2(0, -4)
		var fade := Gradient.new()
		fade.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
		fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0)])
		p.color_ramp = fade
		add_child(p)
	_motes.amount = T.MOTES_MAX
	_motes.lifetime = 5.5
	_motes.randomness = 0.3
	_motes.lifetime_randomness = 0.3
	_motes.preprocess = 5.0
	# They rise from the cracks anywhere on the stone, seen in the gaps between zones.
	_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_motes.spread = 55.0
	_motes.initial_velocity_min = 10.0
	_motes.initial_velocity_max = 28.0
	_motes.scale_amount_min = 0.3
	_motes.scale_amount_max = 0.75
	_burst.amount = 16
	_burst.one_shot = true
	_burst.emitting = false
	_burst.explosiveness = 0.9
	_burst.lifetime = 1.2
	_burst.spread = 180.0
	_burst.initial_velocity_min = 40.0
	_burst.initial_velocity_max = 110.0
	_burst.scale_amount_min = 0.3
	_burst.scale_amount_max = 0.7
	_motes.emitting = false


## Take charge of the backdrop's shader.
func setup(m: ShaderMaterial) -> void:
	material_ref = m
	m.set_shader_parameter("grain", Stone.grain())
	m.set_shader_parameter("cracks", Stone.cracks())
	m.set_shader_parameter("seam_colour", T.SEAM_NEUTRAL)
	m.set_shader_parameter("ether_id", -1)
	m.set_shader_parameter("motion", 0.0 if UI.reduced_motion else 1.0)
	m.set_shader_parameter("intensity", 1.0)
	resized.connect(func():
		m.set_shader_parameter("view_size", size)
		_motes.position = size / 2.0
		_motes.emission_rect_extents = size / 2.0)
	_set_mote_colour(T.SEAM_NEUTRAL)


func _process(delta: float) -> void:
	if material_ref == null or not _live or UI.reduced_motion:
		return
	_clock += delta * (0.5 if _busy else 1.0)
	material_ref.set_shader_parameter("clock", _clock)


## Carved stone (true) or the old flat background (false). The motes drift only
## over stone, and only when motion is allowed.
func set_stone(on: bool) -> void:
	_tween_param("stone_amount", 1.0 if on else 0.0, T.BASE)
	_stone = on
	_update_motes()


func _update_motes() -> void:
	_motes.emitting = _stone and _live and not _busy and not UI.reduced_motion
	_motes.speed_scale = 1.0 if _live else 0.0
	if UI.reduced_motion or not _stone:
		_motes.restart()
		_motes.emitting = false


func _set_mote_colour(c: Color) -> void:
	_motes.color = c
	_burst.color = c


## The rift takes an Ether's colour and character, or the neutral light for null.
func set_ether(element) -> void:
	if element == "":
		element = null
	if element == _ether and material_ref != null and material_ref.get_shader_parameter("seam_colour") != null:
		return
	_ether = element
	if material_ref == null:
		return
	var to: Color = T.ether_shade(element, "lit") if element != null else T.SEAM_NEUTRAL
	_seam_base = to
	material_ref.set_shader_parameter("ether_id", T.ETHER_ID.get(element, -1) if element != null else -1)
	_tween_param("seam_colour", to, T.RIFT_TINT_TIME)
	_set_mote_colour(to)


## Where the light comes from, as a point in this layer.
func set_source(point: Vector2) -> void:
	if material_ref != null:
		material_ref.set_shader_parameter("rift_source", point)


## The zones the light stays out from under (at most eight), as rectangles in this layer.
func set_zones(rects: Array) -> void:
	if material_ref == null:
		return
	var packed := []
	for r: Rect2 in rects.slice(0, 8):
		packed.append(Vector4(r.position.x, r.position.y, r.size.x, r.size.y))
	while packed.size() < 8:
		packed.append(Vector4.ZERO)
	material_ref.set_shader_parameter("zones", packed)
	material_ref.set_shader_parameter("zone_count", mini(rects.size(), 8))


## While a sequence plays, the seams move at half strength.
func set_busy(on: bool) -> void:
	_busy = on
	if material_ref != null and not UI.reduced_motion:
		material_ref.set_shader_parameter("motion", 0.5 if on else 1.0)
	_update_motes()


## Hold everything still while an overlay covers the screen.
func set_live(on: bool) -> void:
	_live = on
	_update_motes()


## The seams answer an event (contracts/board-life.md): surge brighter, dim, or
## burst into motes at `at`. In reduced motion the light is held in `colour` for a
## moment instead, with nothing moving.
func respond(event: String, colour: Color, at = null) -> void:
	if material_ref == null or not BoardResponse.TABLE.has(event):
		return
	var r: Dictionary = BoardResponse.TABLE[event]
	var d: float = r.motion.duration
	if UI.reduced_motion:
		material_ref.set_shader_parameter("seam_colour", colour)
		get_tree().create_timer(r.still.get("hold", T.BASE)).timeout.connect(
			func(): material_ref.set_shader_parameter("seam_colour", _seam_base))
		return
	match r.motion.kind:
		"surge":
			_pulse("intensity", 1.0, 1.9, d)
			_flash_colour(colour, d)
		"dim":
			_pulse("intensity", 1.0, 0.45, d)
			_flash_colour(colour, d)
		"burst":
			if at != null:
				_burst.position = at
				_burst.restart()
				_burst.emitting = true
		"sweep":
			_pulse("intensity", 1.0, 1.4, d)


func _pulse(name: String, base: float, peak: float, d: float) -> void:
	if _tweens.has(name) and _tweens[name].is_valid():
		_tweens[name].kill()
	var tw := create_tween()
	tw.tween_method(func(v): material_ref.set_shader_parameter(name, v), base, peak, d * 0.35)
	tw.tween_method(func(v): material_ref.set_shader_parameter(name, v), peak, base, d * 1.6)
	_tweens[name] = tw


func _flash_colour(c: Color, d: float) -> void:
	if _tweens.has("seam_colour") and _tweens["seam_colour"].is_valid():
		_tweens["seam_colour"].kill()
	var tw := create_tween()
	tw.tween_method(func(v): material_ref.set_shader_parameter("seam_colour", v), _seam_base, c, d * 0.35)
	tw.tween_method(func(v): material_ref.set_shader_parameter("seam_colour", v), c, _seam_base, d * 2.0)
	_tweens["seam_colour"] = tw


func _tween_param(name: String, to, time: float) -> void:
	if material_ref == null:
		return
	var from = material_ref.get_shader_parameter(name)
	if _tweens.has(name) and _tweens[name].is_valid():
		_tweens[name].kill()
	if from == null or UI.reduced_motion or not is_inside_tree():
		material_ref.set_shader_parameter(name, to)
		return
	var tw := create_tween()
	tw.tween_method(func(v): material_ref.set_shader_parameter(name, v), from, to, time)
	_tweens[name] = tw
