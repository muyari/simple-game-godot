extends Wolf


func _ready() -> void:
	max_health = Wolf.MAX_HEALTH * 1.25
	attack_damage = roundi(Wolf.ATTACK_DAMAGE * 1.5)
	super._ready()
