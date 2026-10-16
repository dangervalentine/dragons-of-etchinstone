// Card tilt: turns a flat card in fake 3D inside one canvas_item node.
// From "Card Tilt (Fake 3D Perspective for 2D Cards)" on godotshaders.com,
// https://godotshaders.com/shader/card-tilt-fake-3d-perspective-for-2d-cards/
// MIT license, from https://runningunattended.com/godot-card-tilt-shader
// Here it draws a Mage Card's own offscreen view (ui/widgets/card_view.gd), which
// feeds tilt_degrees from the pointer; the glare is kept faint for the muted board.
shader_type canvas_item;

uniform vec2 tilt_degrees = vec2(0.0); // x turns around the vertical axis, y tips forward/back
uniform float tilt_depth : hint_range(0.8, 10.0) = 2.5; // camera distance in card heights; lower = stronger perspective
uniform float tilt_margin : hint_range(0.0, 0.45) = 0.1; // empty border so the turned corners aren't clipped
uniform float glare : hint_range(0.0, 1.0) = 0.25; // soft highlight that slides across as the card turns

mat3 rotation(vec2 degrees) {
	vec2 a = radians(degrees);
	mat3 ry = mat3(vec3(cos(a.x), 0.0, -sin(a.x)), vec3(0.0, 1.0, 0.0), vec3(sin(a.x), 0.0, cos(a.x)));
	mat3 rx = mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, cos(a.y), sin(a.y)), vec3(0.0, -sin(a.y), cos(a.y)));
	return ry * rx;
}

void fragment() {
	// 1. This pixel, centered and corrected for the card's aspect ratio.
	float aspect = TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
	vec2 s = (UV - 0.5) / max(1.0 - 2.0 * tilt_margin, 0.05);
	s.x *= aspect;
	// 2. Cast a ray from a camera in front of the card through this pixel...
	mat3 r = rotation(tilt_degrees);
	vec3 n = r * vec3(0.0, 0.0, 1.0);
	vec3 cam = vec3(0.0, 0.0, -tilt_depth);
	vec3 dir = vec3(s, tilt_depth);
	float dn = dot(dir, n);
	float t = -dot(cam, n) / (abs(dn) < 1e-5 ? 1e-5 : dn);
	// 3. ...and find where it hits the turned card, in the card's own coordinates.
	vec3 hit = transpose(r) * (cam + t * dir);
	vec2 uv = vec2(hit.x / aspect, hit.y) + 0.5;
	// The card fills the middle of the view; map back into the whole texture.
	vec2 tex_uv = uv * (1.0 - 2.0 * tilt_margin) + tilt_margin;
	bool inside = t > 0.0 && uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0;
	vec4 c = texture(TEXTURE, tex_uv) * COLOR;
	c.a *= inside ? 1.0 : 0.0;
	// 4. A soft glare on the side facing the "light", stronger the further it turns.
	vec2 l = tilt_degrees / 30.0;
	if (dot(l, l) > 1e-4) {
		c.rgb += glare * smoothstep(0.75, 0.0, length(uv - (0.5 - l * 0.6))) * min(length(l), 1.0) * c.a;
	}
	COLOR = c;
}
