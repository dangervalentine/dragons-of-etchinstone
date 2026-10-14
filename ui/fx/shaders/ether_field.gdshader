shader_type canvas_item;
// The patterned field of a card or Encounter face: a slow swirl in the Ether
// colour, darker toward the edges. Single pass, no textures.

uniform vec4 tint : source_color = vec4(0.29, 0.61, 0.94, 1.0);
// Size of the rectangle in design units, so the pattern keeps its scale.
uniform vec2 size = vec2(190.0, 190.0);
// 0 = full colour, 1 = greyed out (a card that cannot be chosen).
uniform float dim : hint_range(0.0, 1.0) = 0.0;
// Where the swirl is centred, as a fraction of the rectangle.
uniform vec2 centre = vec2(0.62, 0.5);

void fragment() {
	vec2 p = UV * size;
	vec2 c = size * centre;
	float d = length(p - c);
	float a = atan(p.y - c.y, p.x - c.x);
	float swirl = sin(d * 0.2 - a * 3.0) * 0.5 + 0.5;
	float bands = smoothstep(0.3, 0.7, swirl);
	float vignette = 1.0 - smoothstep(0.15, 0.9, length(UV - vec2(0.5)) * 1.3);
	vec3 rgb = tint.rgb * (0.30 + 0.24 * vignette);
	rgb += tint.rgb * 0.09 * bands * (0.4 + 0.6 * vignette);
	float grey = dot(rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(rgb, vec3(grey), dim), COLOR.a);
}
