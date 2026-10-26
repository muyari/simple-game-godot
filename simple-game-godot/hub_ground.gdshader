shader_type canvas_item;
// Smooth painted ground for the regional hubs, drawn in world space at screen resolution like Oblath's
// town_ground.gdshader: wind-rippled sand and packed trails for Saltwind Camp, snow, glassy ice and cave
// rock for Rimehollow, and scorched earth and cracked flagstones for Ashgate Outpost.

// 0 = sand, 1 = packed trail, 2 = snow, 3 = ice, 4 = cave rock, 5 = scorched earth, 6 = flagstones.
uniform int mode = 0;
uniform sampler2D noise_texture : repeat_enable, filter_linear;

varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.103, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

float noise(vec2 p) {
	return texture(noise_texture, p).r;
}

// Distance to the nearest Voronoi edge, the id of the cell and the offset from its centre.
float voronoi(vec2 g, out vec2 best_id, out vec2 best_offset) {
	vec2 cell = floor(g);
	float best = 8.0;
	float second = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 id = cell + vec2(float(x), float(y));
			vec2 offset = g - (id + 0.15 + 0.7 * hash22(id));
			float d = length(offset);
			if (d < best) {
				second = best;
				best = d;
				best_id = id;
				best_offset = offset;
			} else if (d < second) {
				second = d;
			}
		}
	}
	return second - best;
}

// Soft wind ripples running across the ground, bent by the broad noise.
float ripples(vec2 w, float spacing, float bend) {
	float warp = noise(w * 0.0012) * bend + noise(w * 0.004 + 0.3) * bend * 0.3;
	float wave = sin((w.y + w.x * 0.18 + warp) / spacing * 6.2832);
	return smoothstep(0.55, 0.95, wave);
}

vec3 sand(vec2 w) {
	float broad = noise(w * 0.0006);
	float mid = noise(w * 0.0025 + vec2(0.4, 0.1));
	vec3 low = vec3(0.79, 0.6, 0.36);
	vec3 high = vec3(0.93, 0.77, 0.5);
	vec3 col = mix(low, high, smoothstep(0.2, 0.75, broad * 0.7 + mid * 0.3));
	// Ripple crests catch the sun; their lee sides fall into soft shade.
	float crest = ripples(w, 22.0, 70.0);
	float lee = ripples(w + vec2(0.0, 4.0), 22.0, 70.0);
	col *= 1.0 + crest * 0.045 - lee * 0.05;
	// Fine grain.
	col *= 0.96 + 0.06 * hash12(floor(w * 0.7));
	return col;
}

vec3 trail(vec2 w) {
	float n = noise(w * 0.004) * 0.6 + noise(w * 0.02 + 0.3) * 0.4;
	vec3 col = mix(vec3(0.62, 0.45, 0.27), vec3(0.74, 0.56, 0.35), n);
	// Scattered grit and the odd darker stone.
	vec2 cell = floor(w / 8.0);
	vec2 j = hash22(cell + 11.0);
	vec2 c = (cell + 0.2 + 0.6 * j) * 8.0;
	float r = length((w - c) * vec2(1.0, 1.4));
	float stone = (1.0 - smoothstep(0.8, 1.7, r)) * step(0.7, j.x);
	col = mix(col, j.y > 0.5 ? vec3(0.8, 0.68, 0.5) : vec3(0.45, 0.32, 0.2), stone * 0.75);
	return col;
}

vec3 snow(vec2 w) {
	float broad = noise(w * 0.0007 + 0.2);
	float mid = noise(w * 0.003 + vec2(0.7, 0.3));
	vec3 shade = vec3(0.72, 0.8, 0.9);
	vec3 lit = vec3(0.95, 0.97, 1.0);
	vec3 col = mix(shade, lit, smoothstep(0.25, 0.75, broad * 0.6 + mid * 0.4));
	// Wind-carved sastrugi: long, soft blue grooves.
	float groove = ripples(w, 34.0, 110.0);
	col = mix(col, col * vec3(0.88, 0.92, 1.0), groove * 0.5);
	// Sparkles in the crust.
	vec2 cell = floor(w / 5.0);
	vec2 j = hash22(cell + 3.0);
	float glint = step(0.985, j.x) * (1.0 - smoothstep(0.3, 1.2, length(w - (cell + j) * 5.0)));
	col += glint * 0.25;
	return col;
}

