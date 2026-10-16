// The four Ethers as moving woodcut: carved shapes in three flat tones, no glow and
// no soft gradients (owner, feature 006: "actual elements" in the game's flat style).
//   Fire: tongues of flame lick upward from the base, layered like carved flame.
//   Water: rows of wave crests roll across, each a carved curl.
//   Lightning: jagged strokes, with a forked bolt cutting through now and then.
//   Shadow: curls of smoke drift up and coil.
// ether_tone() returns 0 (the ground), 1 (the cut) or 2 (the highlight) for a point;
// callers map those to their own colours. With t held (reduced motion) every Ether
// keeps its shape, still.

float wc_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float wc_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(wc_hash(i), wc_hash(i + vec2(1.0, 0.0)), u.x),
		mix(wc_hash(i + vec2(0.0, 1.0)), wc_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float wc_fbm(vec2 p) {
	return wc_noise(p) * 0.6 + wc_noise(p * 2.07 + 5.3) * 0.28 + wc_noise(p * 4.1 + 11.7) * 0.12;
}

// A carved band: 1 inside a stroke of `width` (in pixels of `px` per unit), with a
// sharp but anti-aliased edge.
float wc_cut(float d, float width, float px) {
	return 1.0 - smoothstep(width - px, width + px, abs(d));
}

// Distance from p to the segment a-b.
float wc_seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

// p: the point in units of about 20 design units; uv: 0..1 over the field;
// t: seconds (0 to hold still). Returns 0, 1 or 2.
int ether_tone(int ether, vec2 p, vec2 uv, float t, float px) {
	if (ether == 0) {
		// Fire. Each tongue is a triangle wave raised to a power under 1: full, rounded
		// sides, a sharp tip and a narrow gap between tongues. Its height swells and
		// drops with noise that climbs, and the row sways, so the flames lick.
		float rise = t * 0.9;
		float bend = (wc_fbm(vec2(p.x * 0.3, rise * 0.4)) - 0.5) * 2.0;
		float tip1 = pow(1.0 - abs(fract(p.x * 0.24 + bend * 0.3) - 0.5) * 2.0, 0.55);
		float lick1 = 0.55 + 0.45 * wc_fbm(vec2(floor(p.x * 0.24 + bend * 0.3) * 3.7, rise * 0.7));
		float h1 = 0.18 + 0.62 * tip1 * lick1;
		// The inner flame: its own narrower, quicker tongues, always inside the outer.
		float tip2 = pow(1.0 - abs(fract(p.x * 0.41 + bend * 0.45 + 0.35) - 0.5) * 2.0, 0.6);
		float lick2 = 0.5 + 0.5 * wc_fbm(vec2(floor(p.x * 0.41 + bend * 0.45 + 0.35) * 5.1, rise * 1.1 + 4.0));
		float h2 = min(0.08 + 0.48 * tip2 * lick2, h1 - 0.06);
		float y = 1.0 - uv.y;
		// A thin carved line along the inner flame's edge, as on a woodcut flame.
		if (abs(y - h2) < 0.012) {
			return 0;
		}
		if (y < h2) {
			return 2;
		}
		if (y < h1) {
			return 1;
		}
		// Sparks of flame breaking off above the tongues.
		vec2 cell = floor(vec2(p.x * 0.8, p.y * 0.8 - rise * 1.4));
		vec2 f = fract(vec2(p.x * 0.8, p.y * 0.8 - rise * 1.4)) - 0.5;
		float spark = step(0.86, wc_hash(cell)) * step(length(f * vec2(1.6, 0.8)), 0.22);
		return spark > 0.5 && y < h1 + 0.3 ? 1 : 0;
	} else if (ether == 1) {
		// Water. Rows of crests; each row's line rolls over into a curl.
		float row = p.y * 0.55;
		float k = floor(row);
		float x = p.x * 0.5 - t * (0.35 + 0.15 * wc_hash(vec2(k, 2.0))) + k * 1.7;
		float crest = sin(x * 2.4) * 0.22 + (wc_noise(vec2(x * 0.8, k)) - 0.5) * 0.3;
		float d = fract(row) - 0.5 - crest;
		float line = wc_cut(d, 0.07, px * 0.5);
		// The curl: a hooked stroke at each crest top.
		float top = fract(x * 2.4 / 6.2832 + 0.25);
		float curl = wc_cut(length(vec2(top - 0.5, d + 0.12) * vec2(3.0, 1.6)) - 0.22, 0.05, px * 0.6) * step(0.0, -d);
		if (line > 0.5) {
			return 2;
		}
		if (curl > 0.5 || d < -0.18) {
			return 1;
		}
		return 0;
	} else if (ether == 2) {
		// Lightning. Broken, jagged strokes in the ground, and a forked bolt carved
		// through the field that strikes bright for a moment every couple of seconds
		// (well under one flash a second).
		float col = floor(p.x * 0.5);
		float amp = 0.25 + 0.5 * wc_hash(vec2(col, 7.0));
		float zig = abs(fract(p.x * 0.5 + wc_fbm(vec2(p.x * 0.3, p.y * 0.2)) * 0.6) - 0.5) * amp;
		float jag = wc_cut(fract(p.y * 0.22 + zig + wc_hash(vec2(col, 3.0)) * 0.5) - 0.5, 0.05, px * 0.4);
		jag *= step(0.35, wc_noise(vec2(p.x * 0.4, p.y * 0.15)));
		float cycle = 2.0;
		float slot = floor(t / cycle);
		float lit = t > 0.0 ? step(fract(t / cycle), 0.18) : 1.0;
		// The bolt keeps its path through a strike and the dark spell after it.
		float seed = t > 0.0 ? slot : 3.0;
		vec2 a = vec2(0.3 + 0.4 * wc_hash(vec2(seed, 1.0)), -0.02);
		float bolt = 1e3;
		vec2 fork = a;
		for (int i = 1; i <= 8; i++) {
			vec2 b = vec2(a.x + (wc_hash(vec2(seed, float(i))) - 0.5) * 0.24, float(i) / 8.0);
			bolt = min(bolt, wc_seg(uv, a, b));
			if (i == 3) {
				fork = b;
			}
			a = b;
		}
		vec2 f = fork;
		float side = wc_hash(vec2(seed, 30.0)) > 0.5 ? 1.0 : -1.0;
		for (int j = 1; j <= 3; j++) {
			vec2 g = f + vec2(side * (0.06 + 0.05 * wc_hash(vec2(seed, 20.0 + float(j)))), 0.09);
			bolt = min(bolt, wc_seg(uv, f, g) * 1.3);
			f = g;
		}
		float w = 0.011;
		if (bolt < w) {
			return lit > 0.5 ? 2 : 1;
		}
		if (lit > 0.5 && bolt < w * 2.6) {
			return 1;
		}
		return jag > 0.5 ? 1 : 0;
	}
	// Shadow. Smoke: plumes rising in tall, warped columns, cut into a few iso-lines
	// that curl as they climb.
	vec2 q = vec2(p.x * 0.55, p.y * 0.22 + t * 0.18);
	vec2 warp = vec2(wc_fbm(q * 1.3 + vec2(0.0, t * 0.05)) - 0.5, 0.0);
	float plume = wc_fbm(vec2(q.x + warp.x * 1.8 * (1.2 - uv.y), q.y));
	float v = plume + (1.0 - uv.y) * 0.25;
	float bands = fract(v * 4.0);
	if (bands < 0.1) {
		return 2;
	}
	return v > 0.62 ? 1 : 0;
}
