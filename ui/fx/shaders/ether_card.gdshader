shader_type canvas_item;
// The Ether field of a Mage Card, finished like a premium foil trading card: a rich
// Ether gradient etched with a fine labyrinth of lines, as on the printed cards,
// with a holographic sheen that drifts slowly across and catches the etching.
//
// Each Ether is told apart by its etching, which holds almost still: Fire's strands
// rise from a glowing base into tongues of flame, Water's run in long waves, Lightning's break into sharp zig-zags
// with a bolt etched through them, Shadow's coil round the centre under faint
// four-point stars. Motion is faint and slow. With motion = 0 the field is a still
// card that keeps its character.

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

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	return noise(p) * 0.65 + noise(p * 2.03 + 7.1) * 0.35;
}

// 1 on an etched line, 0 between: iso-lines of a field.
float etch(float v, float density) {
	float d = abs(fract(v * density) - 0.5);
	return 1.0 - smoothstep(0.06, 0.16, d);
}

// A soft rainbow, for the holographic foil.
vec3 iridescent(float x) {
	return 0.5 + 0.5 * cos(6.2832 * (x + vec3(0.0, 0.33, 0.67)));
}

void fragment() {
	vec2 uv = UV;
	vec2 q = uv * size / 19.0;
	// Slow time: the etching barely drifts; the sheen takes half a minute to cross.
	float t = TIME * motion;
	float slow = t * 0.015;

	float centre = 1.0 - smoothstep(0.05, 0.9, length((uv - vec2(0.62, 0.48)) * vec2(1.0, 0.8)) * 1.2);
	vec3 rgb = mix(deep.rgb, tint.rgb * 0.82, 0.25 + 0.55 * centre);

	// The etching, shaped by the Ether.
	float line = 0.0;
	if (ether == 0) {
		// Fire: strands rise from a hot base and curl as they climb, gathering into
		// tongues of flame toward the top; the base glows warm.
		float rise = 1.0 - uv.y;
		float sway = (fbm(vec2(q.x * 0.55, q.y * 0.32 + slow)) - 0.5) * (0.4 + 1.8 * rise);
		float lick = sin(q.y * 0.9 - slow * 6.0 + q.x * 0.3) * 0.18 * rise;
		line = etch(q.x * 0.3 + sway + lick, 3.0) * smoothstep(0.02, 0.25, uv.y);
		float tongues = uv.y - (0.32 + 0.22 * abs(sin(uv.x * 7.0 + fbm(q * 0.3) * 2.0)));
		// Layered outlines of the tongues, as in carved flame ornament.
		line = max(line * 0.75, etch(tongues + fbm(q * 0.5 + vec2(0.0, slow)) * 0.06, 7.0) * smoothstep(0.75, 0.35, uv.y));
		rgb = mix(rgb, mix(rgb, tint.rgb, 0.35), smoothstep(-0.05, 0.25, tongues));
		rgb += tint.rgb * smoothstep(0.6, 1.0, uv.y) * 0.22;
	} else if (ether == 1) {
		// Water: long, even waves running across.
		vec2 p = vec2(q.x * 0.5 + slow, q.y);
		line = etch(fbm(p) * 0.6 + q.y * 0.18 + sin(q.x * 0.7 + slow * 3.0) * 0.12, 5.0);
	} else if (ether == 2) {
		// Lightning: sharp, broken zig-zags, and a bolt etched through the field.
		float zig = abs(fract(q.x * 0.45 + fbm(q * 0.4) * 0.3) - 0.5) * 1.6;
		line = etch(q.y * 0.3 + zig + fbm(q * 0.5 + vec2(slow, 0.0)) * 0.15, 3.0);
		float bx = 0.58 + (abs(fract(uv.y * 2.4 + 0.2) - 0.5) - 0.25) * 0.28;
		float bolt = 1.0 - smoothstep(0.0, 3.5, abs(uv.x - bx) * size.x);
		line = max(line * 0.8, bolt * step(0.06, uv.y) * step(uv.y, 0.94));
	} else {
		// Shadow: lines coil round the centre under faint stars.
		vec2 c = vec2(0.6, 0.48);
		vec2 d = (uv - c) * size / 19.0;
		float r = length(d);
		float a = atan(d.y, d.x);
		line = etch(r * 0.35 + a * 0.32 + fbm(q * 0.6) * 0.35 - slow * 0.5, 4.0);
		vec2 s = q * 0.9;
		vec2 cell = floor(s);
		vec2 o = (fract(s) - (0.3 + 0.4 * vec2(hash(cell + 4.1), hash(cell + 6.7)))) * 10.0;
		float star = clamp(0.05 / (abs(o.x * o.y) + 0.02) - 0.2, 0.0, 1.0) * smoothstep(1.2, 0.1, length(o));
		line = max(line, star * step(0.75, hash(cell + 2.3)));
	}
	rgb += lit.rgb * line * 0.14;

	// The holographic sheen: a broad, faint band of shifting colour drifting
	// diagonally across, strongest where it catches the etching.
	float along = dot(uv, normalize(vec2(1.0, 0.65)));
	float sweep = fract(t * 0.035 + phase * 0.37);
	float band = exp(-pow((along - (sweep * 2.2 - 0.6)) * 2.4, 2.0));
	// Held still, the light rests across the upper left, as on a card tilted to the lamp.
	band = mix(exp(-pow((along - 0.35) * 2.4, 2.0)), band, step(0.5, motion));
	vec3 foil = mix(iridescent(along * 1.3 + uv.y * 0.4 + phase * 0.1), lit.rgb, 0.45);
	rgb += foil * band * (0.012 + 0.04 * line);

	// Foil glints: a few points that brighten and fade, slowly.
	vec2 g = q * 0.7;
	vec2 gc = floor(g);
	float gh = hash(gc + phase);
	float gd = length(fract(g) - (0.25 + 0.5 * vec2(hash(gc + 1.3), hash(gc + 8.1))));
	float twinkle = 0.5 + 0.5 * sin(t * 0.25 + gh * 40.0);
	rgb += vec3(1.0) * smoothstep(0.06, 0.0, gd) * step(0.88, gh) * twinkle * 0.05;

	float vignette = 1.0 - smoothstep(0.35, 1.0, length((uv - 0.5) * vec2(1.1, 0.9)) * 1.35);
	rgb *= 0.66 + 0.34 * vignette;
	rgb *= 1.0 - 0.25 * focus_dim;
	rgb *= 1.0 + 0.15 * glow;
	float grey = dot(rgb, vec3(0.299, 0.587, 0.114));
	rgb = mix(rgb, vec3(grey) * 0.7, dim);
	COLOR = vec4(rgb, COLOR.a);
}
