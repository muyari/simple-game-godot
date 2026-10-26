shader_type canvas_item;
// A potion flask drawn at any resolution, in the same style as the resource globes: a round glass body
// and neck with a gold band and a cork, liquid with a rolling surface and bubbles, and glass highlights.
// The flask is fitted to the height of the rect and centred across it.

uniform float fill_level : hint_range(0.0, 1.0) = 1.0;
// 0..1: brightens the liquid (a fresh charge just arrived).
uniform float surge : hint_range(0.0, 1.0) = 0.0;
uniform vec4 liquid_deep : source_color = vec4(0.35, 0.02, 0.04, 1.0);
uniform vec4 liquid_bright : source_color = vec4(0.95, 0.18, 0.16, 1.0);
// Width / height of the rect this is drawn on.
uniform float aspect = 0.6;
uniform float seed = 0.0;

const vec3 RIM = vec3(0.078, 0.031, 0.012);
const vec3 GOLD = vec3(0.788, 0.604, 0.235);
const vec3 GOLD_LIGHT = vec3(0.965, 0.89, 0.63);
const vec3 GOLD_DARK = vec3(0.43, 0.29, 0.09);
const vec3 CORK = vec3(0.55, 0.36, 0.2);
const vec3 CORK_DARK = vec3(0.3, 0.18, 0.09);
const vec3 GLASS_EDGE = vec3(0.72, 0.82, 0.9);

const vec2 BODY_CENTER = vec2(0.0, 0.69);
const float BODY_RADIUS = 0.28;
const float NECK_HALF_WIDTH = 0.082;
const float NECK_TOP = 0.2;
const float WALL = 0.03;

float hash(float n) {
	return fract(sin(n * 91.345 + seed * 17.13) * 47453.5453);
}

