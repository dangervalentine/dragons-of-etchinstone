shader_type canvas_item;
// The field behind an Encounter's or dragon's art: its Ether as moving woodcut
// (ether_woodcut.gdshaderinc) in three flat, quiet tones of the Ether colour, so the
// creature or scene in front still reads. Single pass, no textures.

#include "res://ui/fx/shaders/ether_woodcut.gdshaderinc"

uniform vec4 tint : source_color = vec4(0.29, 0.61, 0.94, 1.0);
// 0 fire, 1 water, 2 lightning, 3 shadow; -1 for no Ether (a plain field).
uniform int ether = -1;
// Size of the rectangle in design units, so the pattern keeps its scale.
uniform vec2 size = vec2(190.0, 190.0);
// 1 = moving, 0 = still (reduced motion).
uniform float motion = 1.0;
// 0 = full colour, 1 = greyed out.
uniform float dim : hint_range(0.0, 1.0) = 0.0;
// Kept for callers that set it; the woodcut has no centre.
uniform vec2 centre = vec2(0.62, 0.5);

void fragment() {
	vec2 p = UV * size / 20.0;
	float px = 1.0 / 20.0;
	int tone = ether < 0 ? 0 : ether_tone(ether, p, UV, TIME * motion, px);
	float k = tone == 0 ? 0.30 : (tone == 1 ? 0.40 : 0.52);
	vec3 rgb = tint.rgb * k;
	float grey = dot(rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(rgb, vec3(grey), dim), COLOR.a);
}
