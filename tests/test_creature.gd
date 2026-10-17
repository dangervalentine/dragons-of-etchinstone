extends "res://tests/base.gd"
## The creature's crop: the region it shows fills the widget, centred.

const Creature = preload("res://ui/fx/creature.gd")
const Art = preload("res://ui/model/art.gd")


func test_whole_art_fills_a_square_widget() -> void:
	var c := Creature.new()
	c.size = Vector2(200, 200)
	c._fit()
	eq(c.art_rect().position, Vector2.ZERO, "whole art sits at the corner")
	eq(c.art_rect().size, Vector2(200, 200), "whole art fills the widget")
	ok(not c._frame.clip_contents, "whole art is not clipped")
	c.free()


func test_whole_art_is_centred_in_a_wide_widget() -> void:
	var c := Creature.new()
	c.size = Vector2(300, 200)
	c._fit()
	eq(c.art_rect().position, Vector2(50, 0), "centred across")
	eq(c.art_rect().size, Vector2(200, 200), "kept square")
	c.free()


func test_a_crop_fills_the_widget_with_its_region() -> void:
	var c := Creature.new()
	c.size = Vector2(100, 100)
	c.crop = Rect2(256, 0, 256, 256)
	eq(c.art_rect().size, Vector2(200, 200), "the art is scaled so the region is the widget's size")
	eq(c.art_rect().position, Vector2(-100, 0), "and moved so the region is at the corner")
	ok(c._frame.clip_contents, "the rest of the picture is clipped")
	ok(not c.clip_contents, "but not the creature, so its Ether can drift past the edge")
	eq(c._frame.size, Vector2(100, 100), "the frame fills the widget")
	c.crop = Art.FULL
	ok(not c._frame.clip_contents, "back to whole art, unclipped")
	c.free()


func test_a_crop_is_centred_when_its_aspect_differs_from_the_widget() -> void:
	var c := Creature.new()
	c.size = Vector2(200, 100)
	c.crop = Rect2(0, 0, 256, 256)
	eq(c.art_rect().size, Vector2(200, 200), "scaled so the region's taller side fills the widget")
	eq(c.art_rect().position, Vector2(50, 0), "and centred across the wider widget")
	c.free()


func test_moving_parts_are_drawn_in_the_same_pass_as_the_body() -> void:
	# Layers each faded by the tint would read darker where the jaw overlaps the
	# throat; the shader draws every layer together and fades them once.
	var c := Creature.new()
	var tint := Color(0.8, 0.5, 0.2, 0.55)
	c.setup("grimroch", tint)
	var m: ShaderMaterial = c._picture.material
	var layers := Art.layers("grimroch")
	eq(m.get_shader_parameter("layers"), layers.size(), "grimroch's parts are all drawn by the body's shader")
	for i in layers.size():
		ok(m.get_shader_parameter("layer%d" % i) != null, "with layer %d's texture" % i)
	var jaw := layers.map(func(l): return l.art).find("grimroch-rig-jaw")
	eq(m.get_shader_parameter("pivots")[jaw], layers[jaw].pivot / 512.0, "the jaw turning about its hinge")
	eq(m.get_shader_parameter("parents")[jaw], layers.map(func(l): return l.art).find("grimroch-rig-head"), "carried by the head")
	ok(is_equal_approx(m.get_shader_parameter("tint").a, 0.55), "the tint's alpha goes to the one pass that draws them all")
	eq(c._frame.get_child_count(), 1, "one picture, no second layer")
	eq(m.get_shader_parameter("moves")[jaw].x, float(Art.MOVES.hinge), "the jaw on a hinge")
	c.setup("naga", tint)
	eq(m.get_shader_parameter("layers"), 0, "art in one piece has no layers")
	eq(m.get_shader_parameter("layer0"), null, "and no layer textures")
	c.free()


func test_the_shader_keeps_the_fade_of_the_nodes_above_it() -> void:
	# Writing COLOR drops the vertex colour, which carries the modulate of the
	# creature and its parents (a screen fading out); the shader keeps it and
	# multiplies it back in. Headless runs draw nothing, so this reads the source.
	var src := FileAccess.get_file_as_string("res://ui/fx/shaders/creature_idle.gdshader")
	var vertex := src.substr(src.find("void vertex()"))
	vertex = vertex.substr(0, vertex.find("}"))
	ok(vertex.contains("modulate = COLOR;"), "vertex() keeps the vertex colour")
	var fragment := src.substr(src.find("void fragment()"))
	var last := fragment.substr(fragment.rfind("COLOR ="))
	ok(last.contains("* modulate;"), "and the final COLOR is multiplied by it")
