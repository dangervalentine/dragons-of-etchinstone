extends Control
## The rift: the Ether light that glows through the cracks in the stone backdrop,
## and the motes that drift from it. It holds the backdrop shader's rift settings
## (which Ether, where the light comes from, which zones it stays out from under)
## and runs its clock, which stops under reduced motion and while an overlay
## covers the screen.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const Stone = preload("res://ui/theme/stone.gd")

var material_ref: ShaderMaterial
var _clock := 0.0
var _live := true
var _busy := false
var _ether = null
var _tweens := {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## Take charge of the backdrop's shader.
func setup(m: ShaderMaterial) -> void:
	material_ref = m
	m.set_shader_parameter("grain", Stone.grain())
	m.set_shader_parameter("cracks", Stone.cracks())
	m.set_shader_parameter("seam_colour", T.SEAM_NEUTRAL)
	m.set_shader_parameter("ether_id", -1)
	m.set_shader_parameter("motion", 0.0 if UI.reduced_motion else 1.0)
	resized.connect(func(): m.set_shader_parameter("view_size", size))


func _process(delta: float) -> void:
	if material_ref == null or not _live or UI.reduced_motion:
		return
	_clock += delta * (0.5 if _busy else 1.0)
	material_ref.set_shader_parameter("clock", _clock)


## Carved stone (true) or the old flat background (false).
func set_stone(on: bool) -> void:
	_tween_param("stone_amount", 1.0 if on else 0.0, T.BASE)


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
	material_ref.set_shader_parameter("ether_id", T.ETHER_ID.get(element, -1) if element != null else -1)
	_tween_param("seam_colour", to, T.RIFT_TINT_TIME)


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


## Hold everything still while an overlay covers the screen.
func set_live(on: bool) -> void:
	_live = on


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
