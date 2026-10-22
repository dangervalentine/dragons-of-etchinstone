shader_type canvas_item;
// Idle motion for a painted picture, or a silhouette drawn in one flat tint. The
// whole shape moves, bent or warped where that reads as life: breathing, swaying
// from the root, or a slow glow for still places.

// 0 still, 1 breathe, 2 sway, 3 glow
uniform int mode = 0;
// 0 stops all motion (reduced motion); 1 is the normal amount.
uniform float amount = 1.0;
uniform float speed = 1.0;
// Offsets the cycle so two creatures never move in step.
uniform float phase = 0.0;
uniform vec4 tint : source_color = vec4(1.0);
// A painted picture (art/painted/), drawn in its own colours, not tinted.
uniform bool painted = false;
// The share of the picture on each side that is room around the art, for parts
// that move past the art's edge.
uniform float pad = 0.0;
// An ink line round a painted figure, so it stands off its panel (T.CREATURE_LINE):
// none while its alpha is 0. Its width is a share of the art's side, but never less
// than line_min pixels on screen.
uniform vec4 line_color : source_color = vec4(0.0);
uniform float line_width = 0.0;
uniform float line_min = 1.5;
// Soft bones bend the art in place, with nothing cut out: each turns the art
// near the line from its joint to its tip (bone_lines: joint xy, tip xy, in UV)
// about its joint, fully within three quarters of its reach of that line (bone_reach, in UV)
// and fading to nothing at its reach. bone_moves: x the motion (0 still, 1 swing:
// back and forth, 2 rise: out to the angle and back to rest), y the angle in
// degrees, clockwise when positive, z the period, w the phase in periods. A bone
// carries the bones after it up to bone_last (a chain, such as a tail): it moves
// the art near any of them too. Bones apply in order, so a bone listed after
// another rides on it (the head on the neck, the tip of a tail on its root).
uniform int bones = 0;
uniform vec4 bone_lines[8];
uniform vec4 bone_moves[8];
uniform float bone_reach[8];
uniform int bone_last[8];

// A frame the art is cut to, in the picture's own units (x, y, width, height), and
// how far its top-right and bottom-right corners are cut away: a Region Card
// panel's bevelled frame. Done here rather than by a clipping parent, as clipping
// children does not nest inside the Deck's own.
uniform bool cut = false;
uniform vec4 cut_box = vec4(0.0);
uniform vec2 cut_corners = vec2(0.0);

// The node's modulate, its parents' included (a screen fading in or out). It
// arrives in the vertex colour, which writing COLOR would otherwise throw away.
varying vec4 modulate;
// Where the fragment is in the picture's own units, for the cut.
varying vec2 local;

void vertex() {
	modulate = COLOR;
	local = VERTEX;
}

// 1 inside the cut frame, 0 outside it.
float within_cut(vec2 p) {
	if (!cut) {
		return 1.0;
	}
	vec2 lo = cut_box.xy;
	vec2 hi = cut_box.xy + cut_box.zw;
	if (p.x < lo.x || p.y < lo.y || p.x > hi.x || p.y > hi.y) {
		return 0.0;
	}
	if ((hi.x - p.x) + (p.y - lo.y) < cut_corners.x || (hi.x - p.x) + (hi.y - p.y) < cut_corners.y) {
		return 0.0;
	}
	return 1.0;
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

// How far a bone moving by m (as bone_moves) is turned at time t, in radians.
float turned(vec4 m, float t) {
	if (m.x < 0.5) {
		return 0.0;
	}
	float p = fract(t / m.z + m.w);
	if (m.x < 1.5) {
		return radians(m.y) * sin(6.2831853 * p);
	}
	return radians(m.y) * (0.5 - 0.5 * cos(6.2831853 * p));
}

// How far p is from the line a to b.
float line_distance(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	float k = clamp(dot(p - a, ab) / max(dot(ab, ab), 1e-6), 0.0, 1.0);
	return length(p - a - ab * k);
}

// How far bone i moves the art that rests at p.
vec2 moved(int i, vec2 p, float t, float a) {
	// How much of it moves with the bone: near it, or near a bone it carries.
	float w = 0.0;
	for (int j = i; j <= bone_last[i]; j++) {
		vec4 c = bone_lines[j];
		w = max(w, 1.0 - smoothstep(bone_reach[j] * 0.75, bone_reach[j], line_distance(p, c.xy, c.zw)));
	}
	vec4 l = bone_lines[i];
	return (turn(p, l.xy, -turned(bone_moves[i], t) * a) - p) * w;
}

// The art under uv once every bone has moved: for each, the resting point that
// its move carries to uv, found by refining a guess, so a part that moves far
// out of where it rests (the tip of a tail) is still found whole.
vec2 bend(vec2 uv, float t, float a) {
	for (int i = 0; i < bones; i++) {
		vec2 p = uv;
		for (int k = 0; k < 4; k++) {
			p = uv - moved(i, p, t, a);
		}
		uv = p;
	}
	return uv;
}

void fragment() {
	float t = TIME * speed + phase;
	float a = amount;
	vec2 uv = (UV - pad) / (1.0 - 2.0 * pad);
	if (mode == 1) {
		// Breathe: the body swells and settles about the feet, a little in height and
		// nearly as much in width, as a chest fills; a breath barely changes how tall
		// a creature stands.
		float s = 1.0 + 0.008 * a * sin(t * 1.5);
		vec2 feet = vec2(0.5, 0.95);
		uv = (uv - feet) / vec2(1.0 + (s - 1.0) * 0.75, s) + feet;
	} else if (mode == 2) {
		// Sway: rooted at the bottom, the top moves most.
		float h = pow(clamp(1.0 - uv.y, 0.0, 1.0), 2.0);
		uv.x += 0.07 * a * h * sin(t * 1.05);
		uv.y += 0.01 * a * h * sin(t * 2.1);
	}
	uv = bend(uv, t, a);
	float glow = mode == 3 ? 0.82 + 0.18 * a * sin(t * 1.1) : 1.0;
	float kept = within_cut(local);
	if (painted) {
		vec4 c = texture(TEXTURE, uv) * inside(uv);
		if (line_color.a > 0.0) {
			// The line: wherever the figure lies within its width, in two rings so a
			// thin part (a staff, a horn) is not stepped over.
			vec2 w = max(vec2(line_width), fwidth(uv) * line_min);
			float near = 0.0;
			for (int k = 0; k < 16; k++) {
				float r = 6.2831853 * (float(k) + (k < 8 ? 0.0 : 0.5)) / 8.0;
				vec2 o = uv + vec2(cos(r), sin(r)) * w * (k < 8 ? 1.0 : 0.5);
				near = max(near, texture(TEXTURE, o).a * inside(o));
			}
			float l = near * line_color.a * (1.0 - c.a);
			float both = c.a + l;
			c = vec4((c.rgb * c.a + line_color.rgb * l) / max(both, 1e-4), both);
		}
		COLOR = vec4(c.rgb * glow, c.a * kept) * modulate;
	} else {
		COLOR = vec4(tint.rgb * glow, tint.a * texture(TEXTURE, uv).a * inside(uv) * kept) * modulate;
	}
}
