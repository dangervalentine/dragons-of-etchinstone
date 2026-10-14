extends Control
## A creature or landscape silhouette that is never quite still: it breathes,
## hovers or sways (see creature_idle.gdshader), and its Ether drifts around it
## as embers, bubbles, sparks or dark motes. Some are cut in two (Art.PARTS), and
## their moving part, a jaw or a head, works on its own over the body. All of it
## stops in reduced motion.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const Art = preload("res://ui/model/art.gd")
const IDLE = preload("res://ui/fx/shaders/creature_idle.gdshader")

const MODES := {"still": 0, "breathe": 1, "hover": 2, "sway": 3, "wave": 4, "shimmer": 5, "flow": 6, "glow": 7}

var art_name := ""
var element := ""
var _picture := _layer()
## The moving part, over the picture; null when the art is one piece.
var _part: TextureRect
var _particles: CPUParticles2D
var _still := false
static var _dot: Texture2D


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_picture)
	resized.connect(_fit)


static func _layer() -> TextureRect:
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.material = ShaderMaterial.new()
	t.material.shader = IDLE
	return t


## name: a file in art/creatures/. tint: the silhouette's colour. ether: which
## particles drift around it, or "" for none.
func setup(name: String, tint: Color, ether := "", particles := true) -> void:
	art_name = name
	element = ether
	var rig := Art.part(name)
	if _part != null:
		_part.queue_free()
		_part = null
	_picture.texture = UI.art(name + "-base" if not rig.is_empty() else name)
	_idle(_picture, name, tint)
	if not rig.is_empty():
		_part = _layer()
		_part.texture = UI.art(name + "-part")
		_idle(_part, name, tint)
		var m: ShaderMaterial = _part.material
		m.set_shader_parameter("part_motion", 1)
		m.set_shader_parameter("pivot", rig.pivot / 512.0)
		m.set_shader_parameter("hinge_angle", rig.angle)
		m.set_shader_parameter("part_period", rig.period)
		add_child(_part)
	if _particles != null:
		_particles.queue_free()
		_particles = null
	if particles and ether != "":
		_particles = _make_particles(ether)
		add_child(_particles)
	_still = not UI.reduced_motion
	_apply_motion()
	_fit()


## The body and its part share every idle setting, so they move as one.
static func _idle(layer: TextureRect, name: String, tint: Color) -> void:
	var m: ShaderMaterial = layer.material
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("mode", MODES[Art.motion(name)])
	m.set_shader_parameter("speed", Art.speed(name))
	m.set_shader_parameter("phase", float(hash(name) % 628) / 100.0)


func _process(_delta: float) -> void:
	if _still != UI.reduced_motion:
		_apply_motion()


func _apply_motion() -> void:
	_still = UI.reduced_motion
	for layer in [_picture, _part]:
		if layer != null:
			layer.material.set_shader_parameter("amount", 0.0 if _still else 1.0)
	if _particles != null:
		_particles.emitting = not _still
		_particles.visible = not _still


func _fit() -> void:
	for layer in [_picture, _part]:
		if layer != null:
			layer.position = Vector2.ZERO
			layer.size = size
	if _particles != null:
		_particles.position = size / 2.0
		_particles.emission_rect_extents = size * Vector2(0.34, 0.3)
		var k := size.y / 300.0
		# The dot is 32 pixels; these make specks of about 6 to 17 units at full size.
		var small := 0.3 if element == "lightning" else 0.2
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


## A soft round dot for every particle.
static func _round_dot() -> Texture2D:
	if _dot == null:
		var g := GradientTexture2D.new()
		g.width = 32
		g.height = 32
		g.fill = GradientTexture2D.FILL_RADIAL
		g.fill_from = Vector2(0.5, 0.5)
		g.fill_to = Vector2(1.0, 0.5)
		var grad := Gradient.new()
		grad.set_color(0, Color(1, 1, 1, 1))
		grad.set_color(1, Color(1, 1, 1, 0))
		g.gradient = grad
		_dot = g
	return _dot


func _make_particles(ether: String) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = _round_dot()
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
			ramp.set_color(0, Color(T.GOLD, 0.0))
			ramp.add_point(0.15, Color(T.GOLD, 0.95))
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
			ramp.set_color(0, Color(1, 1, 0.85, 1.0))
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
			var dark: Color = T.ether("shadow").darkened(0.15)
			ramp.set_color(0, Color(dark, 0.0))
			ramp.add_point(0.3, Color(dark, 0.75))
			ramp.set_color(ramp.get_point_count() - 1, Color(dark, 0.0))
	p.color_ramp = ramp
	p.preprocess = p.lifetime
	return p
