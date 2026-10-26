shader_type canvas_item;
// A resource globe drawn at any resolution: a bevelled gold frame with gem studs, dark glass, liquid
// with a rolling surface, a slow swirl and rising bubbles, a pale band where recent damage drains away,
// and glass highlights over the top. Draw it on a square Control.

uniform float fill_level : hint_range(0.0, 1.0) = 1.0;
// Where the pale "recently lost" band reaches up to; at or below fill_level it is hidden.
uniform float trail_level : hint_range(0.0, 1.0) = 1.0;
// 0..1: healing shimmer.
uniform float surge : hint_range(0.0, 1.0) = 0.0;
// 0..1: low-resource heartbeat glow.
uniform float pulse : hint_range(0.0, 1.0) = 0.0;
uniform vec4 liquid_deep : source_color = vec4(0.35, 0.02, 0.04, 1.0);
uniform vec4 liquid_bright : source_color = vec4(0.95, 0.18, 0.16, 1.0);
uniform vec4 gem_color : source_color = vec4(0.78, 0.13, 0.16, 1.0);
uniform float seed = 0.0;

const vec3 RIM = vec3(0.078, 0.031, 0.012);
const vec3 GOLD = vec3(0.788, 0.604, 0.235);
const vec3 GOLD_LIGHT = vec3(0.965, 0.89, 0.63);
const vec3 GOLD_DARK = vec3(0.43, 0.29, 0.09);
const float R_GLASS = 0.80;
const float R_FRAME = 0.95;
const float R_OUTER = 0.985;

float hash(float n) {
	return fract(sin(n * 91.345 + seed * 17.13) * 47453.5453);
}

// Smooth value noise built from sines, enough for a slow liquid swirl.
float swirl(vec2 p, float t) {
	float v = sin(p.x * 3.1 + t * 0.7) * sin(p.y * 2.7 - t * 0.5);
	v += 0.5 * sin(p.x * 5.3 - p.y * 4.1 + t * 1.1);
	v += 0.25 * sin(length(p - vec2(0.2, 0.3)) * 9.0 - t * 1.6);
	return v * 0.5 + 0.5;
}

