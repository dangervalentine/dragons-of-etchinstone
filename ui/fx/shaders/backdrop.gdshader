shader_type canvas_item;
// The table every screen stands on (specs/019 contracts/materials-and-ground.md): the
// flat ground, and in play a large soft glow in the current Region's own tint behind
// the Encounter or Region Card, so each Region feels like its painting. In play the
// ground itself is the Region's own (T.REGION_GROUND), set by backdrop_layer.gd. It
// replaces the patterned stone of feature 006.

uniform vec4 ground : source_color = vec4(0.055, 0.082, 0.09, 1.0);
uniform vec4 wash : source_color = vec4(0.0, 0.0, 0.0, 1.0);
// 0 (no wash) to REGION_WASH.
uniform float wash_amount = 0.0;
// The glow's centre and reach, in the view's pixels.
uniform vec2 wash_centre = vec2(320.0, 360.0);
uniform float wash_radius = 432.0;
uniform vec2 view_size = vec2(1280.0, 720.0);

void fragment() {
	float d = distance(UV * view_size, wash_centre);
	float glow = 1.0 - smoothstep(0.0, wash_radius, d);
	COLOR = vec4(mix(ground.rgb, wash.rgb, wash_amount * glow), 1.0);
}
