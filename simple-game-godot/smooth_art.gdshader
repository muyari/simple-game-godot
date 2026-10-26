shader_type canvas_item;
// Draws pixel art smoothly at any scale: texel edges are blended across exactly one screen pixel, so art
// stays crisp when magnified and anti-aliased (rather than jagged) at fractional or shrunk scales. Use
// with linear filtering; mipmaps keep shrunk art clean.

varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

void fragment() {
	vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 texel = UV * texture_size;
	vec2 texels_per_pixel = max(fwidth(texel), vec2(1e-4));
	vec2 seam = floor(texel + 0.5);
	// Snap to the texel centre except within half a screen pixel of a texel edge.
	vec2 smooth_texel = seam + clamp((texel - seam) / max(texels_per_pixel, vec2(1.0)), -0.5, 0.5);
	vec2 smooth_uv = smooth_texel / texture_size;
	COLOR = textureGrad(TEXTURE, smooth_uv, dFdx(UV), dFdy(UV)) * vertex_color;
}
