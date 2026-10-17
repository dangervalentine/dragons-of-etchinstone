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
// A creature cut into parts is drawn from up to six layers (layer0 at the bottom)
// in this one pass, each with the same idle motion so they move as one creature,
// and then its own turn about its pivot (in UV), carried by its parent's turn
// (parents, an index, or -1). moves: x the motion (0 still, 1 hinge: opens now and
// then and closes, 2 swing: back and forth, 3 rise: out to the angle and back to
// rest), y the angle in degrees, clockwise when
// positive, z the period, w the phase in periods. A layer's alpha is where it
// covers what is below it and its red is where it draws, so a part can cut a gap
// around itself; art all in white draws everywhere it covers. Everything is one
// flat tint, so the layers combine by alpha alone and the tint's alpha is applied
// once. With no layers, TEXTURE is the whole art.
uniform int layers = 0;
uniform sampler2D layer0 : filter_linear;
uniform sampler2D layer1 : filter_linear;
uniform sampler2D layer2 : filter_linear;
uniform sampler2D layer3 : filter_linear;
uniform sampler2D layer4 : filter_linear;
uniform sampler2D layer5 : filter_linear;
uniform vec2 pivots[6];
uniform int parents[6];
uniform vec4 moves[6];
// 1 where a layer is drawn together with the one before it, a part with the part
// it carries (a head and its jaw): neither cuts the other, and their gaps together
// cut only what is below them both.
uniform int joins[6];
// Soft bones bend the art in place, with nothing cut out: each turns the art
// near the line from its joint to its tip (bone_lines: joint xy, tip xy, in UV)
// about its joint, fully within half its reach of that line (bone_reach, in UV)
// and fading to nothing at its reach. bone_moves are as moves. Bones apply in
// order, so a bone listed after another rides on it (the head on the neck).
uniform int bones = 0;
uniform vec4 bone_lines[4];
uniform vec4 bone_moves[4];
uniform float bone_reach[4];

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

// Sampling coordinates turned by -r about p, which shows the art turned by r.
vec2 turn(vec2 uv, vec2 p, float r) {
	vec2 c = uv - p;
	return vec2(c.x * cos(r) + c.y * sin(r), c.y * cos(r) - c.x * sin(r)) + p;
}

// How far a part moving by m (as moves) is turned at time t, in radians.
float turned(vec4 m, float t) {
	if (m.x < 0.5) {
		return 0.0;
	}
	float p = fract(t / m.z + m.w);
	if (m.x < 1.5) {
		// Opens quickly, holds, closes, then rests for the second half of the cycle.
		return radians(m.y) * smoothstep(0.0, 0.12, p) * (1.0 - smoothstep(0.32, 0.5, p));
	}
	if (m.x < 2.5) {
		return radians(m.y) * sin(6.2831853 * p);
	}
	return radians(m.y) * (0.5 - 0.5 * cos(6.2831853 * p));
}

float angle(int i, float t) {
	return turned(moves[i], t);
}

// How far p is from the line a to b.
float line_distance(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	float k = clamp(dot(p - a, ab) / max(dot(ab, ab), 1e-6), 0.0, 1.0);
	return length(p - a - ab * k);
}

// The art under uv once every bone has turned.
vec2 bend(vec2 uv, float t, float a) {
	for (int i = 0; i < bones; i++) {
		vec4 l = bone_lines[i];
		float w = 1.0 - smoothstep(bone_reach[i] * 0.5, bone_reach[i], line_distance(uv, l.xy, l.zw));
		uv = mix(uv, turn(uv, l.xy, turned(bone_moves[i], t) * a), w);
	}
	return uv;
}

// Where layer i's art is under uv: its ancestors' turns undone first, then its own.
vec2 place(int i, vec2 uv, float t, float a) {
	int chain[4];
	int n = 0;
	int j = i;
	for (int k = 0; k < 4; k++) {
		if (j < 0) {
			break;
		}
		chain[k] = j;
		n++;
		j = parents[j];
	}
	for (int k = n - 1; k >= 0; k--) {
		uv = turn(uv, pivots[chain[k]], angle(chain[k], t) * a);
	}
	return uv;
}

vec4 layer(int i, vec2 uv) {
	if (i == 0) return texture(layer0, uv);
	if (i == 1) return texture(layer1, uv);
	if (i == 2) return texture(layer2, uv);
	if (i == 3) return texture(layer3, uv);
	if (i == 4) return texture(layer4, uv);
	return texture(layer5, uv);
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
	uv = bend(uv, t, a);
	float body = 0.0;
	if (layers == 0) {
		body = texture(TEXTURE, uv).a * inside(uv);
	}
	// The layers joined into the piece being drawn: what they cover and draw.
	float cover = 0.0;
	float draw = 0.0;
	for (int i = 0; i < layers; i++) {
		vec2 luv = place(i, uv, t, a);
		vec4 s = layer(i, luv) * inside(luv);
		if (joins[i] == 0) {
			body = body * (1.0 - cover) + draw;
			cover = 0.0;
			draw = 0.0;
		}
		cover = max(cover, s.a);
		draw = max(draw, s.a * s.r);
	}
	body = body * (1.0 - cover) + draw;
	float glow = mode == 7 ? 0.82 + 0.18 * a * sin(t * 1.1) : 1.0;
	COLOR = vec4(tint.rgb * glow, tint.a * body) * modulate;
}
