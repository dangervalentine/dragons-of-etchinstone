shader_type canvas_item;
// The screen background. With stone_amount 0 it is the old flat background: the
// base colour, a little lighter in the middle, darker toward the edges, faintly
// tinted at top left by the Encounter's Ether. With stone_amount 1 it is a plain
// stone grain, still and flat, for the raised zones to stand on.

uniform vec4 base : source_color = vec4(0.063, 0.055, 0.09, 1.0);
uniform vec4 glow : source_color = vec4(0.17, 0.15, 0.25, 1.0);
// The Encounter's Ether, in its deep shade; tint_amount 0 leaves it out.
uniform vec4 ether_tint : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float tint_amount = 0.0;

uniform float stone_amount = 0.0;
uniform sampler2D grain : repeat_enable, filter_linear;
uniform vec2 view_size = vec2(1280.0, 720.0);

void fragment() {
	float d = length((UV - vec2(0.5, 0.42)) * vec2(1.0, 1.25));
	float v = 1.0 - smoothstep(0.0, 0.75, d);
	vec3 flat_rgb = mix(base.rgb, glow.rgb, v * 0.55);
	float corner = 1.0 - smoothstep(0.0, 0.7, length((UV - vec2(0.15, 0.3)) * vec2(1.0, 1.4)));
	flat_rgb = mix(flat_rgb, ether_tint.rgb, corner * 0.12 * tint_amount);
	float edge = smoothstep(0.55, 1.05, length((UV - 0.5) * vec2(1.0, 1.3)) * 1.3);
	flat_rgb *= 1.0 - 0.35 * edge;
	if (stone_amount <= 0.0) {
		COLOR = vec4(flat_rgb, 1.0);
	} else {
		vec3 stone = texture(grain, UV * view_size / 256.0).rgb * (1.0 - 0.4 * edge);
		COLOR = vec4(mix(flat_rgb, stone, stone_amount), 1.0);
	}
}
