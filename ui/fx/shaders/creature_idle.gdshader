shader_type canvas_item;
// Idle motion for a flat silhouette. The whole shape moves, bent or warped where
// that reads as life: breathing, hovering, swaying from the root, a wave running
// through the body, heat shimmer, flowing water, or a slow glow for still places.

// 0 still, 1 breathe, 2 hover, 3 sway, 4 wave, 5 shimmer, 6 flow, 7 glow
uniform int mode = 0;
// 0 stops all motion (reduced motion); 1 is the normal amount.
uniform float amount = 1.0;
uniform float speed = 1.0;
// Offsets the cycle so two creatures never move in step.
uniform float phase = 0.0;
uniform vec4 tint : source_color = vec4(1.0);
// A creature's moving part (a jaw) is a second texture drawn in the same pass,
// with the same idle motion so it moves as one with the body, and then its hinge
// on top: it turns about the pivot (in UV) by up to hinge_angle degrees,
// clockwise when positive, now and then, and back. Body and part are one flat
// tint, so they combine by alpha alone and the tint's alpha is applied once.
uniform bool has_part = false;
uniform sampler2D part_tex : filter_linear;
uniform vec2 pivot = vec2(0.5);
uniform float hinge_angle = 0.0;
uniform float part_period = 4.0;

// The node's modulate, its parents' included (a screen fading in or out). It
// arrives in the vertex colour, which writing COLOR would otherwise throw away.
varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

// 1 inside the art, 0 beyond its edge, where nothing is drawn.
float inside(vec2 uv) {
	return (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) ? 0.0 : 1.0;
}

void fragment() {
	float t = TIME * speed + phase;
	float a = amount;
	vec2 uv = UV;
	if (mode == 1) {
		// Breathe: rise and fall about the feet, more in height than width.
		float s = 1.0 + 0.03 * a * sin(t * 1.5);
		vec2 feet = vec2(0.5, 0.95);
		uv = (uv - feet) / vec2(1.0 + (s - 1.0) * 0.45, s) + feet;
	} else if (mode == 2) {
		// Hover: drift up and down with a slight tilt.
		uv.y += 0.035 * a * sin(t * 1.3);
		float r = 0.045 * a * sin(t * 0.85);
		vec2 c = uv - vec2(0.5);
		uv = vec2(c.x * cos(r) - c.y * sin(r), c.x * sin(r) + c.y * cos(r)) + vec2(0.5);
	} else if (mode == 3) {
		// Sway: rooted at the bottom, the top moves most.
		float h = pow(clamp(1.0 - uv.y, 0.0, 1.0), 2.0);
		uv.x += 0.07 * a * h * sin(t * 1.05);
		uv.y += 0.01 * a * h * sin(t * 2.1);
	} else if (mode == 4) {
		// Wave: a ripple running down the body.
		uv.x += 0.03 * a * sin(uv.y * 8.0 - t * 2.2);
		uv.y += 0.012 * a * sin(uv.x * 6.0 - t * 1.6);
	} else if (mode == 5) {
		// Shimmer: rising heat, stronger toward the top.
		float h = clamp(1.0 - uv.y, 0.0, 1.0);
		uv.x += 0.01 * a * h * sin(uv.y * 38.0 - t * 5.0);
	} else if (mode == 6) {
		// Flow: running water, stronger toward the bottom.
		float l = clamp(uv.y, 0.0, 1.0);
		uv.x += 0.012 * a * l * sin(uv.y * 30.0 + t * 4.0);
	}
	float body = texture(TEXTURE, uv).a * inside(uv);
	if (has_part) {
		// Opens quickly, holds, closes, then rests for the second half of the cycle.
		float p = fract(t / part_period);
		float open = smoothstep(0.0, 0.12, p) * (1.0 - smoothstep(0.32, 0.5, p));
		float r = -radians(hinge_angle) * open * a;
		vec2 c = uv - pivot;
		vec2 puv = vec2(c.x * cos(r) - c.y * sin(r), c.x * sin(r) + c.y * cos(r)) + pivot;
		float part = texture(part_tex, puv).a * inside(puv);
		body = body + part * (1.0 - body);
	}
	float glow = mode == 7 ? 0.82 + 0.18 * a * sin(t * 1.1) : 1.0;
	COLOR = vec4(tint.rgb * glow, tint.a * body) * modulate;
}
