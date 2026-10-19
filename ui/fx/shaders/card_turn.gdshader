shader_type canvas_item;
// A card turning over about its upright axis, seen in perspective: the card, drawn
// into a texture, is laid on a plane turned `angle` radians, so the edge coming
// toward the viewer grows taller and the far edge shrinks. Negative angles bring
// the right edge forward, positive the left. Darker as it stands on edge.

uniform float angle = 0.0;
// How far the eye is from the card, in card widths.
uniform float distance = 2.2;
uniform vec2 card_size = vec2(200.0, 280.0);
// This rect and the texture's, from the card's top left, in the card's own units.
uniform vec2 rect_origin;
uniform vec2 rect_size = vec2(1.0);
uniform vec2 tex_origin;
uniform vec2 tex_size = vec2(1.0);
uniform float shade = 0.4;

void fragment() {
	vec2 local = rect_origin + UV * rect_size;
	vec2 p = (local - card_size * 0.5) / card_size.x;
	float s = sin(angle);
	float c = cos(angle);
	float denom = distance * c - p.x * s;
	if (denom <= 0.0001) {
		COLOR = vec4(0.0);
	} else {
		float u = p.x * distance / denom;
		float v = p.y * (distance + u * s) / distance;
		vec2 q = card_size * 0.5 + vec2(u, v) * card_size.x;
		vec2 uv = (q - tex_origin) / tex_size;
		if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
			COLOR = vec4(0.0);
		} else {
			vec4 col = texture(TEXTURE, uv);
			col.rgb *= 1.0 - shade * abs(s);
			COLOR = col;
		}
	}
}
