shader_type canvas_item;
// The table every screen stands on (specs/019 contracts/materials-and-ground.md): the
// flat ground, and in play a large soft glow in the current Region's own tint behind
// the Encounter or Region Card, so each Region feels like its painting. In play the
// ground itself is the Region's own (T.REGION_GROUND), shaded by its grey texture
// (Art.GROUNDS), set by backdrop_layer.gd. It
// replaces the patterned stone of feature 006.

uniform vec4 ground : source_color = vec4(0.055, 0.082, 0.09, 1.0);
uniform vec4 wash : source_color = vec4(0.0, 0.0, 0.0, 1.0);
// 0 (no wash) to REGION_WASH.
uniform float wash_amount = 0.0;
// The glow's centre and reach, in the view's pixels.
uniform vec2 wash_centre = vec2(320.0, 360.0);
uniform float wash_radius = 432.0;
uniform vec2 view_size = vec2(1280.0, 720.0);
// The Region's grey ground texture, crossfading from texture_from to texture_to as
// texture_mix goes 0 to 1; texture_amount (0 to REGION_TEXTURE) is how hard it shades.
uniform sampler2D texture_from : filter_linear_mipmap;
uniform sampler2D texture_to : filter_linear_mipmap;
uniform float texture_mix = 1.0;
uniform float texture_amount = 0.0;

void fragment() {
	// The square texture covers the view, cropped rather than stretched.
	vec2 cover = view_size / max(view_size.x, view_size.y);
	vec2 tuv = vec2(0.5) + (UV - vec2(0.5)) * cover;
	float grey = mix(texture(texture_from, tuv).r, texture(texture_to, tuv).r, texture_mix);
	// Mid grey leaves the ground as it is; lighter lifts it, darker sinks it.
	vec3 base = ground.rgb * mix(1.0, grey * 2.0, texture_amount);
	float d = distance(UV * view_size, wash_centre);
	float glow = 1.0 - smoothstep(0.0, wash_radius, d);
	COLOR = vec4(mix(base, wash.rgb, wash_amount * glow), 1.0);
}