vec4 blend(vec4 under, vec3 color, float alpha) {
	return vec4(mix(under.rgb, color, alpha), max(under.a, alpha));
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float aa = fwidth(r) * 1.2;
	float t = TIME;
	vec4 col = vec4(0.0);

	// Soft drop shadow under the frame.
	float shadow = (1.0 - smoothstep(R_OUTER - 0.02, 1.0, length(p - vec2(0.0, 0.025)))) * 0.55;
	col = vec4(0.0, 0.0, 0.0, shadow);

	// Frame: dark rim, bevelled gold band, dark inner lip.
	float in_frame = smoothstep(R_OUTER + aa, R_OUTER - aa, r);
	if (in_frame > 0.0) {
		float band = clamp((r - R_GLASS) / (R_FRAME - R_GLASS), 0.0, 1.0);
		vec2 dir = r > 0.0 ? p / r : vec2(0.0, -1.0);
		float light = dot(dir, normalize(vec2(-0.6, -0.8)));
		float profile = sin(band * 3.14159);
		vec3 gold = mix(GOLD_DARK, GOLD, 0.45 + 0.55 * profile);
		gold = mix(gold, GOLD_LIGHT, clamp(profile * profile * (0.35 + 0.65 * light), 0.0, 1.0) * 0.8);
		gold *= 0.75 + 0.25 * light;
		// A glint sweeps round the band every few seconds.
		float angle = atan(p.y, p.x);
		float sweep = mod(t * 0.9, 6.2832 * 1.6) - 3.14159;
		float glint = pow(max(0.0, 1.0 - abs(angle - sweep) * 2.2), 6.0) * profile;
		gold = mix(gold, GOLD_LIGHT, glint * 0.8);
		vec3 frame = gold;
		frame = mix(frame, RIM, smoothstep(R_FRAME - aa, R_FRAME + aa, r));
		frame = mix(frame, RIM, 1.0 - smoothstep(R_GLASS - aa, R_GLASS + aa * 2.0, r));
		col = blend(col, frame, in_frame);

		// Gem studs set into the band.
		float mid = (R_GLASS + R_FRAME) * 0.5;
		for (int i = 0; i < 4; i++) {
			float a = 0.7854 + float(i) * 1.5708;
			vec2 c = vec2(cos(a), sin(a)) * mid;
			float d = length(p - c);
			float stud = smoothstep(0.052 + aa, 0.052 - aa, d);
			vec3 gem = mix(gem_color.rgb * 0.45, gem_color.rgb, smoothstep(0.05, -0.02, dot(p - c, vec2(-0.6, -0.8))));
			gem = mix(gem, vec3(1.0), smoothstep(0.018, 0.0, length(p - c - vec2(-0.016, -0.018))) * 0.85);
			col = blend(col, mix(GOLD_DARK, gem, smoothstep(0.052, 0.038, d)), stud);
		}
	}

	// Glass interior.
	float in_glass = smoothstep(R_GLASS + aa, R_GLASS - aa, r);
	if (in_glass > 0.0) {
		// Dark glass, faintly tinted and catching a little light low down.
		vec3 glass = mix(vec3(0.025, 0.02, 0.03), liquid_deep.rgb * 0.45, clamp(p.y * 0.5 + 0.5, 0.0, 1.0) * 0.55);

		// Liquid: a rolling surface that calms when the globe is nearly empty or full.
		float calm = smoothstep(0.0, 0.06, fill_level) * smoothstep(1.0, 0.94, fill_level);
		float wave = (sin(p.x * 5.5 + t * 2.1) * 0.6 + sin(p.x * 10.5 - t * 3.3) * 0.4) * 0.028 * calm;
		float surface = mix(R_GLASS, -R_GLASS, fill_level) + wave;
		float trail_surface = mix(R_GLASS, -R_GLASS, trail_level) + wave * 0.6;
		float edge = fwidth(p.y) * 1.5;

		// Pale band of what was just lost, draining after the liquid.
		if (trail_level > fill_level + 0.002) {
			float in_trail = smoothstep(trail_surface - edge, trail_surface + edge, p.y);
			// A translucent wash, brightest at its top edge and fading down into the liquid.
			float top_edge = smoothstep(0.06, 0.0, p.y - trail_surface);
			vec3 trail = mix(liquid_bright.rgb, vec3(1.0, 0.95, 0.88), 0.35);
			glass = mix(glass, trail, in_trail * (0.28 + 0.3 * top_edge));
		}

		float in_liquid = smoothstep(surface - edge, surface + edge, p.y);
		if (in_liquid > 0.0) {
			float depth = clamp((p.y - surface) / max(R_GLASS - surface, 0.05), 0.0, 1.0);
			vec3 liquid = mix(liquid_bright.rgb, liquid_deep.rgb, smoothstep(0.0, 1.0, depth));
			float s = swirl(p * 1.4 + vec2(0.0, t * 0.05), t);
			liquid *= 0.82 + 0.3 * s;
			// Rounded like a sphere: darker toward the glass.
			liquid *= 1.0 - pow(r / R_GLASS, 3.0) * 0.45;
			// Meniscus: a bright line along the surface.
			float meniscus = smoothstep(edge * 4.0 + 0.035, 0.0, p.y - surface);
			liquid = mix(liquid, mix(liquid_bright.rgb, vec3(1.0), 0.45), meniscus * 0.7);
			// Bubbles rising from the bottom.
			for (int i = 0; i < 6; i++) {
				float fi = float(i);
				float speed = 0.12 + hash(fi) * 0.16;
				float cycle = fract(t * speed + hash(fi + 7.0));
				vec2 c = vec2((hash(fi + 3.0) - 0.5) * 1.1 + sin(t * 2.0 + fi) * 0.03, mix(R_GLASS * 0.9, surface, cycle));
				float size = 0.012 + hash(fi + 11.0) * 0.018;
				float d = length(p - c);
				float ring = smoothstep(size + edge, size, d) * (1.0 - smoothstep(size * 0.45, size * 0.45 - edge, d) * 0.6);
				liquid = mix(liquid, mix(liquid_bright.rgb, vec3(1.0), 0.6), ring * 0.55 * step(surface, c.y));
			}
			// Healing shimmer: bright streaks rising through the liquid.
			float shimmer = pow(max(0.0, sin(p.y * 22.0 + t * 9.0 + sin(p.x * 6.0) * 1.5)), 6.0);
			liquid = mix(liquid, liquid_bright.rgb * 1.35, surge * (0.18 + 0.22 * shimmer));
			// Low-resource heartbeat.
			float beat = pow(max(0.0, sin(t * 6.0)), 3.0);
			liquid += liquid_bright.rgb * pulse * beat * 0.35;
			glass = mix(glass, liquid, in_liquid);
		}

		// Shade toward the rim, then the glass highlights.
		glass *= 1.0 - smoothstep(R_GLASS * 0.72, R_GLASS, r) * 0.45;
		float crescent = smoothstep(0.42, 0.18, length((p - vec2(-0.26, -0.36)) * vec2(1.0, 1.35)));
		crescent *= smoothstep(0.1, 0.32, length((p - vec2(-0.12, -0.18)) * vec2(1.0, 1.2)));
		glass = mix(glass, vec3(1.0), crescent * 0.32);
		float glint = smoothstep(0.075, 0.035, length(p - vec2(-0.38, -0.44)));
		glass = mix(glass, vec3(1.0), glint * 0.75);
		float bounce = smoothstep(0.06, 0.0, abs(r - R_GLASS * 0.9)) * smoothstep(0.1, 0.8, dot(p / max(r, 0.001), vec2(0.55, 0.83)));
		glass = mix(glass, mix(liquid_bright.rgb, vec3(1.0), 0.5), bounce * 0.3);
		col = blend(col, glass, in_glass);
	}

	COLOR = col;
}