float sd_box(vec2 p, vec2 center, vec2 half_size) {
	vec2 d = abs(p - center) - half_size;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float smooth_union(float a, float b, float k) {
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
	return mix(b, a, h) - k * h * (1.0 - h);
}

vec4 blend(vec4 under, vec3 color, float alpha) {
	return vec4(mix(under.rgb, color, alpha), max(under.a, alpha));
}

void fragment() {
	// x centred, y from 0 (top) to 1 (bottom), in units of the rect height.
	vec2 p = vec2((UV.x - 0.5) * aspect, UV.y);
	float aa = fwidth(p.y) * 1.2;
	float t = TIME;
	vec4 col = vec4(0.0);

	float body = length(p - BODY_CENTER) - BODY_RADIUS;
	float neck = sd_box(p, vec2(0.0, (NECK_TOP + BODY_CENTER.y) * 0.5), vec2(NECK_HALF_WIDTH, (BODY_CENTER.y - NECK_TOP) * 0.5));
	float vessel = smooth_union(body, neck, 0.05);

	// Soft shadow, then a dark outline so the flask reads on any ground.
	float shadow = (1.0 - smoothstep(-0.01, 0.03, length(p - BODY_CENTER - vec2(0.0, 0.02)) - BODY_RADIUS)) * 0.5;
	col = vec4(0.0, 0.0, 0.0, shadow);
	col = blend(col, RIM, smoothstep(0.018 + aa, 0.018 - aa, vessel));

	// Glass: dark inside, a pale wall.
	float in_glass = smoothstep(aa, -aa, vessel);
	if (in_glass > 0.0) {
		vec3 glass = mix(liquid_deep.rgb * 0.15, vec3(0.03, 0.03, 0.04), 0.5);
		float liquid_top = NECK_TOP + 0.13;
		float liquid_bottom = BODY_CENTER.y + BODY_RADIUS - WALL;
		float calm = smoothstep(0.0, 0.06, fill_level) * smoothstep(1.0, 0.94, fill_level);
		float wave = (sin(p.x * 34.0 + t * 2.4) * 0.6 + sin(p.x * 61.0 - t * 3.6) * 0.4) * 0.008 * calm;
		float surface = mix(liquid_bottom, liquid_top, fill_level) + wave;
		float edge = aa * 1.2;
		float in_liquid = smoothstep(surface - edge, surface + edge, p.y) * smoothstep(-WALL + aa, -WALL - aa, vessel);
		if (in_liquid > 0.0) {
			float depth = clamp((p.y - surface) / max(liquid_bottom - surface, 0.03), 0.0, 1.0);
			vec3 liquid = mix(liquid_bright.rgb, liquid_deep.rgb, depth);
			liquid *= 1.0 - smoothstep(0.1, BODY_RADIUS, length(p - BODY_CENTER)) * 0.4;
			float meniscus = smoothstep(edge * 3.0 + 0.02, 0.0, p.y - surface);
			liquid = mix(liquid, mix(liquid_bright.rgb, vec3(1.0), 0.45), meniscus * 0.7);
			for (int i = 0; i < 4; i++) {
				float fi = float(i);
				float cycle = fract(t * (0.18 + hash(fi) * 0.2) + hash(fi + 5.0));
				vec2 c = vec2((hash(fi + 2.0) - 0.5) * 0.3, mix(liquid_bottom - 0.03, surface, cycle));
				float size = 0.012 + hash(fi + 9.0) * 0.012;
				float ring = smoothstep(size + edge, size, length(p - c));
				liquid = mix(liquid, mix(liquid_bright.rgb, vec3(1.0), 0.6), ring * 0.5 * step(surface, c.y));
			}
			liquid = mix(liquid, liquid_bright.rgb * 1.5, surge * 0.45);
			glass = mix(glass, liquid, in_liquid);
		}
		// Wall and highlights.
		float wall = smoothstep(-WALL - aa, -WALL + aa, vessel);
		glass = mix(glass, GLASS_EDGE * 0.55, wall * 0.55);
		float streak = smoothstep(0.035, 0.0, abs(length((p - BODY_CENTER) * vec2(1.0, 1.0)) - BODY_RADIUS * 0.72))
				* smoothstep(0.2, -0.6, dot(normalize(p - BODY_CENTER), vec2(0.8, 0.6)))
				* step(p.x, 0.0);
		glass = mix(glass, vec3(1.0), streak * 0.4);
		float glint = smoothstep(0.03, 0.012, length(p - BODY_CENTER - vec2(-0.14, -0.15)));
		glass = mix(glass, vec3(1.0), glint * 0.8);
		float neck_line = smoothstep(0.012, 0.0, abs(p.x + NECK_HALF_WIDTH * 0.5)) * step(NECK_TOP, p.y) * step(p.y, BODY_CENTER.y - BODY_RADIUS + 0.02);
		glass = mix(glass, vec3(1.0), neck_line * 0.3);
		col = blend(col, glass, in_glass);
	}

	// Gold band round the lip of the neck.
	float lip = sd_box(p, vec2(0.0, NECK_TOP + 0.012), vec2(NECK_HALF_WIDTH + 0.022, 0.024)) - 0.008;
	float in_lip = smoothstep(aa, -aa, lip);
	if (in_lip > 0.0) {
		float shade = clamp((p.y - (NECK_TOP - 0.02)) / 0.06, 0.0, 1.0);
		vec3 gold = mix(GOLD_LIGHT, GOLD_DARK, shade);
		gold = mix(gold, GOLD, 0.4);
		gold = mix(RIM, gold, smoothstep(0.0, -0.008, lip));
		col = blend(col, gold, in_lip);
	}

	// Cork.
	float cork = sd_box(p, vec2(0.0, NECK_TOP - 0.06), vec2(NECK_HALF_WIDTH * 0.8, 0.05)) - 0.012;
	float in_cork = smoothstep(aa, -aa, cork);
	if (in_cork > 0.0) {
		vec3 c = mix(CORK * 1.15, CORK_DARK, clamp((p.x + 0.08) / 0.16, 0.0, 1.0));
		c *= 0.85 + 0.15 * sin(p.y * 160.0);
		c = mix(RIM, c, smoothstep(0.0, -0.01, cork));
		col = blend(col, c, in_cork);
	}

	COLOR = col;
}
