// The four Ethers as moving woodcut: carved shapes in three flat tones, no glow and
// no soft gradients (owner, feature 006: "actual elements" in the game's flat style).
//   Fire: tongues of flame lick upward from the base, layered like carved flame.
//   Water: toon water, flat bands of waves with foam on their peaks.
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

// Distance to the nearest edge between Voronoi cells (ice plates), in cell units.
float wc_crack(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(wc_hash(i + g), wc_hash(i + g + 17.3));
			float d = length(g + o - f);
			if (d < d1) {
				d2 = d1;
				d1 = d;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return d2 - d1;
}

// The field's width over its height is not known here; the bolt's slope is measured
// in uv, which is close enough for fields near square.
float size_ratio() {
	return 1.0;
}


// A triangle wave, -1..1.
float wc_tri(float x) {
	return abs(fract(x) - 0.5) * 4.0 - 1.0;
}

// p: the point in units of about 20 design units; uv: 0..1 over the field;
// t: seconds (0 to hold still). Returns 0, 1 or 2.
// Techniques borrowed from godotshaders.com (all CC0/MIT): Fire from "2D fire"
// (rising noise against a fire-shaped gradient at hard thresholds), Lightning from
// "Random 2D Lightning Strikes" (hashed strike positions, a bent and tapered bolt;
// slowed here and without its glow), Shadow from "Smoke or fog" (nested, warped
// fbm), and Water from "Stylized Toon Water" (low-octave noise waves cut into
// flat bands, foam on the peaks).
int ether_tone(int ether, vec2 p, vec2 uv, float t, float px) {
	float h = 1.0 - uv.y;
	if (ether == 0) {
		// Fire. Noise rising through the field, read against a gradient that is hot
		// at the base and cools upward and toward the sides; two hard thresholds cut
		// it into the flame and its bright core.
		// Stretched tall, so the shapes rise as streaks and tongues, not blobs.
		float n = wc_fbm(vec2(p.x * 0.9, p.y * 0.22 + t * 0.9));
		float n2 = wc_noise(vec2(p.x * 1.8 + 4.0, p.y * 0.5 + t * 1.6));
		n = n * 0.7 + n2 * 0.3;
		// Hot at the base, cooling upward; the tongues' tips flicker with the noise.
		float g = 1.1 - h * 1.25;
		if (n < g - 0.34) {
			return 2;
		}
		if (n < g) {
			return 1;
		}
		return 0;
	} else if (ether == 1) {
		// Water, as "Stylized Toon Water": a low-octave wave field, two layers moving
		// against each other plus a swell, cut into flat bands: deep water, the lit
		// body of the waves, and foam on their peaks.
		// Stretched along the waves' travel, so the bands lie as swells, not blobs.
		vec2 a = vec2(p.x * 0.22 + t * 0.1, p.y * 0.85 - t * 0.04);
		vec2 b = vec2(p.x * 0.18 - t * 0.07, p.y * 0.7 + t * 0.06);
		float v = wc_noise(a) * 0.55 + wc_noise(b + 3.7) * 0.45;
		v += sin(p.x * 0.3 + p.y * 0.9 - t * 0.8) * 0.07;
		// Foam: the peaks, and a thin line where the waves' bodies meet deep water.
		if (v > 0.68 || abs(v - 0.48) < 0.012) {
			return 2;
		}
		return v > 0.48 ? 1 : 0;
	} else if (ether == 2) {
		// Lightning. Faint, broken strokes in the ground; and two bolts, each at a
		// hashed place, bent by a jagged wave and tapered at both ends, that strike
		// for a moment roughly every two seconds (well under one flash a second).
		float col = floor(p.x * 0.5);
		float zig = abs(fract(p.x * 0.5 + wc_fbm(vec2(p.x * 0.3, p.y * 0.2)) * 0.6) - 0.5) * (0.25 + 0.5 * wc_hash(vec2(col, 7.0)));
		float jag = wc_cut(fract(p.y * 0.22 + zig + wc_hash(vec2(col, 3.0)) * 0.5) - 0.5, 0.05, px * 0.4);
		jag *= step(0.55, wc_noise(vec2(p.x * 0.4, p.y * 0.15)));
		float cycle = 2.1;
		float slot = t > 0.0 ? floor(t / cycle) : 3.0;
		float on = t > 0.0 ? step(fract(t / cycle), 0.2) : 1.0;
		int tone = jag > 0.5 ? 1 : 0;
		for (int b = 0; b < 2; b++) {
			float seed = slot * 2.0 + float(b);
			// One bolt in each half, so they never cross.
			float pos = 0.12 + 0.5 * float(b) + 0.26 * wc_hash(vec2(seed, 1.3));
			float bend = wc_tri(uv.y * (2.0 + 2.0 * wc_hash(vec2(seed, 2.1))) + wc_hash(vec2(seed, 3.7)));
			bend += wc_tri(uv.y * 7.0 + wc_hash(vec2(seed, 5.9))) * 0.35;
			float x = pos + bend * 0.07;
			// Distance across the bolt, not just sideways, so slanted runs keep
			// their width: divide by the length of the bolt's direction.
			float e = 0.004;
			float bend2 = wc_tri((uv.y + e) * (2.0 + 2.0 * wc_hash(vec2(seed, 2.1))) + wc_hash(vec2(seed, 3.7)))
				+ wc_tri((uv.y + e) * 7.0 + wc_hash(vec2(seed, 5.9))) * 0.35;
			float slope = (bend2 - bend) * 0.07 / e * (size_ratio());
			float taper = 1.0 - pow(abs(uv.y * 2.0 - 1.0), 3.0);
			float w = 0.012 * taper;
			float d = abs(uv.x - x) / sqrt(1.0 + slope * slope);
			if (d < w) {
				return on > 0.5 ? 2 : 1;
			}
			if (on > 0.5 && d < w * 2.4) {
				tone = 1;
			}
		}
		return tone;
	}
	// Shadow. Smoke: fbm folded into itself twice, drifting up, then cut into the
	// dark, a mid-tone body and thin bright curls along one level.
	vec2 q = vec2(p.x * 0.45, p.y * 0.3 + t * 0.15);
	float a = wc_fbm(q + vec2(t * 0.04, 0.0));
	float b = wc_fbm(q + vec2(a * 1.7, a * 1.2) + vec2(1.7, 9.2) - t * 0.03);
	float v = wc_fbm(q + vec2(b * 1.9, b * 1.4) + vec2(8.3, 2.8));
	v += (h - 0.5) * -0.15;
	if (abs(v - 0.58) < 0.022) {
		return 2;
	}
	return v > 0.55 ? 1 : 0;
}