vec3 ice(vec2 w) {
	float n = noise(w * 0.0015) * 0.6 + noise(w * 0.006 + 0.5) * 0.4;
	vec3 col = mix(vec3(0.42, 0.62, 0.78), vec3(0.66, 0.84, 0.94), smoothstep(0.25, 0.8, n));
	// Pale streaks frozen into it, and fine cracks.
	float streak = smoothstep(0.62, 0.7, noise(w * vec2(0.004, 0.012) + 0.1));
	col = mix(col, vec3(0.85, 0.94, 1.0), streak * 0.35);
	vec2 id;
	vec2 offset;
	float edge = voronoi(w / 70.0, id, offset) * 70.0;
	float crack = 1.0 - smoothstep(0.0, 0.9, edge);
	col = mix(col, vec3(0.9, 0.97, 1.0), crack * 0.55 * step(0.45, hash12(id)));
	// A soft gloss that brightens toward the top-left.
	col += 0.05 * smoothstep(0.6, 0.9, noise(w * 0.002 + 0.8));
	return col;
}

vec3 cave_rock(vec2 w) {
	vec2 id;
	vec2 offset;
	float edge = voronoi(w / 40.0, id, offset) * 40.0;
	float aa = fwidth(edge) + 0.001;
	vec3 stone = mix(vec3(0.2, 0.25, 0.33), vec3(0.3, 0.36, 0.45), hash12(id));
	stone *= 1.05 - length(offset) * 0.3 - dot(offset, vec2(0.25, 0.35)) * 0.3;
	stone *= 0.9 + 0.15 * noise(w * 0.01);
	// Frost settled in the hollows.
	stone = mix(stone, vec3(0.75, 0.85, 0.95), smoothstep(0.55, 0.8, noise(w * 0.006 + 0.4)) * 0.35);
	return mix(vec3(0.1, 0.13, 0.18), stone, smoothstep(1.0 - aa, 1.5 + aa, edge));
}

vec3 scorched(vec2 w) {
	float broad = noise(w * 0.0008 + 0.6);
	float fine = noise(w * 0.012 + 0.2);
	vec3 col = mix(vec3(0.17, 0.12, 0.1), vec3(0.32, 0.24, 0.19), smoothstep(0.2, 0.8, broad));
	col *= 0.9 + 0.18 * fine;
	// Ash drifts.
	col = mix(col, vec3(0.42, 0.39, 0.37), smoothstep(0.6, 0.85, noise(w * 0.003 + 0.9)) * 0.45);
	// Glowing fissures, sparse and slowly pulsing.
	vec2 id;
	vec2 offset;
	float edge = voronoi(w / 120.0, id, offset) * 120.0;
	float vein = (1.0 - smoothstep(0.0, 1.6, edge)) * step(0.7, hash12(id + 4.0));
	float pulse = 0.75 + 0.25 * sin(TIME * 1.7 + hash12(id) * 6.2832);
	col = mix(col, vec3(1.0, 0.42, 0.1) * pulse, vein * 0.9);
	col += vec3(0.35, 0.08, 0.0) * (1.0 - smoothstep(0.0, 7.0, edge)) * step(0.7, hash12(id + 4.0)) * 0.4 * pulse;
	return col;
}

vec3 flagstones(vec2 w) {
	vec2 id;
	vec2 offset;
	float edge = voronoi(w / 34.0, id, offset) * 34.0;
	float aa = fwidth(edge) + 0.001;
	vec3 stone = mix(vec3(0.38, 0.35, 0.33), vec3(0.52, 0.48, 0.44), hash12(id));
	stone *= 1.06 - length(offset) * 0.25 - dot(offset, vec2(0.2, 0.3)) * 0.25;
	stone *= 0.93 + 0.1 * noise(w * 0.025);
	// Soot and scorch marks from the siege.
	float soot = smoothstep(0.5, 0.8, noise(w * 0.0025 + 0.35));
	stone = mix(stone, vec3(0.13, 0.1, 0.09), soot * 0.6);
	// The odd slab split in two.
	float split = abs(dot(offset, normalize(hash22(id + 2.0) - 0.5)));
	stone = mix(stone, vec3(0.16, 0.13, 0.12), (1.0 - smoothstep(0.0, 0.04, split)) * step(0.75, hash12(id + 7.0)));
	return mix(vec3(0.16, 0.13, 0.12), stone, smoothstep(1.0 - aa, 1.0 + aa * 2.0, edge));
}

void fragment() {
	vec3 col;
	if (mode == 1) {
		col = trail(world);
	} else if (mode == 2) {
		col = snow(world);
	} else if (mode == 3) {
		col = ice(world);
	} else if (mode == 4) {
		col = cave_rock(world);
	} else if (mode == 5) {
		col = scorched(world);
	} else if (mode == 6) {
		col = flagstones(world);
	} else {
		col = sand(world);
	}
	COLOR = vec4(col, 1.0) * vec4(1.0, 1.0, 1.0, COLOR.a);
}
