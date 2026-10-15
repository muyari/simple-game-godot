extends RefCounted
class_name SunShadow
## Soft warm shadows cast on the desert sand by props and creatures. The sun sits high to the upper right,
## so each shadow is a flattened ellipse nudged down and to the left of the object's base.

const COLOR := Color(0.36, 0.18, 0.05, 0.46)
const TEXTURE_SIZE := Vector2i(64, 24)

static var _texture: ImageTexture


## Adds a shadow under `parent`, centred on `base` (parent-local) and `width` local pixels wide.
## With `behind_parent` it draws under the parent itself (for sprites); otherwise it is added as the
## parent's first child so it draws under the parent's other children (for creatures).
static func attach(parent: Node2D, base: Vector2, width: float, behind_parent := true) -> Sprite2D:
	var shadow := Sprite2D.new()
	shadow.name = "SunShadow"
	shadow.texture = _get_texture()
	shadow.show_behind_parent = behind_parent
	shadow.position = base + Vector2(-width * 0.1, width * 0.04)
	shadow.scale = Vector2(width, width * 0.32) / Vector2(TEXTURE_SIZE)
	parent.add_child(shadow)
	if not behind_parent:
		parent.move_child(shadow, 0)
	return shadow


static func _get_texture() -> ImageTexture:
	if _texture != null:
		return _texture
	var image := Image.create_empty(TEXTURE_SIZE.x, TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	var half := Vector2(TEXTURE_SIZE) * 0.5
	for y in TEXTURE_SIZE.y:
		for x in TEXTURE_SIZE.x:
			var distance := ((Vector2(x, y) + Vector2(0.5, 0.5) - half) / half).length()
			if distance < 1.0:
				# Dense core fading to a soft rim.
				var alpha := COLOR.a * (1.0 - smoothstep(0.45, 1.0, distance))
				image.set_pixel(x, y, Color(COLOR.r, COLOR.g, COLOR.b, alpha))
	_texture = ImageTexture.create_from_image(image)
	return _texture
