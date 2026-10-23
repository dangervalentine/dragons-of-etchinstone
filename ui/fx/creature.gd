extends Control
## A painted creature, or the Final Journey's silhouette, that is never quite still:
## it breathes, sways or glows (see creature_idle.gdshader), bent in places by soft
## bones (Art.BONES), and its Ether drifts around it as embers, bubbles, sparks or
## dark motes. A crop can show just a region of the art, filling the widget with the
## rest of the picture clipped; the Ether still drifts past the edge. All of it stops
## in reduced motion.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const Art = preload("res://ui/model/art.gd")
const IDLE = preload("res://ui/fx/shaders/creature_idle.gdshader")

## Room drawn around the art on every side, as a share of its side, so a part that
## moves past the edge of its square (antlers lifting, a tail whipping) isn't cut off.
const MARGIN := 0.15
## As many soft bones as it bends the art with.
const MAX_BONES := 8
const MODES := {"still": 0, "breathe": 1, "sway": 2, "glow": 3}

var art_name := ""
var element := ""
## The region of the art to show, in its 512 units: all of it, or a part such as a
## dragon's head (Art.head), which is then fitted and centred in the widget, the art
## beyond it clipped by the frame. The art stays whole, so parts pivot as usual;
## tweening it zooms.
var crop := Art.FULL:
	set(value):
		crop = value
		_frame.clip_contents = crop != Art.FULL
		_fit()
## Holds the picture and clips it to the widget when cropped; the
## particles sit outside it, free to drift past the edge.
var _frame := Control.new()
## The art.
var _picture := _layer()
var _particles: CPUParticles2D
## A bevelled frame the picture is cut to (set_cut()), in the widget's own units:
## {box, top, bottom}, or empty for none.
var _cut := {}
var _still := false
## Kept still whatever the motion setting: a creature on the Region Card, or one
## waiting for the Deck's zoom to land before it wakes (specs/012 research R7).
var held := false: set = set_held
## Whether a painted figure has an ink line round it (T.CREATURE_LINE), to stand off
## its panel. Off for a faint emblem, which should sink into its card.
var outlined := false: set = set_outlined



func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	_frame.add_child(_picture)
	resized.connect(_fit)


static func _layer() -> TextureRect:
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.material = ShaderMaterial.new()
	t.material.shader = IDLE
	return t


## name: a picture in art/painted/, or a silhouette in art/creatures/. tint: the
## silhouette's colour. ether: which particles drift around it, or "" for none.
func setup(name: String, tint: Color, ether := "", particles := true) -> void:
	art_name = name
	element = ether
	var painted := UI.is_painted(name)
	_picture.texture = UI.art(name)
	_idle(_picture, name, tint)
	var m: ShaderMaterial = _picture.material
	m.set_shader_parameter("painted", painted)
	var bones := Art.bones(name)
	assert(bones.size() <= MAX_BONES, name + " has more bones than the shader bends")
	var lines := PackedVector4Array()
	var bone_moves := PackedVector4Array()
	var reach := PackedFloat32Array()
	var last := PackedInt32Array()
	for i in MAX_BONES:
		var b: Dictionary = bones[i] if i < bones.size() else {}
		var joint: Vector2 = b.get("joint", Vector2.ZERO) / 512.0
		var tip: Vector2 = b.get("tip", Vector2.ZERO) / 512.0
		lines.append(Vector4(joint.x, joint.y, tip.x, tip.y))
		bone_moves.append(Vector4(Art.MOVES[b.get("motion", "still")], b.get("angle", 0.0), b.get("period", 1.0), b.get("phase", 0.0)))
		reach.append(b.get("reach", 0.0) / 512.0)
		last.append(b.get("last", i))
	m.set_shader_parameter("bones", bones.size())
	m.set_shader_parameter("bone_lines", lines)
	m.set_shader_parameter("bone_moves", bone_moves)
	m.set_shader_parameter("bone_reach", reach)
	m.set_shader_parameter("bone_last", last)
	if _particles != null:
		_particles.queue_free()
		_particles = null
	# The dragons move enough on their own; only the others have their Ether drifting
	# round them.
	if particles and ether != "" and not Art.DRAGONS.values().has(name):
		_particles = _make_particles(ether)
		add_child(_particles)
	_still = not (UI.reduced_motion or held)
	_apply_motion()
	_fit()


