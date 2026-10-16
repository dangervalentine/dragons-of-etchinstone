shader_type canvas_item;
// The Ether field of a Mage Card: its Ether as moving woodcut (feature 006, owner:
// "actual elements" rather than soft circles), carved in three flat tones of the
// Ether: flame tongues licking up, wave crests rolling across, a forked bolt
// cutting through, smoke curling. With motion = 0 the field holds still and keeps
// its character.

#include "res://ui/fx/shaders/ether_woodcut.gdshaderinc"

// 0 fire, 1 water, 2 lightning, 3 shadow.
uniform int ether = 1;
// The Ether's base hue, its deep shade (edges) and its lit shade (etching, sheen).
uniform vec4 tint : source_color = vec4(0.12, 0.37, 0.82, 1.0);
uniform vec4 deep : source_color = vec4(0.05, 0.17, 0.37, 1.0);
uniform vec4 lit : source_color = vec4(0.45, 0.62, 0.92, 1.0);
// Size of the field in design units, so the pattern keeps its scale.
uniform vec2 size = vec2(190.0, 200.0);
// 1 = moving, 0 = still (reduced motion, or the card is covered).
uniform float motion = 1.0;
// Per-card offset so no two cards catch the light at once.
uniform float phase = 0.0;
// 0..1: the field steps back while another part of the card is in focus.
uniform float focus_dim = 0.0;
// 0..1: the field brightens while the card's Ether is the thing in focus.
uniform float glow = 0.0;
// 0..1: greyed out, for a card that cannot be chosen.
uniform float dim = 0.0;

void fragment() {
	vec2 uv = UV;
	vec2 p = uv * size / 19.0;
	float px = 1.0 / 19.0;
	// Each card starts its flames and waves at its own point.
	float t = (TIME + phase * 7.0) * motion;
	int tone = ether_tone(ether, p, uv, t, px);
	vec3 ground = mix(deep.rgb, tint.rgb * 0.82, 0.3);
	vec3 cut = mix(deep.rgb, tint.rgb * 0.82, 0.62);
	vec3 high = mix(tint.rgb * 0.82, lit.rgb, 0.28);
	vec3 rgb = tone == 0 ? ground : (tone == 1 ? cut : high);
	rgb *= 1.0 - 0.25 * focus_dim;
	rgb *= 1.0 + 0.15 * glow;
	float grey = dot(rgb, vec3(0.299, 0.587, 0.114));
	rgb = mix(rgb, vec3(grey) * 0.7, dim);
	COLOR = vec4(rgb, COLOR.a);
}
