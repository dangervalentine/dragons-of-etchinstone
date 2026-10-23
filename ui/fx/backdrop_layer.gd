extends Control
## The ground's settings (specs/019 FR-005, FR-006): the flat ground, and the glow in
## the current Region's tint that lies behind the Encounter or Region Card in play.
## It replaces feature 006's stone grounds, and the menu's choice of them (FR-006a).

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

## How far the wash reaches, as a share of the view's height: far enough that it
## shows round the card it lies behind and under the tray (the system's "large soft
## radial glow").
const REACH := 0.9

var material_ref: ShaderMaterial
var _tween: Tween
## The tint now washing the ground, or null for none.
var _tint = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## Take charge of the backdrop's shader.
func setup(m: ShaderMaterial) -> void:
	material_ref = m
	m.set_shader_parameter("ground", T.GROUND)
	m.set_shader_parameter("wash_amount", 0.0)
	resized.connect(func():
		m.set_shader_parameter("view_size", size)
		m.set_shader_parameter("wash_radius", size.y * REACH))


## The tint of a stage (vs.stage): a Region's own colour, the lair's for the Final
## Battle, or null where there is no game.
static func tint_of(stage) -> Variant:
	if stage == null or not stage is Dictionary or stage.is_empty():
		return null
	if stage.get("kind") == "final":
		return T.REGION_LAIR
	return T.REGION.get(int(stage.get("region", 0)))


## Wash the ground in `stage`'s tint, glowing round `centre` (global pixels), or
## clear it. A change of tint fades over a move, or happens at once in reduced motion.
func set_region(stage, centre := Vector2.ZERO) -> void:
	if material_ref == null:
		return
	var tint = tint_of(stage)
	if tint != null:
		material_ref.set_shader_parameter("wash_centre", centre - global_position)
	if typeof(tint) == typeof(_tint) and (tint == null or tint == _tint):
		return
	var from_amount: float = material_ref.get_shader_parameter("wash_amount")
	var to_amount := T.REGION_WASH if tint != null else 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if tint != null:
		if _tint == null or UI.reduced_motion or not is_inside_tree():
			material_ref.set_shader_parameter("wash", tint)
		else:
			_tween = create_tween()
			_tween.tween_method(func(c): material_ref.set_shader_parameter("wash", c), _tint, tint, T.MOVE)
	_tint = tint
	if UI.reduced_motion or not is_inside_tree():
		material_ref.set_shader_parameter("wash_amount", to_amount)
		return
	if _tween == null or not _tween.is_valid():
		_tween = create_tween()
	_tween.parallel().tween_method(func(v): material_ref.set_shader_parameter("wash_amount", v), from_amount, to_amount, T.MOVE)
