extends Control
## The stone backdrop's settings: whether the play screen stands on stone or on
## the old flat background, and how large the view is. (Feature 006 first lit the
## stone's cracks with Ether light and drifting motes; the owner set that aside at
## the stage 2 review in favour of flat lines and strong raised boxes.)

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const Stone = preload("res://ui/theme/stone.gd")

var material_ref: ShaderMaterial
var _tween: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## Take charge of the backdrop's shader.
func setup(m: ShaderMaterial) -> void:
	material_ref = m
	m.set_shader_parameter("grain", Stone.grain())
	resized.connect(func(): m.set_shader_parameter("view_size", size))


## Stone (true) or the old flat background (false).
func set_stone(on: bool) -> void:
	if material_ref == null:
		return
	var to := 1.0 if on else 0.0
	var from = material_ref.get_shader_parameter("stone_amount")
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if from == null or UI.reduced_motion or not is_inside_tree():
		material_ref.set_shader_parameter("stone_amount", to)
		return
	_tween = create_tween()
	_tween.tween_method(func(v): material_ref.set_shader_parameter("stone_amount", v), from, to, T.BASE)
