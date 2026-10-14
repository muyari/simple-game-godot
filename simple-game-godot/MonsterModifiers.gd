extends RefCounted
class_name MonsterModifiers

## Central, data-driven list of random monster modifiers.
##
## To add a modifier, add an entry to DEFINITIONS. Each entry has:
##   "name"   - label shown above the monster.
##   "weight" - relative chance of being picked when rolling.
##   "stats"  - stat keys below mapped to values. When a monster has several
##              modifiers, their stats are added together.
## New behaviour only needs code when it can't be expressed with existing stats;
## add a stat key here and read it from Wolf via get_stat().

## +fraction of max HP.
const STAT_MAX_HEALTH := "max_health_bonus"
## +fraction of outgoing damage.
const STAT_DAMAGE := "damage_bonus"
## +fraction of movement speed and attack speed.
const STAT_SPEED := "speed_bonus"
## Fraction of max HP healed per second.
const STAT_REGEN := "regen_per_second"
## Fraction of incoming damage ignored. Enemy damage has no types yet, so this covers all hits.
const STAT_DAMAGE_REDUCTION := "damage_reduction"
## Chance (0-1) to ignore an incoming hit.
const STAT_DODGE := "dodge_chance"
## Fraction of damage taken sent back to the player, scaled from the monster's HP to the player's HP.
const STAT_REFLECT := "reflect_fraction"
## Fraction of the monster's max HP healed whenever it hits the player.
const STAT_LIFESTEAL := "lifesteal_fraction"
## +fraction of gold dropped.
const STAT_GOLD := "gold_bonus"
## Guaranteed extra item drops.
const STAT_EXTRA_ITEMS := "extra_item_drops"
## Aura stats apply to other monsters within STAT_AURA_RADIUS. Overlapping auras don't stack;
## each monster takes the strongest value of each aura stat around it.
const STAT_AURA_RADIUS := "aura_radius"
const STAT_AURA_DAMAGE := "aura_damage_bonus"
const STAT_AURA_SPEED := "aura_speed_bonus"
const STAT_AURA_DAMAGE_REDUCTION := "aura_damage_reduction"

const AURA_STATS: Array[String] = [STAT_AURA_DAMAGE, STAT_AURA_SPEED, STAT_AURA_DAMAGE_REDUCTION]
## Caps so stacked modifiers and auras can't make a monster untouchable.
const MAX_DAMAGE_REDUCTION := 0.75
const MAX_DODGE_CHANCE := 0.6

const DEFINITIONS := {
	"extra_health": {
		"name": "Extra Health",
		"weight": 10,
		"stats": {STAT_MAX_HEALTH: 0.6}
	},
	"extra_damage": {
		"name": "Extra Damage",
		"weight": 10,
		"stats": {STAT_DAMAGE: 0.35}
	},
	"extra_speed": {
		"name": "Extra Speed",
		"weight": 10,
		"stats": {STAT_SPEED: 0.3}
	},
	"regenerating": {
		"name": "Regenerating",
		"weight": 8,
		"stats": {STAT_REGEN: 0.04}
	},
	"commander": {
		"name": "Commander",
		"weight": 5,
		"stats": {STAT_AURA_RADIUS: 280.0, STAT_AURA_DAMAGE: 0.15, STAT_AURA_DAMAGE_REDUCTION: 0.15}
	},
	"pack_leader": {
		"name": "Pack Leader",
		"weight": 5,
		"stats": {STAT_AURA_RADIUS: 280.0, STAT_AURA_SPEED: 0.2, STAT_AURA_DAMAGE: 0.2}
	},
	"treasure_bound": {
		"name": "Treasure Bound",
		"weight": 6,
		"stats": {STAT_GOLD: 2.0}
	},
	"hoarder": {
		"name": "Hoarder",
		"weight": 6,
		"stats": {STAT_EXTRA_ITEMS: 1}
	},
	"reflective": {
		"name": "Reflective",
		"weight": 7,
		"stats": {STAT_REFLECT: 0.15}
	},
	"evasive": {
		"name": "Evasive",
		"weight": 8,
		"stats": {STAT_DODGE: 0.25}
	},
	"armored": {
		"name": "Armored",
		"weight": 8,
		"stats": {STAT_DAMAGE_REDUCTION: 0.3}
	},
	"vampiric": {
		"name": "Vampiric",
		"weight": 7,
		"stats": {STAT_LIFESTEAL: 0.12}
	},
}

## Chance that a spawned monster rolls any modifiers, rising with area level.
const BASE_MODIFIER_CHANCE := 0.2
const MODIFIER_CHANCE_PER_AREA_LEVEL := 0.08
const MAX_MODIFIER_CHANCE := 0.6
## Each extra modifier beyond the first is rolled with this chance, up to the area's cap.
const EXTRA_MODIFIER_CHANCE := 0.35
const AREA_LEVELS_PER_EXTRA_MODIFIER := 2
const MAX_MODIFIERS := 3
## Modified monsters are tougher, so they grant more experience per modifier.
const EXPERIENCE_BONUS_PER_MODIFIER := 0.25


## Rolls a random set of distinct modifier ids for a monster spawning in the given area.
static func roll(random: RandomNumberGenerator, area_level: int) -> Array[String]:
	var rolled: Array[String] = []
	var level_steps := maxi(area_level - 1, 0)
	var chance := minf(BASE_MODIFIER_CHANCE + MODIFIER_CHANCE_PER_AREA_LEVEL * level_steps, MAX_MODIFIER_CHANCE)
	if random.randf() >= chance:
		return rolled

	var max_count := mini(1 + level_steps / AREA_LEVELS_PER_EXTRA_MODIFIER, MAX_MODIFIERS)
	var candidates: Array = DEFINITIONS.keys()
	while rolled.size() < max_count and not candidates.is_empty():
		if not rolled.is_empty() and random.randf() >= EXTRA_MODIFIER_CHANCE:
			break
		var picked := _pick_weighted(random, candidates)
		rolled.append(picked)
		candidates.erase(picked)
	return rolled


## Adds together the stats of every known modifier id. Unknown ids are reported and skipped.
static func combine_stats(modifier_ids: Array[String]) -> Dictionary:
	var totals := {}
	for modifier_id in modifier_ids:
		if not DEFINITIONS.has(modifier_id):
			push_error("Unknown monster modifier '%s'." % modifier_id)
			continue
		var stats: Dictionary = DEFINITIONS[modifier_id]["stats"]
		for stat in stats:
			totals[stat] = float(totals.get(stat, 0.0)) + float(stats[stat])
	return totals


static func get_display_name(modifier_id: String) -> String:
	if not DEFINITIONS.has(modifier_id):
		return modifier_id
	return str(DEFINITIONS[modifier_id]["name"])


## Returns only the ids that exist in DEFINITIONS, for loading saved data safely.
static func sanitize(raw_ids: Variant) -> Array[String]:
	var valid: Array[String] = []
	if typeof(raw_ids) != TYPE_ARRAY:
		return valid
	for raw_id in raw_ids:
		var modifier_id := str(raw_id)
		if DEFINITIONS.has(modifier_id) and not valid.has(modifier_id):
			valid.append(modifier_id)
	return valid


static func _pick_weighted(random: RandomNumberGenerator, candidates: Array) -> String:
	var total_weight := 0.0
	for modifier_id in candidates:
		total_weight += float(DEFINITIONS[modifier_id]["weight"])
	var roll_value := random.randf() * total_weight
	for modifier_id in candidates:
		roll_value -= float(DEFINITIONS[modifier_id]["weight"])
		if roll_value < 0.0:
			return str(modifier_id)
	return str(candidates.back())
