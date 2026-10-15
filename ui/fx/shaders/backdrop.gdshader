shader_type canvas_item;
// The screen background. With stone_amount 0 it is the old flat background: the
// base colour, a little lighter in the middle, darker toward the edges, faintly
// tinted at top left by the Encounter's Ether. With stone_amount 1 it is carved
// stone, cracked, with the rift's Ether light glowing through the cracks and from
// one source; never beneath a zone, so it never sits under text.

uniform vec4 base : source_color = vec4(0.063, 0.055, 0.09, 1.0);
uniform vec4 glow : source_color = vec4(0.17, 0.15, 0.25, 1.0);
// The Encounter's Ether, in its deep shade; tint_amount 0 leaves it out.
uniform vec4 ether_tint : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float tint_amount = 0.0;

uniform float stone_amount = 0.0;
uniform sampler2D grain : repeat_enable, filter_linear;
uniform sampler2D cracks : repeat_enable, filter_linear;
uniform vec2 view_size = vec2(1280.0, 720.0);
// The rift light: its colour, and which Ether's character it moves with (-1 none,
// 0 fire, 1 water, 2 lightning, 3 shadow).
uniform vec4 seam_colour : source_color = vec4(0.56, 0.5, 0.84, 1.0);
uniform int ether_id = -1;
// The rift's own clock, held still under reduced motion.
uniform float clock = 0.0;
// How much the seams move: 1 normally, 0.5 while a sequence plays, 0 held still.
uniform float motion = 1.0;
// Where the light comes from, in pixels.
uniform vec2 rift_source = vec2(240.0, 260.0);
// Zone rectangles in pixels (x, y, width, height): no light beneath them.
uniform vec4 zones[8];
uniform int zone_count = 0;
// Responses push this briefly up (a win, a Play) or down (a loss).
uniform float intensity = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// How far inside any zone a pixel is: 1 inside, falling to 0 a few units outside.
float under_zone(vec2 px) {
	float inside = 0.0;
	for (int i = 0; i < 8; i++) {
		if (i >= zone_count) {
			break;
		}
		vec4 z = zones[i];
		vec2 d = max(z.xy - px, px - (z.xy + z.zw));
		float sd = max(d.x, d.y);
		inside = max(inside, 1.0 - smoothstep(-4.0, 10.0, sd));
	}
	return inside;
}

// The seams' brightness over time, in each Ether's character: faint and slow.
float shimmer(vec2 cell, vec2 px) {
	float h = hash(cell);
	float t = clock;
	float s = 0.78 + 0.22 * sin(t * 0.9 + h * 6.283);
	if (ether_id == 0) {
		// Fire: warmer and quicker, a small flicker.
		s = 0.8 + 0.14 * sin(t * 2.3 + h * 6.283) + 0.06 * sin(t * 7.1 + h * 17.0);
	} else if (ether_id == 1) {
		// Water: a slow swell that runs along the cracks.
		s = 0.72 + 0.28 * sin(t * 0.55 - px.x * 0.006 + h);
	} else if (ether_id == 2) {
		// Lightning: steady, with a brighter jolt at most once in four seconds.
		float phase = fract(t / 4.0 + h * 0.15);
		s = 0.82 + 0.4 * (1.0 - smoothstep(0.0, 0.05, phase)) * step(0.55, h);
	} else if (ether_id == 3) {
		// Shadow: dim, with faint pinpricks along the seams.
		s = 0.6 + 0.08 * sin(t * 0.7 + h * 6.283);
		s += 0.5 * step(0.985, hash(floor(px / 3.0) + floor(t * 0.5)));
	}
	return mix(0.85, s, motion);
}

void fragment() {
	float d = length((UV - vec2(0.5, 0.42)) * vec2(1.0, 1.25));
	float v = 1.0 - smoothstep(0.0, 0.75, d);
	vec3 flat_rgb = mix(base.rgb, glow.rgb, v * 0.55);
	float corner = 1.0 - smoothstep(0.0, 0.7, length((UV - vec2(0.15, 0.3)) * vec2(1.0, 1.4)));
	flat_rgb = mix(flat_rgb, ether_tint.rgb, corner * 0.12 * tint_amount);
	float edge = smoothstep(0.55, 1.05, length((UV - 0.5) * vec2(1.0, 1.3)) * 1.3);
	flat_rgb *= 1.0 - 0.35 * edge;
	if (stone_amount <= 0.0) {
		COLOR = vec4(flat_rgb, 1.0);
	} else {
		vec2 px = UV * view_size;
		vec3 stone = texture(grain, px / 256.0).rgb * (1.0 - 0.4 * edge);
		float c = texture(cracks, px / 512.0).r;
		float seam = smoothstep(0.93, 0.985, c);
		float halo = smoothstep(0.80, 0.985, c) * 0.35;
		float hidden = under_zone(px);
		// The light is strongest near the rift and only some cracks far from it
		// carry any: a slow field picks which.
		float bloom = exp(-length(px - rift_source) / (0.6 * view_size.y));
		float field = texture(grain, px / 2200.0 + 0.37).r;
		float reach = smoothstep(0.3, 0.6, (field - 0.03) * 30.0);
		float lit = (seam + halo) * shimmer(floor(px / 96.0), px) * (1.0 - hidden) * mix(0.25 + reach * 0.75, 1.0, bloom);
		vec3 light = seam_colour.rgb * (lit * 1.5 + bloom * 0.08) * intensity;
		vec3 rgb = stone + light;
		COLOR = vec4(mix(flat_rgb, rgb, stone_amount), 1.0);
	}
}
