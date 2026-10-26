shader_type canvas_item;
// Smooth painted ground for Oblath, drawn in world space at screen resolution (so it is never pixelated):
// a meadow of soft greens with sun-dappled swells, fine grass strokes and scattered tiny flowers, plus
// procedural paving modes for the streets (bricks in running bond) and the plaza (rounded cobbles).

// 0 = grass, 1 = brick paving, 2 = cobbles, 3 = packed dirt.
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

// Signed distance to a rounded box centred on the origin.
float rounded_box(vec2 p, vec2 half_size, float radius) {
	vec2 q = abs(p) - half_size + radius;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

vec3 grass(vec2 w) {
	float broad = noise(w * 0.00055);
	float mid = noise(w * 0.0021 + vec2(0.31, 0.77));
	float fine = noise(w * 0.011 + vec2(0.5, 0.2));
	vec3 deep = vec3(0.19, 0.35, 0.12);
	vec3 base = vec3(0.29, 0.47, 0.16);
	vec3 light = vec3(0.45, 0.6, 0.22);
	vec3 col = mix(deep, base, smoothstep(0.25, 0.6, broad));
	col = mix(col, light, smoothstep(0.55, 0.85, broad * 0.6 + mid * 0.4) * 0.7);
	col *= 0.93 + 0.12 * fine;
	// Short grass strokes: soft slanted dashes on a jittered grid.
	vec2 cell_size = vec2(9.0, 7.0);
	vec2 cell = floor(w / cell_size);
	vec2 jitter = hash22(cell);
	vec2 local = (w - (cell + 0.2 + 0.6 * jitter) * cell_size);
	float lean = (jitter.x - 0.5) * 0.8;
	float along = clamp(local.y, -5.0, 0.0);
	float d = abs(local.x - along * lean) - 0.55 * (1.0 + along / 5.0);
	float stroke = (1.0 - smoothstep(-0.2, 0.9, d)) * step(-5.0, local.y) * step(local.y, 0.5);
	vec3 blade = mix(col * 0.72, col * 1.25, jitter.y);
	col = mix(col, blade, stroke * 0.85);
	// Tiny flowers here and there.
	vec2 flower_cell = floor(w / 46.0);
	vec2 fj = hash22(flower_cell + 17.0);
	if (fj.x > 0.82) {
		vec2 c = (flower_cell + 0.15 + 0.7 * hash22(flower_cell + 3.0)) * 46.0;
		float r = length((w - c) * vec2(1.0, 1.3));
		float petal = 1.0 - smoothstep(1.4, 2.4, r);
		vec3 tint = fj.y < 0.33 ? vec3(0.98, 0.95, 0.85) : (fj.y < 0.66 ? vec3(0.98, 0.83, 0.3) : vec3(0.93, 0.55, 0.72));
		col = mix(col, tint, petal);
		col = mix(col, vec3(0.95, 0.8, 0.3), (1.0 - smoothstep(0.3, 0.9, r)) * petal);
	}
	return col;
}

vec3 bricks(vec2 w) {
	vec2 brick = vec2(30.0, 15.0);
	float row = floor(w.y / brick.y);
	vec2 p = vec2(w.x + mod(row, 2.0) * brick.x * 0.5, w.y);
	vec2 id = floor(p / brick);
	vec2 local = p - (id + 0.5) * brick;
	float d = rounded_box(local, brick * 0.5 - 1.3, 2.6);
	float aa = fwidth(d) + 0.001;
	float tint = hash12(id);
	vec3 stone = mix(vec3(0.6, 0.55, 0.5), vec3(0.72, 0.67, 0.6), tint);
	stone = mix(stone, vec3(0.62, 0.5, 0.42), step(0.86, hash12(id + 9.0)) * 0.5);
	// Each brick is gently domed: light on the top-left, shade on the bottom-right.
	vec2 n = local / (brick * 0.5);
	stone *= 1.0 + (-n.x * 0.05 - n.y * 0.09);
	stone *= 1.0 - smoothstep(-3.0, 0.0, d) * 0.22;
	stone *= 0.94 + 0.1 * noise(w * 0.02);
	vec3 mortar = vec3(0.32, 0.29, 0.26);
	vec3 col = mix(stone, mortar, smoothstep(-aa, aa, d));
	// Broad wear so it doesn't read as a flat repeat.
	col *= 0.9 + 0.16 * noise(w * 0.0015 + 0.4);
	return col;
}

vec3 cobbles(vec2 w) {
	vec2 cell_size = vec2(22.0);
	vec2 g = w / cell_size;
	vec2 cell = floor(g);
	float best = 8.0;
	float second = 8.0;
	vec2 best_id = vec2(0.0);
	vec2 best_offset = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 id = cell + vec2(float(x), float(y));
			vec2 centre = id + 0.2 + 0.6 * hash22(id);
			vec2 offset = g - centre;
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
	float edge = (second - best) * cell_size.x;
	float aa = fwidth(edge) + 0.001;
	float tint = hash12(best_id);
	vec3 stone = mix(vec3(0.55, 0.53, 0.5), vec3(0.74, 0.71, 0.66), tint);
	// Rounded tops: lit from the upper left, darker toward the joints.
	stone *= 1.05 - length(best_offset) * 0.35 - dot(best_offset, vec2(0.2, 0.3)) * 0.25;
	stone *= 0.95 + 0.08 * noise(w * 0.03);
	vec3 joint = vec3(0.3, 0.28, 0.25);
	return mix(joint, stone, smoothstep(1.2 - aa, 1.2 + aa * 2.0, edge));
}

vec3 dirt(vec2 w) {
	float n = noise(w * 0.004) * 0.6 + noise(w * 0.018 + 0.3) * 0.4;
	vec3 col = mix(vec3(0.47, 0.36, 0.23), vec3(0.6, 0.47, 0.3), n);
	// Scattered pebbles.
	vec2 cell = floor(w / 7.0);
	vec2 j = hash22(cell + 5.0);
	vec2 c = (cell + 0.2 + 0.6 * j) * 7.0;
	float r = length((w - c) * vec2(1.0, 1.4));
	float pebble = (1.0 - smoothstep(0.9, 1.6, r)) * step(0.72, j.x);
	col = mix(col, j.y > 0.5 ? vec3(0.68, 0.6, 0.5) : vec3(0.36, 0.28, 0.19), pebble * 0.8);
	return col;
}

void fragment() {
	vec3 col;
	if (mode == 1) {
		col = bricks(world);
	} else if (mode == 2) {
		col = cobbles(world);
	} else if (mode == 3) {
		col = dirt(world);
	} else {
		col = grass(world);
	}
	COLOR = vec4(col, 1.0) * vec4(1.0, 1.0, 1.0, COLOR.a);
}