## How the art idles and its tint.
static func _idle(layer: TextureRect, name: String, tint: Color) -> void:
	var m: ShaderMaterial = layer.material
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("mode", MODES[Art.motion(name)])
	m.set_shader_parameter("speed", Art.speed(name))
	m.set_shader_parameter("phase", float(hash(name) % 628) / 100.0)


## Draws the art as one flat `tint` cut to its shape, painted or not, or, with a
## clear tint, back in its own colours. Call after setup().
func silhouette(tint: Color) -> void:
	var m: ShaderMaterial = _picture.material
	var flat := tint.a > 0.0
	m.set_shader_parameter("painted", UI.is_painted(art_name) and not flat)
	if flat:
		m.set_shader_parameter("tint", tint)


func set_outlined(on: bool) -> void:
	outlined = on
	var m: ShaderMaterial = _picture.material
	m.set_shader_parameter("line_color", T.CREATURE_LINE if on else Color(T.SHADE, 0))
	m.set_shader_parameter("line_width", T.CREATURE_LINE_SHARE)
	m.set_shader_parameter("line_min", T.CREATURE_LINE_MIN)


func set_held(on: bool) -> void:
	held = on
	_apply_motion()


func _process(_delta: float) -> void:
	if _still != (UI.reduced_motion or held):
		_apply_motion()


func _apply_motion() -> void:
	_still = UI.reduced_motion or held
	_picture.material.set_shader_parameter("amount", 0.0 if _still else 1.0)
	if _particles != null:
		_particles.emitting = not _still
		_particles.visible = not _still


## Where the art's square is in the widget: scaled so `crop` fits the widget and
## placed so `crop` is centred in it.
func art_rect() -> Rect2:
	var zoom := minf(size.x / crop.size.x, size.y / crop.size.y)
	var side := Art.FULL.size.x * zoom
	return Rect2((size - crop.size * zoom) / 2.0 - crop.position * zoom, Vector2(side, side))


## Cut the picture to `box` (in the widget's own units) with its top-right and
## bottom-right corners cut away by `top` and `bottom`, as a Region Card panel's
## frame is: drawn so by the shader, so it holds inside other clipping.
func set_cut(box: Rect2, top: float, bottom: float) -> void:
	_cut = {"box": box, "top": top, "bottom": bottom}
	_apply_cut()


func _apply_cut() -> void:
	var m: ShaderMaterial = _picture.material
	m.set_shader_parameter("cut", not _cut.is_empty())
	if _cut.is_empty():
		return
	# The shader works in the picture's units: the box moved by where the picture sits.
	var box: Rect2 = _cut.box
	var at := box.position - _frame.position - _picture.position
	m.set_shader_parameter("cut_box", Vector4(at.x, at.y, box.size.x, box.size.y))
	m.set_shader_parameter("cut_corners", Vector2(_cut.top, _cut.bottom))


func _fit() -> void:
	# The picture is the whole square of art, scaled so `crop` fits the widget and
	# placed so `crop` is centred in it.
	var art := art_rect()
	_frame.position = Vector2.ZERO
	_frame.size = size
	# The picture is the art with MARGIN round it, which the shader leaves room for.
	_picture.position = art.position - art.size * MARGIN
	_picture.size = art.size * (1.0 + 2.0 * MARGIN)
	_picture.material.set_shader_parameter("pad", MARGIN / (1.0 + 2.0 * MARGIN))
	_apply_cut()
	if _particles != null:
		_particles.position = size / 2.0
		_particles.emission_rect_extents = size * Vector2(0.34, 0.3)
		var k := size.y / 300.0
		# The shapes are 64 pixels; these make them about 8 to 22 units at full size.
		var small := 0.18 if element == "lightning" else 0.13
		_particles.scale_amount_min = small * k
		_particles.scale_amount_max = small * 2.6 * k
		_particles.initial_velocity_min = _speed_range(element).x * k
		_particles.initial_velocity_max = _speed_range(element).y * k


