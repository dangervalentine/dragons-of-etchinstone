shader_type canvas_item;
// The screen background: the base colour, a little lighter in the middle.

uniform vec4 base : source_color = vec4(0.063, 0.055, 0.09, 1.0);
uniform vec4 glow : source_color = vec4(0.17, 0.15, 0.25, 1.0);

void fragment() {
	float d = length((UV - vec2(0.5, 0.42)) * vec2(1.0, 1.25));
	float v = 1.0 - smoothstep(0.0, 0.75, d);
	COLOR = vec4(mix(base.rgb, glow.rgb, v * 0.55), 1.0);
}
