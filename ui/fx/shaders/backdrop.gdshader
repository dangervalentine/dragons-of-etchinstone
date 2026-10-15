shader_type canvas_item;
// The screen background: the base colour, a little lighter in the middle, darker
// toward the edges, and faintly tinted at top left by the Encounter's Ether.

uniform vec4 base : source_color = vec4(0.063, 0.055, 0.09, 1.0);
uniform vec4 glow : source_color = vec4(0.17, 0.15, 0.25, 1.0);
// The Encounter's Ether, in its deep shade; tint_amount 0 leaves it out.
uniform vec4 ether_tint : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float tint_amount = 0.0;

void fragment() {
	float d = length((UV - vec2(0.5, 0.42)) * vec2(1.0, 1.25));
	float v = 1.0 - smoothstep(0.0, 0.75, d);
	vec3 rgb = mix(base.rgb, glow.rgb, v * 0.55);
	float corner = 1.0 - smoothstep(0.0, 0.7, length((UV - vec2(0.15, 0.3)) * vec2(1.0, 1.4)));
	rgb = mix(rgb, ether_tint.rgb, corner * 0.12 * tint_amount);
	float edge = smoothstep(0.55, 1.05, length((UV - 0.5) * vec2(1.0, 1.3)) * 1.3);
	rgb *= 1.0 - 0.35 * edge;
	COLOR = vec4(rgb, 1.0);
}