static func _speed_range(ether: String) -> Vector2:
	match ether:
		"fire":
			return Vector2(18, 42)
		"water":
			return Vector2(10, 24)
		"lightning":
			return Vector2(70, 140)
	return Vector2(6, 16)


## Each Ether's particle as a flat woodcut shape (feature 006): a tongue of flame,
## a drop of water, a forked spark, a curl of smoke. White, so the colour ramp tints
## it. 64 pixels square; drawn once and shared.
const SHAPES := {
	"fire": '<path d="M32 3C41 17 53 27 50 43C48 56 39 61 32 61C25 61 15 56 14 43C13 33 21 28 24 17C26 26 29 29 32 31C34 22 30 13 32 3Z"/>',
	"water": '<path d="M32 5C41 22 51 32 51 44C51 55 42 61 32 61C22 61 13 55 13 44C13 32 23 22 32 5Z"/>',
	"lightning": '<path d="M39 2L17 35H30L23 62L49 24H36Z"/>',
	"shadow": '<path d="M12 56C10 34 46 42 41 22C38 11 24 13 27 23" fill="none" stroke="#fff" stroke-width="8" stroke-linecap="round"/>',
}
static var _shapes := {}


static func _shape(ether: String) -> Texture2D:
	var key: String = ether if SHAPES.has(ether) else "shadow"
	if not _shapes.has(key):
		var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="#fff">%s</svg>' % SHAPES[key]
		var img := Image.new()
		img.load_svg_from_string(svg, 1.0)
		_shapes[key] = ImageTexture.create_from_image(img)
	return _shapes[key]


func _make_particles(ether: String) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = _shape(ether)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.local_coords = true
	var c: Color = T.ether(ether).lightened(0.25)
	var ramp := Gradient.new()
	match ether:
		"fire":
			# Embers rising and fading.
			p.amount = 16
			p.lifetime = 2.4
			p.direction = Vector2(0, -1)
			p.spread = 18.0
			p.gravity = Vector2(0, -12)
			ramp.set_color(0, Color(T.ether_shade("fire", "lit"), 0.0))
			ramp.add_point(0.15, Color(T.ether_shade("fire", "lit"), 0.95))
			ramp.set_color(ramp.get_point_count() - 1, Color(c, 0.0))
		"water":
			# Bubbles drifting up, wobbling.
			p.amount = 12
			p.lifetime = 3.2
			p.direction = Vector2(0, -1)
			p.spread = 12.0
			p.gravity = Vector2(0, -4)
			p.orbit_velocity_min = -0.02
			p.orbit_velocity_max = 0.02
			ramp.set_color(0, Color(c, 0.0))
			ramp.add_point(0.25, Color(c, 0.7))
			ramp.set_color(ramp.get_point_count() - 1, Color(c, 0.0))
		"lightning":
			# Sparks that crackle out in short bursts.
			p.amount = 8
			p.lifetime = 1.7
			p.explosiveness = 0.85
			p.direction = Vector2(0, -1)
			p.spread = 180.0
			p.damping_min = 120.0
			p.damping_max = 200.0
			p.angle_min = -35.0
			p.angle_max = 35.0
			ramp.set_color(0, T.SHEEN.lerp(T.ether_shade("lightning", "lit"), 0.25))
			ramp.add_point(0.12, Color(c, 0.9))
			ramp.add_point(0.22, Color(c, 0.0))
			ramp.set_color(ramp.get_point_count() - 1, Color(c, 0.0))
		_:
			# Dark motes wandering.
			p.amount = 14
			p.lifetime = 4.5
			p.direction = Vector2(0.3, -1)
			p.spread = 60.0
			p.gravity = Vector2(0, -2)
			p.angle_min = -180.0
			p.angle_max = 180.0
			p.angular_velocity_min = -20.0
			p.angular_velocity_max = 20.0
			var dark: Color = T.ether("shadow").darkened(0.15)
			ramp.set_color(0, Color(dark, 0.0))
			ramp.add_point(0.3, Color(dark, 0.75))
			ramp.set_color(ramp.get_point_count() - 1, Color(dark, 0.0))
	p.color_ramp = ramp
	p.preprocess = p.lifetime
	return p
