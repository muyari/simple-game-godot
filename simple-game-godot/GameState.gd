extends Node

signal gold_changed(total_gold: int)
signal progression_changed(level: int, experience: int, xp_into_level: int, xp_for_level: int, passive_points: int, skill_points: int)
signal experience_gained(amount: int)
signal player_leveled_up(level: int)

const SAVE_PATH = "user://character_save.json"
const SAVE_VERSION = 8
const ROSTER_PATH = "user://character_roster.json"
const ROSTER_VERSION = 1
const SCENE_FADE_OUT_TIME = 0.22
const SCENE_FADE_IN_TIME = 0.35
const LEVEL_NAMES = {
	1: "Forest Outskirts",
	2: "Sunscorch Sands",
	3: "The Ice Caves",
	4: "The Underworld",
	5: "Random Map",
}
const LEVEL_SCENES = {
	"res://main.tscn": 1,
	"res://desert.tscn": 2,
	"res://ice_caves.tscn": 3,
	"res://underworld.tscn": 4,
	"res://endgame_map.tscn": 5,
}
## The endgame: once the campaign is cleared, the waystones open random maps. Each run lays out one of
## the four regions (picked at random), fills it with monsters from every region and ends with any of
## their bosses. Its state saves under this level id like a campaign level's.
const ENDGAME_LEVEL_ID := 5
const ENDGAME_SCENE := "res://endgame_map.tscn"
## Difficulty tiers for random maps. health and damage multiply every monster's stats, extra_monsters
## are added to the layout's usual tally before the boss, and experience multiplies every XP reward.
const ENDGAME_TIERS := {
	1: {"name": "1x", "health": 1.5, "damage": 1.2, "extra_monsters": 4, "experience": 1.5},
	2: {"name": "2x", "health": 2.25, "damage": 1.45, "extra_monsters": 8, "experience": 2.0},
	3: {"name": "3x", "health": 3.0, "damage": 1.75, "extra_monsters": 12, "experience": 3.0},
}
## Each region's staging hub, keyed by level id. Town portals and "Return to Town" lead to the hub of the
## level they're used in, and the waystones travel between hubs.
## arrival: where the player appears; entrance: where the way into the level stands.
const HUBS = {
	1: {
		"name": "Oblath", "scene": "res://town.tscn",
		"arrival": Vector2(576, 300),
	},
	2: {
		"name": "Saltwind Camp", "scene": "res://desert_camp.tscn",
		"arrival": Vector2(600, 420),
	},
	3: {
		"name": "Rimehollow", "scene": "res://ice_settlement.tscn",
		"arrival": Vector2(600, 440),
	},
	4: {
		"name": "Ashgate Outpost", "scene": "res://besieged_outpost.tscn",
		"arrival": Vector2(560, 560),
	},
}
## Where a level starts when entered from its hub.
const LEVEL_START_POSITION := Vector2(84, 574)
const LEVEL_SCENE_PATHS = {
	1: "res://main.tscn",
	2: "res://desert.tscn",
	3: "res://ice_caves.tscn",
	4: "res://underworld.tscn",
}
const WITCH_SKILL_ORDER = [
	"firebolt",
	"frost_nova",
	"summon_wisp",
	"soul_siphon",
	"arcane_shield",
	"curse"
]
const WITCH_SKILL_TREE = {
	"firebolt": {
		"name": "Firebolt",
		"short_label": "FIRE",
		"icon_path": "res://textures/skills/firebolt.svg",
		"branch": "Elemental",
		"description": "Launch a focused flame bolt at the nearest foe. Each rank increases damage.",
		"max_rank": 3,
		"point_cost": 1,
		"required_level": 1,
		"prerequisites": [],
		"mana_cost": 12,
		"cooldown": 0.8
	},
	"frost_nova": {
		"name": "Frost Nova",
		"short_label": "NOVA",
		"icon_path": "res://textures/skills/frost_nova.svg",
		"branch": "Elemental",
		"description": "Burst freezing magic around you, damaging and briefly stunning nearby enemies.",
		"max_rank": 3,
		"point_cost": 1,
		"required_level": 2,
		"prerequisites": [],
		"mana_cost": 28,
		"cooldown": 7.0
	},
	"summon_wisp": {
		"name": "Summon Wisp",
		"short_label": "WISP",
		"icon_path": "res://textures/skills/summon_wisp.svg",
		"branch": "Summoner",
		"description": "Call a spirit wisp that follows you and attacks nearby enemies for a short time.",
		"max_rank": 3,
		"point_cost": 1,
		"required_level": 2,
		"prerequisites": [],
		"mana_cost": 32,
		"cooldown": 16.0
	},
	"soul_siphon": {
		"name": "Soul Siphon",
		"short_label": "SIPHON",
		"icon_path": "res://textures/skills/soul_siphon.svg",
		"branch": "Summoner",
		"description": "Drain a nearby enemy to restore health and mana. Higher ranks improve the drain.",
		"max_rank": 3,
		"point_cost": 1,
		"required_level": 4,
		"prerequisites": [],
		"mana_cost": 20,
		"cooldown": 10.0
	},
	"arcane_shield": {
		"name": "Arcane Shield",
		"short_label": "SHIELD",
		"icon_path": "res://textures/skills/arcane_shield.svg",
		"branch": "Support",
		"description": "Wrap yourself in a ward that absorbs most incoming damage for four seconds.",
		"max_rank": 3,
		"point_cost": 1,
		"required_level": 2,
		"prerequisites": [],
		"mana_cost": 26,
		"cooldown": 14.0
	},
	"curse": {
		"name": "Curse",
		"short_label": "CURSE",
		"icon_path": "res://textures/skills/curse.svg",
		"branch": "Support",
		"description": "Curse the nearest enemy, making it vulnerable to your attacks for six seconds.",
		"max_rank": 3,
		"point_cost": 1,
		"required_level": 4,
		"prerequisites": [],
		"mana_cost": 18,
		"cooldown": 12.0
	}
}
const WITCH_SKILL_SLOTS = ["Q", "W", "E", "R"]
const WARRIOR_SKILL_ORDER: Array[String] = [
	"heavy_strike",
	"shield_bash",
	"cleave",
	"leap_slam",
	"war_cry",
	"iron_resolve"
]
const WARRIOR_SKILL_TREE := {
	"heavy_strike": {
		"name": "Heavy Strike",
		"short_label": "HEAVY",
		"icon_path": "res://textures/warrior_skills/heavy_strike.svg",
		"branch": "Single Target",
		"description": "Deliver a crushing blow to the foe in front of you. Each rank increases damage.",
		"max_rank": 3,
		"point_cost": 1,
		"required_level": 1,
		"prerequisites": [],
		"mana_cost": 0,
		"cooldown": 1.2,
		"position": [1, 0]
	},
	"shield_bash": {
		"name": "Shield Bash",
		"short_label": "BASH",
		"icon_path": "res://textures/warrior_skills/shield_bash.svg",
		"branch": "Single Target",
		"description": "Bash the foe ahead, dealing damage and briefly stunning it.",
		"max_rank": 3,
		"point_cost": 1,
		"required_level": 3,
		"prerequisites": ["heavy_strike"],
		"mana_cost": 8,
		"cooldown": 7.0,
		"position": [1, 1]
	},
	"cleave": {
		"name": "Cleave",
		"short_label": "CLEAVE",
		"icon_path": "res://textures/warrior_skills/cleave.svg",
		"branch": "Area",
		"description": "Sweep your weapon through nearby enemies. Each rank increases damage and reach.",
		"max_rank": 3,
		"point_cost": 1,
		"required_level": 2,
		"prerequisites": [],
		"mana_cost": 10,
		"cooldown": 5.0,
		"position": [3, 0]
	},
	"leap_slam": {
		"name": "Leap Slam",
		"short_label": "LEAP",
		"icon_path": "res://textures/warrior_skills/leap_slam.svg",
		"branch": "Area",
		"description": "Leap toward the nearest foe and slam the ground, damaging and stunning nearby enemies.",
		"max_rank": 3,
		"point_cost": 1,
		"required_level": 5,
		"prerequisites": ["cleave"],
		"mana_cost": 16,
		"cooldown": 10.0,
		"position": [3, 1]
	},
	"war_cry": {
		"name": "War Cry",
		"short_label": "CRY",
		"icon_path": "res://textures/warrior_skills/war_cry.svg",
		"branch": "Support",
		"description": "Roar with resolve, empowering your attacks and reducing incoming damage.",
		"max_rank": 3,
		"point_cost": 1,
		"required_level": 2,
		"prerequisites": [],
		"mana_cost": 12,
		"cooldown": 12.0,
		"position": [4, 0]
	},
	"iron_resolve": {
		"name": "Iron Resolve",
		"short_label": "IRON",
		"icon_path": "res://textures/warrior_skills/iron_resolve.svg",
		"branch": "Support",
		"description": "Brace yourself, gaining a stronger guard and restoring health over time.",
		"max_rank": 3,
		"point_cost": 1,
		"required_level": 5,
		"prerequisites": ["war_cry"],
		"mana_cost": 18,
		"cooldown": 18.0,
		"position": [4, 1]
	}
}
const WARRIOR_SKILL_SLOTS: Array[String] = ["Q", "W", "E", "R"]

const RANGER_SKILL_ORDER: Array[String] = [
	"power_shot", "multi_shot", "explosive_arrow", "smoke_bomb"
]
const RANGER_SKILL_TREE: Dictionary = {
	"power_shot": {
		"name": "Power Shot",
		"short_label": "POWER",
		"icon_path": "res://textures/ranger_skills/power_shot.svg",
		"branch": "Precision",
		"description": "Fire a hard-hitting arrow that pierces through more foes with each rank.",
		"max_rank": 3, "point_cost": 1, "required_level": 1, "prerequisites": [],
		"mana_cost": 6, "cooldown": 2.5, "position": [1, 0]
	},
	"multi_shot": {
		"name": "Multi-Shot",
		"short_label": "VOLLEY",
		"icon_path": "res://textures/ranger_skills/multi_shot.svg",
		"branch": "Volley",
		"description": "Loose three arrows in a fan to strike a cluster of enemies.",
		"max_rank": 3, "point_cost": 1, "required_level": 2, "prerequisites": ["power_shot"],
		"mana_cost": 14, "cooldown": 5.0, "position": [3, 0]
	},
	"explosive_arrow": {
		"name": "Explosive Arrow",
		"short_label": "BLAST",
		"icon_path": "res://textures/ranger_skills/explosive_arrow.svg",
		"branch": "Control",
		"description": "Detonate an arrow on impact, damaging enemies around its target.",
		"max_rank": 3, "point_cost": 1, "required_level": 4, "prerequisites": ["power_shot"],
		"mana_cost": 18, "cooldown": 7.0, "position": [1, 1]
	},
	"smoke_bomb": {
		"name": "Smoke Bomb",
		"short_label": "SMOKE",
		"icon_path": "res://textures/ranger_skills/smoke_bomb.svg",
		"branch": "Mobility",
		"description": "Burst into smoke, staggering nearby enemies so you can reposition.",
		"max_rank": 3, "point_cost": 1, "required_level": 2, "prerequisites": [],
		"mana_cost": 16, "cooldown": 12.0, "position": [4, 0]
	}
}
const RANGER_SKILL_SLOTS: Array[String] = ["Q", "W", "E", "R"]

const WARRIOR_PASSIVE_ORDER: Array[String] = [
	"iron_vitality", "reinforced_armor", "steadfast_guard", "unyielding", "colossus",
	"battle_training", "enduring_stamina", "heavy_hands", "combat_veteran", "warbringer",
	"precise_strikes", "weapon_mastery", "savage_force", "executioner", "warlord"
]

const WARRIOR_PASSIVE_TREE: Dictionary = {
	"iron_vitality": {
		"name": "Iron Vitality", "branch": "Tank",
		"description": "Gain +12 maximum health.",
		"is_super": false, "point_cost": 1, "required_level": 1, "prerequisites": [],
		"stats": {"max_health": 12}, "x": 0, "y": 0
	},
	"reinforced_armor": {
		"name": "Reinforced Armor", "branch": "Tank",
		"description": "Gain +1 flat damage reduction from armor.",
		"is_super": false, "point_cost": 1, "required_level": 2, "prerequisites": ["iron_vitality"],
		"stats": {"armor": 1}, "x": 0, "y": 1
	},
	"steadfast_guard": {
		"name": "Steadfast Guard", "branch": "Tank",
		"description": "Reduce incoming damage by 2%.",
		"is_super": false, "point_cost": 1, "required_level": 4, "prerequisites": ["reinforced_armor"],
		"stats": {"damage_reduction_percent": 0.02}, "x": 0, "y": 2
	},
	"unyielding": {
		"name": "Unyielding", "branch": "Tank",
		"description": "Gain +20 maximum health.",
		"is_super": false, "point_cost": 1, "required_level": 6, "prerequisites": ["steadfast_guard"],
		"stats": {"max_health": 20}, "x": 0, "y": 3
	},
	"colossus": {
		"name": "Colossus", "branch": "Tank",
		"description": "Gain +25 maximum health and 3% damage reduction.",
		"is_super": true, "point_cost": 2, "required_level": 10, "prerequisites": ["unyielding"],
		"stats": {"max_health": 25, "damage_reduction_percent": 0.03}, "x": 0, "y": 4
	},
	"battle_training": {
		"name": "Battle Training", "branch": "Bruiser",
		"description": "Gain +1 weapon damage.",
		"is_super": false, "point_cost": 1, "required_level": 1, "prerequisites": [],
		"stats": {"weapon_damage_bonus": 1}, "x": 2, "y": 0
	},
	"enduring_stamina": {
		"name": "Enduring Stamina", "branch": "Bruiser",
		"description": "Gain +10 maximum mana for Warrior skills.",
		"is_super": false, "point_cost": 1, "required_level": 2, "prerequisites": ["battle_training"],
		"stats": {"max_mana": 10}, "x": 2, "y": 1
	},
	"heavy_hands": {
		"name": "Heavy Hands", "branch": "Bruiser",
		"description": "Gain +2 weapon damage.",
		"is_super": false, "point_cost": 1, "required_level": 4, "prerequisites": ["enduring_stamina"],
		"stats": {"weapon_damage_bonus": 2}, "x": 2, "y": 2
	},
	"combat_veteran": {
		"name": "Combat Veteran", "branch": "Bruiser",
		"description": "Gain +15 maximum health and +5 maximum mana.",
		"is_super": false, "point_cost": 1, "required_level": 6, "prerequisites": ["heavy_hands"],
		"stats": {"max_health": 15, "max_mana": 5}, "x": 2, "y": 3
	},
	"warbringer": {
		"name": "Warbringer", "branch": "Bruiser",
		"description": "Gain +3 weapon damage.",
		"is_super": true, "point_cost": 2, "required_level": 10, "prerequisites": ["combat_veteran"],
		"stats": {"weapon_damage_bonus": 3}, "x": 2, "y": 4
	},
	"precise_strikes": {
		"name": "Precise Strikes", "branch": "Slayer",
		"description": "Gain +2 weapon damage.",
		"is_super": false, "point_cost": 1, "required_level": 1, "prerequisites": [],
		"stats": {"weapon_damage_bonus": 2}, "x": 4, "y": 0
	},
	"weapon_mastery": {
		"name": "Weapon Mastery", "branch": "Slayer",
		"description": "Gain +2 weapon damage.",
		"is_super": false, "point_cost": 1, "required_level": 2, "prerequisites": ["precise_strikes"],
		"stats": {"weapon_damage_bonus": 2}, "x": 4, "y": 1
	},
	"savage_force": {
		"name": "Savage Force", "branch": "Slayer",
		"description": "Gain +20 maximum health and +1 weapon damage.",
		"is_super": false, "point_cost": 1, "required_level": 4, "prerequisites": ["weapon_mastery"],
		"stats": {"max_health": 20, "weapon_damage_bonus": 1}, "x": 4, "y": 2
	},
	"executioner": {
		"name": "Executioner", "branch": "Slayer",
		"description": "Gain +3 weapon damage.",
		"is_super": false, "point_cost": 1, "required_level": 6, "prerequisites": ["savage_force"],
		"stats": {"weapon_damage_bonus": 3}, "x": 4, "y": 3
	},
	"warlord": {
		"name": "Warlord", "branch": "Slayer",
		"description": "Gain +4 weapon damage and +10 maximum health.",
		"is_super": true, "point_cost": 2, "required_level": 10, "prerequisites": ["executioner"],
		"stats": {"weapon_damage_bonus": 4, "max_health": 10}, "x": 4, "y": 4
	}
}

const WITCH_PASSIVE_ORDER: Array[String] = [
	# Spire of Arcana (Elemental)
	"arcane_spark",
	"ember_mastery",
	"frost_affinity",
	"spell_weaver",
	"elemental_overload",
	"ignited_fury",
	"glacial_focus",
	"super_archmages_nexus",
	# Shadow & Siphon (Occult)
	"soul_tether",
	"essence_siphon",
	"shadow_mend",
	"vital_surge",
	"decay_aura",
	"dark_harvest",
	"spirit_channel",
	"super_void_ascendancy",
	# Aegis of Phantoms (Defense)
	"mist_shroud",
	"phantom_step",
	"warding_veil",
	"evasive_reflex",
	"iron_will",
	"hardened_skin",
	"ethereal_flow",
	"super_spectral_bastion",
	# Mystic Wellspring (Mana & Utility)
	"mana_reservoir",
	"inner_trance",
	"crystal_clarity",
	"sorcerers_cunning",
	"spell_flux",
	"abyssal_reserves",
	"arcane_shielding",
	"super_infinite_conduit",
	# Astral Convergence (Apex)
	"celestial_attunement",
	"super_celestial_sovereign"
]

const WITCH_PASSIVE_TREE: Dictionary = {
	# --- Spire of Arcana (Elemental) ---
	"arcane_spark": {
		"name": "Arcane Spark",
		"branch": "Spire of Arcana",
		"description": "Increases spell damage by +4%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 1,
		"prerequisites": [],
		"stats": {"spell_damage_percent": 0.04},
		"x": 2, "y": 0
	},
	"ember_mastery": {
		"name": "Ember Mastery",
		"branch": "Spire of Arcana",
		"description": "Increases spell damage by +4%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 2,
		"prerequisites": ["arcane_spark"],
		"stats": {"spell_damage_percent": 0.04},
		"x": 1, "y": 1
	},
	"frost_affinity": {
		"name": "Frost Affinity",
		"branch": "Spire of Arcana",
		"description": "Increases spell damage by +4%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 2,
		"prerequisites": ["arcane_spark"],
		"stats": {"spell_damage_percent": 0.04},
		"x": 3, "y": 1
	},
	"spell_weaver": {
		"name": "Spell Weaver",
		"branch": "Spire of Arcana",
		"description": "Increases spell damage by +5%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 4,
		"prerequisites": ["ember_mastery", "frost_affinity"],
		"stats": {"spell_damage_percent": 0.05},
		"x": 2, "y": 2
	},
	"elemental_overload": {
		"name": "Elemental Overload",
		"branch": "Spire of Arcana",
		"description": "Increases spell damage by +5%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 6,
		"prerequisites": ["spell_weaver"],
		"stats": {"spell_damage_percent": 0.05},
		"x": 2, "y": 3
	},
	"ignited_fury": {
		"name": "Ignited Fury",
		"branch": "Spire of Arcana",
		"description": "Increases spell damage by +5%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 8,
		"prerequisites": ["elemental_overload"],
		"stats": {"spell_damage_percent": 0.05},
		"x": 1, "y": 4
	},
	"glacial_focus": {
		"name": "Glacial Focus",
		"branch": "Spire of Arcana",
		"description": "Increases spell damage by +5%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 8,
		"prerequisites": ["elemental_overload"],
		"stats": {"spell_damage_percent": 0.05},
		"x": 3, "y": 4
	},
	"super_archmages_nexus": {
		"name": "Archmage's Nexus",
		"branch": "Spire of Arcana",
		"description": "Super Node: Enhances destructive prowess and evasion.\nGrants +12% spell damage and +6% evasion.",
		"is_super": true,
		"point_cost": 1,
		"required_level": 10,
		"prerequisites": ["ignited_fury", "glacial_focus"],
		"stats": {"spell_damage_percent": 0.12, "evasion": 0.06},
		"x": 2, "y": 5
	},

	# --- Shadow & Siphon (Occult) ---
	"soul_tether": {
		"name": "Soul Tether",
		"branch": "Shadow & Siphon",
		"description": "Increases maximum health by +15.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 1,
		"prerequisites": [],
		"stats": {"max_health": 15},
		"x": 0, "y": 2
	},
	"essence_siphon": {
		"name": "Essence Siphon",
		"branch": "Shadow & Siphon",
		"description": "Increases maximum health by +15.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 3,
		"prerequisites": ["soul_tether"],
		"stats": {"max_health": 15},
		"x": 0, "y": 3
	},
	"shadow_mend": {
		"name": "Shadow Mend",
		"branch": "Shadow & Siphon",
		"description": "Increases maximum health by +20.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 5,
		"prerequisites": ["essence_siphon"],
		"stats": {"max_health": 20},
		"x": 0, "y": 4
	},
	"vital_surge": {
		"name": "Vital Surge",
		"branch": "Shadow & Siphon",
		"description": "Increases maximum health by +20.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 7,
		"prerequisites": ["shadow_mend"],
		"stats": {"max_health": 20},
		"x": 0, "y": 5
	},
	"decay_aura": {
		"name": "Decay Aura",
		"branch": "Shadow & Siphon",
		"description": "Increases spell damage by +4%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 8,
		"prerequisites": ["vital_surge"],
		"stats": {"spell_damage_percent": 0.04},
		"x": 0, "y": 6
	},
	"dark_harvest": {
		"name": "Dark Harvest",
		"branch": "Shadow & Siphon",
		"description": "Reduces damage taken by 3%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 9,
		"prerequisites": ["vital_surge"],
		"stats": {"damage_reduction_percent": 0.03},
		"x": 1, "y": 6
	},
	"spirit_channel": {
		"name": "Spirit Channel",
		"branch": "Shadow & Siphon",
		"description": "Increases maximum health by +20.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 10,
		"prerequisites": ["decay_aura", "dark_harvest"],
		"stats": {"max_health": 20},
		"x": 0, "y": 7
	},
	"super_void_ascendancy": {
		"name": "Void Ascendancy",
		"branch": "Shadow & Siphon",
		"description": "Super Node: Merges life-force with eldritch defense.\nGrants +45 maximum health and 5% less damage taken.",
		"is_super": true,
		"point_cost": 1,
		"required_level": 12,
		"prerequisites": ["spirit_channel"],
		"stats": {"max_health": 45, "damage_reduction_percent": 0.05},
		"x": 0, "y": 8
	},

	# --- Aegis of Phantoms (Defense) ---
	"mist_shroud": {
		"name": "Mist Shroud",
		"branch": "Aegis of Phantoms",
		"description": "Increases evasion by +4%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 1,
		"prerequisites": [],
		"stats": {"evasion": 0.04},
		"x": 4, "y": 2
	},
	"phantom_step": {
		"name": "Phantom Step",
		"branch": "Aegis of Phantoms",
		"description": "Increases evasion by +4%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 3,
		"prerequisites": ["mist_shroud"],
		"stats": {"evasion": 0.04},
		"x": 4, "y": 3
	},
	"warding_veil": {
		"name": "Warding Veil",
		"branch": "Aegis of Phantoms",
		"description": "Reduces damage taken by 3%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 5,
		"prerequisites": ["phantom_step"],
		"stats": {"damage_reduction_percent": 0.03},
		"x": 4, "y": 4
	},
	"evasive_reflex": {
		"name": "Evasive Reflex",
		"branch": "Aegis of Phantoms",
		"description": "Increases evasion by +5%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 7,
		"prerequisites": ["warding_veil"],
		"stats": {"evasion": 0.05},
		"x": 4, "y": 5
	},
	"iron_will": {
		"name": "Iron Will",
		"branch": "Aegis of Phantoms",
		"description": "Reduces damage taken by 3%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 8,
		"prerequisites": ["evasive_reflex"],
		"stats": {"damage_reduction_percent": 0.03},
		"x": 3, "y": 6
	},
	"hardened_skin": {
		"name": "Hardened Skin",
		"branch": "Aegis of Phantoms",
		"description": "Reduces damage taken by 3%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 8,
		"prerequisites": ["evasive_reflex"],
		"stats": {"damage_reduction_percent": 0.03},
		"x": 4, "y": 6
	},
	"ethereal_flow": {
		"name": "Ethereal Flow",
		"branch": "Aegis of Phantoms",
		"description": "Increases evasion by +5%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 10,
		"prerequisites": ["iron_will", "hardened_skin"],
		"stats": {"evasion": 0.05},
		"x": 4, "y": 7
	},
	"super_spectral_bastion": {
		"name": "Spectral Bastion",
		"branch": "Aegis of Phantoms",
		"description": "Super Node: Weaves phantasmal wards around your form.\nGrants +6% evasion and 6% less damage taken.",
		"is_super": true,
		"point_cost": 1,
		"required_level": 12,
		"prerequisites": ["ethereal_flow"],
		"stats": {"evasion": 0.06, "damage_reduction_percent": 0.06},
		"x": 4, "y": 8
	},

	# --- Mystic Wellspring (Mana & Utility) ---
	"mana_reservoir": {
		"name": "Mana Reservoir",
		"branch": "Mystic Wellspring",
		"description": "Increases maximum mana by +20.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 1,
		"prerequisites": [],
		"stats": {"max_mana": 20},
		"x": 2, "y": 6
	},
	"inner_trance": {
		"name": "Inner Trance",
		"branch": "Mystic Wellspring",
		"description": "Increases maximum mana by +20.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 3,
		"prerequisites": ["mana_reservoir"],
		"stats": {"max_mana": 20},
		"x": 2, "y": 7
	},
	"crystal_clarity": {
		"name": "Crystal Clarity",
		"branch": "Mystic Wellspring",
		"description": "Increases maximum mana by +25.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 5,
		"prerequisites": ["inner_trance"],
		"stats": {"max_mana": 25},
		"x": 2, "y": 8
	},
	"sorcerers_cunning": {
		"name": "Sorcerer's Cunning",
		"branch": "Mystic Wellspring",
		"description": "Increases spell damage by +4%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 7,
		"prerequisites": ["crystal_clarity"],
		"stats": {"spell_damage_percent": 0.04},
		"x": 1, "y": 9
	},
	"spell_flux": {
		"name": "Spell Flux",
		"branch": "Mystic Wellspring",
		"description": "Increases spell damage by +4%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 7,
		"prerequisites": ["crystal_clarity"],
		"stats": {"spell_damage_percent": 0.04},
		"x": 3, "y": 9
	},
	"abyssal_reserves": {
		"name": "Abyssal Reserves",
		"branch": "Mystic Wellspring",
		"description": "Increases maximum mana by +25.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 9,
		"prerequisites": ["sorcerers_cunning", "spell_flux"],
		"stats": {"max_mana": 25},
		"x": 2, "y": 10
	},
	"arcane_shielding": {
		"name": "Arcane Shielding",
		"branch": "Mystic Wellspring",
		"description": "Reduces damage taken by 3%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 11,
		"prerequisites": ["abyssal_reserves"],
		"stats": {"damage_reduction_percent": 0.03},
		"x": 2, "y": 11
	},
	"super_infinite_conduit": {
		"name": "Infinite Conduit",
		"branch": "Mystic Wellspring",
		"description": "Super Node: Floods your mind with infinite magical potential.\nGrants +50 maximum mana and +8% spell damage.",
		"is_super": true,
		"point_cost": 1,
		"required_level": 13,
		"prerequisites": ["arcane_shielding"],
		"stats": {"max_mana": 50, "spell_damage_percent": 0.08},
		"x": 2, "y": 12
	},

	# --- Astral Convergence (Apex) ---
	"celestial_attunement": {
		"name": "Celestial Attunement",
		"branch": "Astral Convergence",
		"description": "Increases spell damage by +5%.",
		"is_super": false,
		"point_cost": 1,
		"required_level": 14,
		"prerequisites": ["super_archmages_nexus", "super_infinite_conduit"],
		"stats": {"spell_damage_percent": 0.05},
		"x": 2, "y": 13
	},
	"super_celestial_sovereign": {
		"name": "Celestial Sovereign",
		"branch": "Astral Convergence",
		"description": "Super Node: Master of heavens, fate, and cosmic arcana.\nGrants +10% spell damage, +30 maximum health, +30 maximum mana, and +5% evasion.",
		"is_super": true,
		"point_cost": 1,
		"required_level": 16,
		"prerequisites": ["celestial_attunement", "super_void_ascendancy", "super_spectral_bastion"],
		"stats": {
			"spell_damage_percent": 0.10,
			"max_health": 30,
			"max_mana": 30,
			"evasion": 0.05
		},
		"x": 2, "y": 14
	}
}

const RANGER_PASSIVE_ORDER: Array[String] = [
	"keen_sight", "steady_aim", "critical_focus", "deadly_precision", "eagles_eye",
	"quickstep", "light_footed", "windrunner", "evasive_reflex", "wind_dancer",
	"trapcraft", "volatile_payload", "efficient_fletching", "field_rations", "master_trapper"
]
const RANGER_PASSIVE_TREE: Dictionary = {
	"keen_sight": {
		"name": "Keen Sight", "branch": "Precision",
		"description": "Improve arrow accuracy by 10%, widening your hit margin and range.",
		"is_super": false, "point_cost": 1, "required_level": 1, "prerequisites": [],
		"stats": {"accuracy": 0.10}, "x": 0, "y": 0
	},
	"steady_aim": {
		"name": "Steady Aim", "branch": "Precision",
		"description": "Gain +4% critical hit chance.",
		"is_super": false, "point_cost": 1, "required_level": 2, "prerequisites": ["keen_sight"],
		"stats": {"critical_chance": 0.04}, "x": 0, "y": 1
	},
	"critical_focus": {
		"name": "Critical Focus", "branch": "Precision",
		"description": "Increase critical damage by 20%.",
		"is_super": false, "point_cost": 1, "required_level": 4, "prerequisites": ["steady_aim"],
		"stats": {"critical_damage": 0.20}, "x": 0, "y": 2
	},
	"deadly_precision": {
		"name": "Deadly Precision", "branch": "Precision",
		"description": "Gain +5% critical hit chance and +10% arrow accuracy.",
		"is_super": false, "point_cost": 1, "required_level": 6, "prerequisites": ["critical_focus"],
		"stats": {"critical_chance": 0.05, "accuracy": 0.10}, "x": 0, "y": 3
	},
	"eagles_eye": {
		"name": "Eagle's Eye", "branch": "Precision",
		"description": "Super passive: +8% critical chance and +30% critical damage.",
		"is_super": true, "point_cost": 2, "required_level": 10, "prerequisites": ["deadly_precision"],
		"stats": {"critical_chance": 0.08, "critical_damage": 0.30}, "x": 0, "y": 4
	},
	"quickstep": {
		"name": "Quickstep", "branch": "Skirmisher",
		"description": "Increase Ranger movement speed by 5%.",
		"is_super": false, "point_cost": 1, "required_level": 1, "prerequisites": [],
		"stats": {"movement_speed": 0.05}, "x": 2, "y": 0
	},
	"light_footed": {
		"name": "Light-Footed", "branch": "Skirmisher",
		"description": "Gain +5% chance to evade incoming attacks.",
		"is_super": false, "point_cost": 1, "required_level": 2, "prerequisites": ["quickstep"],
		"stats": {"evasion": 0.05}, "x": 2, "y": 1
	},
	"windrunner": {
		"name": "Windrunner", "branch": "Skirmisher",
		"description": "Increase movement speed by another 5% and projectile speed by 10%.",
		"is_super": false, "point_cost": 1, "required_level": 4, "prerequisites": ["light_footed"],
		"stats": {"movement_speed": 0.05, "projectile_speed": 0.10}, "x": 2, "y": 2
	},
	"evasive_reflex": {
		"name": "Evasive Reflex", "branch": "Skirmisher",
		"description": "Gain +7% chance to evade incoming attacks.",
		"is_super": false, "point_cost": 1, "required_level": 6, "prerequisites": ["windrunner"],
		"stats": {"evasion": 0.07}, "x": 2, "y": 3
	},
	"wind_dancer": {
		"name": "Wind Dancer", "branch": "Skirmisher",
		"description": "Super passive: +10% movement speed, +10% projectile speed, and +15 health.",
		"is_super": true, "point_cost": 2, "required_level": 10, "prerequisites": ["evasive_reflex"],
		"stats": {"movement_speed": 0.10, "projectile_speed": 0.10, "max_health": 15}, "x": 2, "y": 4
	},
	"trapcraft": {
		"name": "Trapcraft", "branch": "Trapper",
		"description": "Increase Explosive Arrow and Smoke Bomb effectiveness by 10%.",
		"is_super": false, "point_cost": 1, "required_level": 1, "prerequisites": [],
		"stats": {"trap_efficiency": 0.10}, "x": 4, "y": 0
	},
	"volatile_payload": {
		"name": "Volatile Payload", "branch": "Trapper",
		"description": "Increase trap and explosive area by another 15%.",
		"is_super": false, "point_cost": 1, "required_level": 2, "prerequisites": ["trapcraft"],
		"stats": {"trap_efficiency": 0.15}, "x": 4, "y": 1
	},
	"efficient_fletching": {
		"name": "Efficient Fletching", "branch": "Trapper",
		"description": "Reduce Ranger skill mana costs by 10%.",
		"is_super": false, "point_cost": 1, "required_level": 4, "prerequisites": ["volatile_payload"],
		"stats": {"mana_cost_reduction": 0.10}, "x": 4, "y": 2
	},
	"field_rations": {
		"name": "Field Rations", "branch": "Trapper",
		"description": "Gain +15 maximum health and +10 maximum mana.",
		"is_super": false, "point_cost": 1, "required_level": 6, "prerequisites": ["efficient_fletching"],
		"stats": {"max_health": 15, "max_mana": 10}, "x": 4, "y": 3
	},
	"master_trapper": {
		"name": "Master Trapper", "branch": "Trapper",
		"description": "Super passive: +25% trap effectiveness and +10% Ranger skill mana savings.",
		"is_super": true, "point_cost": 2, "required_level": 10, "prerequisites": ["field_rations"],
		"stats": {"trap_efficiency": 0.25, "mana_cost_reduction": 0.10}, "x": 4, "y": 4
	}
}

const MAX_PLAYER_LEVEL = 25
const LEVEL_XP_THRESHOLDS: Array[int] = [
	0, 300, 750, 1350, 2100, 3000, 4050, 5250, 6600, 8100,
	9750, 11550, 13500, 15600, 17850, 20250, 22800, 25500,
	28350, 31350, 34500, 37800, 41250, 44850, 48600
]
const LEGACY_LEVEL_XP_THRESHOLDS: Array[int] = [
	0, 100, 250, 450, 700, 1000, 1350, 1750, 2200, 2700,
	3250, 3850, 4500, 5200, 5950, 6750, 7600, 8500, 9450,
	10450, 11500, 12600, 13750, 14950, 16200
]
const EQUIPMENT_SLOTS = [
	"Weapon",
	"Helm",
	"Chest",
	"Legs",
	"Gloves",
	"Boots",
	"Ring 1",
	"Ring 2",
	"Amulet"
]

var _inventory_records: Array[Dictionary] = []
var _equipment_records: Dictionary = {}
var _characters: Array[Dictionary] = []
var _active_character_id := ""
var _active_save_path := SAVE_PATH
var _scene_fade: ColorRect
var _roster_loaded := false
var gold := 0
var player_level := 1
var experience := 0
var passive_tree_points := 0
var skill_tree_points := 0
var witch_skill_ranks: Dictionary = {}
var witch_skill_loadout: Dictionary = {}
var witch_unlocked_passives: Array[String] = []
var warrior_skill_ranks: Dictionary = {}
var warrior_skill_loadout: Dictionary = {}
var warrior_unlocked_passives: Array[String] = []
var ranger_skill_ranks: Dictionary = {}
var ranger_skill_loadout: Dictionary = {}
var ranger_unlocked_passives: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# One theme for every scene, so in-game panels and buttons match the menus.
	# Merged into the engine default because HUD controls sit under CanvasLayers,
	# which stop theme inheritance from the root window.
	ThemeDB.get_default_theme().merge_with(MenuStyle.get_theme())
	_build_scene_fade()
	_load_roster()
	_load_character()


## Fades to black, swaps scenes, then fades back in. Returns an error straight
## away if the scene is missing, like change_scene_to_file().
func change_scene(scene_path: String) -> Error:
	if not ResourceLoader.exists(scene_path):
		return ERR_FILE_NOT_FOUND
	if _scene_fade.mouse_filter == Control.MOUSE_FILTER_STOP:
		return ERR_BUSY
	_scene_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	get_tree().paused = true
	var fade_out := _fade_scene_to(1.0, SCENE_FADE_OUT_TIME)
	fade_out.finished.connect(_finish_scene_change.bind(scene_path))
	return OK


func _finish_scene_change(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	get_tree().paused = false
	if error != OK:
		push_error("Could not change scene to %s: %s" % [scene_path, error_string(error)])
	_fade_scene_to(0.0, SCENE_FADE_IN_TIME).finished.connect(
		func() -> void: _scene_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)


func _fade_scene_to(alpha: float, duration: float) -> Tween:
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(_scene_fade, "color:a", alpha, duration)
	return tween


func _build_scene_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	_scene_fade = ColorRect.new()
	_scene_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scene_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_scene_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_scene_fade)


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	# Android back: scenes with their own back navigation handle it, otherwise
	# it behaves like Esc (close the top menu, or open the pause menu).
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("go_back"):
		scene.call("go_back")
		return
	for pressed in [true, false]:
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.physical_keycode = KEY_ESCAPE
		escape.pressed = pressed
		Input.parse_input_event(escape)


func get_characters() -> Array[Dictionary]:
	_load_roster()
	if _characters.is_empty() and FileAccess.file_exists(SAVE_PATH):
		_characters.append({
			"id": "legacy",
			"name": "Adventurer",
			"class": "Warrior",
			"save_path": SAVE_PATH,
			"completed_levels": [],
			"level_states": {}
		})
		_save_roster()

	var characters: Array[Dictionary] = []
	for character in _characters:
		characters.append({
			"id": character["id"],
			"name": character["name"],
			"class": character["class"]
		})
	return characters


func get_character(character_id: String) -> Dictionary:
	for character in _characters:
		if character["id"] == character_id:
			return character.duplicate()
	return {}


func get_active_character() -> Dictionary:
	return get_character(_active_character_id)


func get_completed_levels() -> Array[int]:
	var character_index := _find_character_index(_active_character_id)
	if character_index < 0:
		return []
	var completed_levels: Array[int] = []
	for level_id in _characters[character_index].get("completed_levels", []):
		completed_levels.append(int(level_id))
	return completed_levels


func is_level_unlocked(level_id: int) -> bool:
	var completed_levels := get_completed_levels()
	match level_id:
		1:
			return true
		2:
			return completed_levels.has(1)
		3:
			return completed_levels.has(2)
		4:
			return completed_levels.has(3)
		ENDGAME_LEVEL_ID:
			return is_campaign_complete()
	return false


## True once every campaign level (all of LEVEL_SCENE_PATHS) has been cleared; unlocks random maps.
func is_campaign_complete() -> bool:
	var completed_levels := get_completed_levels()
	for level_id in LEVEL_SCENE_PATHS:
		if not completed_levels.has(level_id):
			return false
	return true


func get_level_id(scene_path: String) -> int:
	return int(LEVEL_SCENES.get(scene_path, 0))


## The level whose hub `scene_path` is, or 0 if it isn't a hub.
func get_hub_level_id(scene_path: String) -> int:
	for level_id in HUBS:
		if HUBS[level_id]["scene"] == scene_path:
			return level_id
	return 0


func get_hub_scene(level_id: int) -> String:
	return str(HUBS.get(_resolve_hub_id(level_id), HUBS[1])["scene"])


func get_hub_name(level_id: int) -> String:
	return str(HUBS.get(_resolve_hub_id(level_id), HUBS[1])["name"])


func get_hub_arrival(level_id: int) -> Vector2:
	return HUBS.get(_resolve_hub_id(level_id), HUBS[1])["arrival"]


## Random maps lead home to the hub whose waystone started the run.
func _resolve_hub_id(level_id: int) -> int:
	if level_id == ENDGAME_LEVEL_ID:
		return int(get_endgame_run().get("hub", 1))
	return level_id


## The active character's current random map: {tier, layout, boss, seed, hub, cleared}, or {} if they
## have never started one. layout and boss are campaign level ids minus one (LevelController.biome).
func get_endgame_run() -> Dictionary:
	var character_index := _find_character_index(_active_character_id)
	if character_index < 0:
		return {}
	return _validated_endgame_run(_characters[character_index].get("endgame_run", {}))


## True while a random map has been started and not yet cleared, so the waystone can offer to resume it.
func has_unfinished_endgame_run() -> bool:
	var run := get_endgame_run()
	return not run.is_empty() and not bool(run["cleared"])


## Rolls a new random map at the given tier, replacing (abandoning) any unfinished one.
## hub_level_id is the hub the run returns to.
func start_endgame_run(tier: int, hub_level_id: int) -> bool:
	var character_index := _find_character_index(_active_character_id)
	if character_index < 0 or not ENDGAME_TIERS.has(tier) or not HUBS.has(hub_level_id):
		push_error("Cannot start a random map at tier %d from hub %d." % [tier, hub_level_id])
		return false

	var random := RandomNumberGenerator.new()
	random.randomize()
	var layout_count := LEVEL_SCENE_PATHS.size()
	var previous_character: Dictionary = _characters[character_index]
	var character := previous_character.duplicate(true)
	character["endgame_run"] = {
		"tier": tier,
		"layout": random.randi_range(0, layout_count - 1),
		"boss": random.randi_range(0, layout_count - 1),
		# Non-zero so the map's scenery never matches the campaign level it borrows its layout from.
		"seed": random.randi_range(1, 0x7fffffff),
		"hub": hub_level_id,
		"cleared": false,
	}
	var level_states: Dictionary = character.get("level_states", {})
	level_states.erase(str(ENDGAME_LEVEL_ID))
	character["level_states"] = level_states
	_characters[character_index] = character
	if not _save_roster():
		_characters[character_index] = previous_character
		return false
	return true


## Marks the current random map cleared and counts it towards its tier. Its level state is kept so the
## player can return to the cleared map until they start a new one at a waystone.
func finish_endgame_run() -> bool:
	var character_index := _find_character_index(_active_character_id)
	var run := get_endgame_run()
	if character_index < 0 or run.is_empty() or bool(run["cleared"]):
		return false

	var previous_character: Dictionary = _characters[character_index]
	var character := previous_character.duplicate(true)
	run["cleared"] = true
	character["endgame_run"] = run
	var clears := _validated_endgame_clears(character.get("endgame_clears", {}))
	var tier_key := str(run["tier"])
	clears[tier_key] = int(clears.get(tier_key, 0)) + 1
	character["endgame_clears"] = clears
	_characters[character_index] = character
	if not _save_roster():
		_characters[character_index] = previous_character
		return false
	return true


## How many random maps the active character has cleared at a tier.
func get_endgame_clears(tier: int) -> int:
	var character_index := _find_character_index(_active_character_id)
	if character_index < 0:
		return 0
	var clears := _validated_endgame_clears(_characters[character_index].get("endgame_clears", {}))
	return int(clears.get(str(tier), 0))


func get_endgame_tier_name(tier: int) -> String:
	return str(ENDGAME_TIERS.get(tier, ENDGAME_TIERS[1])["name"])

func get_witch_skill_definitions() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for skill_id in WITCH_SKILL_ORDER:
		var definition: Dictionary = WITCH_SKILL_TREE[skill_id].duplicate(true)
		definition["id"] = skill_id
		definitions.append(definition)
	return definitions


func get_warrior_skill_definitions() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for skill_id in WARRIOR_SKILL_ORDER:
		var definition: Dictionary = WARRIOR_SKILL_TREE[skill_id].duplicate(true)
		definition["id"] = skill_id
		definitions.append(definition)
	return definitions


func get_ranger_skill_definitions() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for skill_id in RANGER_SKILL_ORDER:
		var definition: Dictionary = RANGER_SKILL_TREE[skill_id].duplicate(true)
		definition["id"] = skill_id
		definitions.append(definition)
	return definitions


func get_ranger_skill_definition(skill_id: String) -> Dictionary:
	if not RANGER_SKILL_TREE.has(skill_id):
		return {}
	var definition: Dictionary = RANGER_SKILL_TREE[skill_id].duplicate(true)
	definition["id"] = skill_id
	return definition


func get_ranger_skill_rank(skill_id: String) -> int:
	return int(ranger_skill_ranks.get(skill_id, 0))


func get_ranger_equipped_skill(slot: String) -> String:
	return str(ranger_skill_loadout.get(slot, ""))


func can_unlock_ranger_skill(skill_id: String) -> bool:
	if _get_active_character_class() != "Ranger" or not RANGER_SKILL_TREE.has(skill_id):
		return false

	var skill: Dictionary = RANGER_SKILL_TREE[skill_id]
	var current_rank := get_ranger_skill_rank(skill_id)
	if player_level < int(skill["required_level"]) \
			or current_rank >= int(skill["max_rank"]) \
			or skill_tree_points < int(skill["point_cost"]):
		return false
	for prerequisite_id in skill["prerequisites"]:
		if get_ranger_skill_rank(str(prerequisite_id)) <= 0:
			return false
	return true


func unlock_or_upgrade_ranger_skill(skill_id: String) -> bool:
	if not can_unlock_ranger_skill(skill_id):
		return false

	var previous_rank := get_ranger_skill_rank(skill_id)
	var previous_points := skill_tree_points
	ranger_skill_ranks[skill_id] = previous_rank + 1
	skill_tree_points -= int(RANGER_SKILL_TREE[skill_id]["point_cost"])
	if not save_character(get_inventory(), get_equipment()):
		ranger_skill_ranks[skill_id] = previous_rank
		skill_tree_points = previous_points
		return false
	_emit_progression_changed()
	return true


func assign_ranger_skill(skill_id: String, slot: String) -> bool:
	if _get_active_character_class() != "Ranger" \
			or slot not in RANGER_SKILL_SLOTS \
			or get_ranger_skill_rank(skill_id) < 1:
		return false

	var previous_loadout := ranger_skill_loadout.duplicate()
	for assigned_slot in ranger_skill_loadout.keys():
		if ranger_skill_loadout[assigned_slot] == skill_id:
			ranger_skill_loadout.erase(assigned_slot)
	ranger_skill_loadout[slot] = skill_id
	if not save_character(get_inventory(), get_equipment()):
		ranger_skill_loadout = previous_loadout
		return false
	_emit_progression_changed()
	return true


func get_warrior_skill_definition(skill_id: String) -> Dictionary:
	if not WARRIOR_SKILL_TREE.has(skill_id):
		return {}
	var definition: Dictionary = WARRIOR_SKILL_TREE[skill_id].duplicate(true)
	definition["id"] = skill_id
	return definition


func get_warrior_skill_rank(skill_id: String) -> int:
	return int(warrior_skill_ranks.get(skill_id, 0))


func get_warrior_equipped_skill(slot: String) -> String:
	return str(warrior_skill_loadout.get(slot, ""))


func can_unlock_warrior_skill(skill_id: String) -> bool:
	if _get_active_character_class() != "Warrior" or not WARRIOR_SKILL_TREE.has(skill_id):
		return false

	var skill: Dictionary = WARRIOR_SKILL_TREE[skill_id]
	var current_rank := get_warrior_skill_rank(skill_id)
	if player_level < int(skill["required_level"]) \
			or current_rank >= int(skill["max_rank"]) \
			or skill_tree_points < int(skill["point_cost"]):
		return false
	for prerequisite_id in skill["prerequisites"]:
		if get_warrior_skill_rank(str(prerequisite_id)) <= 0:
			return false
	return true


func unlock_or_upgrade_warrior_skill(skill_id: String) -> bool:
	if not can_unlock_warrior_skill(skill_id):
		return false

	var previous_rank := get_warrior_skill_rank(skill_id)
	var previous_points := skill_tree_points
	warrior_skill_ranks[skill_id] = previous_rank + 1
	skill_tree_points -= int(WARRIOR_SKILL_TREE[skill_id]["point_cost"])
	if not save_character(get_inventory(), get_equipment()):
		warrior_skill_ranks[skill_id] = previous_rank
		skill_tree_points = previous_points
		return false
	_emit_progression_changed()
	return true


func assign_warrior_skill(skill_id: String, slot: String) -> bool:
	if _get_active_character_class() != "Warrior" \
			or slot not in WARRIOR_SKILL_SLOTS \
			or get_warrior_skill_rank(skill_id) < 1:
		return false

	var previous_loadout := warrior_skill_loadout.duplicate()
	for assigned_slot in warrior_skill_loadout.keys():
		if warrior_skill_loadout[assigned_slot] == skill_id:
			warrior_skill_loadout.erase(assigned_slot)
	warrior_skill_loadout[slot] = skill_id
	if not save_character(get_inventory(), get_equipment()):
		warrior_skill_loadout = previous_loadout
		return false
	_emit_progression_changed()
	return true


func get_witch_skill_definition(skill_id: String) -> Dictionary:
	if not WITCH_SKILL_TREE.has(skill_id):
		return {}
	var definition: Dictionary = WITCH_SKILL_TREE[skill_id].duplicate(true)
	definition["id"] = skill_id
	return definition


func get_witch_skill_rank(skill_id: String) -> int:
	return int(witch_skill_ranks.get(skill_id, 0))


func get_witch_equipped_skill(slot: String) -> String:
	return str(witch_skill_loadout.get(slot, ""))


func can_unlock_witch_skill(skill_id: String) -> bool:
	if _get_active_character_class() != "Witch" or not WITCH_SKILL_TREE.has(skill_id):
		return false

	var skill: Dictionary = WITCH_SKILL_TREE[skill_id]
	var current_rank := get_witch_skill_rank(skill_id)
	if player_level < int(skill["required_level"]) \
			or current_rank >= int(skill["max_rank"]) \
			or skill_tree_points < int(skill["point_cost"]):
		return false

	return true


func unlock_or_upgrade_witch_skill(skill_id: String) -> bool:
	if not can_unlock_witch_skill(skill_id):
		return false

	var previous_rank := get_witch_skill_rank(skill_id)
	var previous_points := skill_tree_points
	witch_skill_ranks[skill_id] = previous_rank + 1
	skill_tree_points -= int(WITCH_SKILL_TREE[skill_id]["point_cost"])
	if not save_character(get_inventory(), get_equipment()):
		witch_skill_ranks[skill_id] = previous_rank
		skill_tree_points = previous_points
		return false
	_emit_progression_changed()
	return true


func assign_witch_skill(skill_id: String, slot: String) -> bool:
	if _get_active_character_class() != "Witch" \
			or slot not in WITCH_SKILL_SLOTS \
			or get_witch_skill_rank(skill_id) < 1:
		return false

	var previous_loadout := witch_skill_loadout.duplicate()
	for assigned_slot in witch_skill_loadout.keys():
		if witch_skill_loadout[assigned_slot] == skill_id:
			witch_skill_loadout.erase(assigned_slot)
	witch_skill_loadout[slot] = skill_id
	if not save_character(get_inventory(), get_equipment()):
		witch_skill_loadout = previous_loadout
		return false
	_emit_progression_changed()
	return true


func get_witch_passive_definitions() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for passive_id in WITCH_PASSIVE_ORDER:
		var definition: Dictionary = WITCH_PASSIVE_TREE[passive_id].duplicate(true)
		definition["id"] = passive_id
		definitions.append(definition)
	return definitions


func get_witch_passive_definition(passive_id: String) -> Dictionary:
	if not WITCH_PASSIVE_TREE.has(passive_id):
		return {}
	var definition: Dictionary = WITCH_PASSIVE_TREE[passive_id].duplicate(true)
	definition["id"] = passive_id
	return definition


func is_witch_passive_unlocked(passive_id: String) -> bool:
	return witch_unlocked_passives.has(passive_id)


func can_unlock_witch_passive(passive_id: String) -> bool:
	if _get_active_character_class() != "Witch" or not WITCH_PASSIVE_TREE.has(passive_id):
		return false
	if is_witch_passive_unlocked(passive_id):
		return false

	var node: Dictionary = WITCH_PASSIVE_TREE[passive_id]
	if player_level < int(node.get("required_level", 1)):
		return false
	if passive_tree_points < int(node.get("point_cost", 1)):
		return false

	var prerequisites: Array = node.get("prerequisites", [])
	for prerequisite_id in prerequisites:
		if not is_witch_passive_unlocked(str(prerequisite_id)):
			return false
	return true


func unlock_witch_passive(passive_id: String) -> bool:
	if not can_unlock_witch_passive(passive_id):
		return false

	var node: Dictionary = WITCH_PASSIVE_TREE[passive_id]
	var cost := int(node.get("point_cost", 1))
	var previous_passives := witch_unlocked_passives.duplicate()
	var previous_points := passive_tree_points

	witch_unlocked_passives.append(passive_id)
	passive_tree_points -= cost

	if not save_character(get_inventory(), get_equipment()):
		witch_unlocked_passives = previous_passives
		passive_tree_points = previous_points
		return false

	_emit_progression_changed()
	return true


func get_witch_passive_stat_totals() -> Dictionary:
	var totals := {
		"spell_damage_percent": 0.0,
		"evasion": 0.0,
		"max_health": 0,
		"max_mana": 0,
		"damage_reduction_percent": 0.0
	}
	if _get_active_character_class() != "Witch":
		return totals

	for passive_id in witch_unlocked_passives:
		if not WITCH_PASSIVE_TREE.has(passive_id):
			continue
		var node: Dictionary = WITCH_PASSIVE_TREE[passive_id]
		var stats: Dictionary = node.get("stats", {})
		for stat_name in stats:
			if stat_name == "max_health" or stat_name == "max_mana":
				totals[stat_name] = int(totals.get(stat_name, 0)) + int(stats[stat_name])
			else:
				totals[stat_name] = float(totals.get(stat_name, 0.0)) + float(stats[stat_name])
	return totals


func get_warrior_passive_definitions() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for passive_id in WARRIOR_PASSIVE_ORDER:
		var definition: Dictionary = WARRIOR_PASSIVE_TREE[passive_id].duplicate(true)
		definition["id"] = passive_id
		definitions.append(definition)
	return definitions


func get_warrior_passive_definition(passive_id: String) -> Dictionary:
	if not WARRIOR_PASSIVE_TREE.has(passive_id):
		return {}
	var definition: Dictionary = WARRIOR_PASSIVE_TREE[passive_id].duplicate(true)
	definition["id"] = passive_id
	return definition


func is_warrior_passive_unlocked(passive_id: String) -> bool:
	return warrior_unlocked_passives.has(passive_id)


func can_unlock_warrior_passive(passive_id: String) -> bool:
	if _get_active_character_class() != "Warrior" or not WARRIOR_PASSIVE_TREE.has(passive_id):
		return false
	if is_warrior_passive_unlocked(passive_id):
		return false

	var node: Dictionary = WARRIOR_PASSIVE_TREE[passive_id]
	if player_level < int(node.get("required_level", 1)):
		return false
	if passive_tree_points < int(node.get("point_cost", 1)):
		return false

	for prerequisite_id in node.get("prerequisites", []):
		if not is_warrior_passive_unlocked(str(prerequisite_id)):
			return false
	return true


func unlock_warrior_passive(passive_id: String) -> bool:
	if not can_unlock_warrior_passive(passive_id):
		return false

	var node: Dictionary = WARRIOR_PASSIVE_TREE[passive_id]
	var cost := int(node.get("point_cost", 1))
	var previous_passives := warrior_unlocked_passives.duplicate()
	var previous_points := passive_tree_points
	warrior_unlocked_passives.append(passive_id)
	passive_tree_points -= cost

	if not save_character(get_inventory(), get_equipment()):
		warrior_unlocked_passives = previous_passives
		passive_tree_points = previous_points
		return false

	_emit_progression_changed()
	return true


func get_warrior_passive_stat_totals() -> Dictionary:
	var totals := {
		"max_health": 0,
		"max_mana": 0,
		"armor": 0,
		"weapon_damage_bonus": 0,
		"damage_reduction_percent": 0.0
	}
	if _get_active_character_class() != "Warrior":
		return totals

	for passive_id in warrior_unlocked_passives:
		if not WARRIOR_PASSIVE_TREE.has(passive_id):
			continue
		var stats: Dictionary = WARRIOR_PASSIVE_TREE[passive_id].get("stats", {})
		for stat_name in stats:
			if typeof(totals.get(stat_name, 0)) == TYPE_INT:
				totals[stat_name] = int(totals.get(stat_name, 0)) + int(stats[stat_name])
			else:
				totals[stat_name] = float(totals.get(stat_name, 0.0)) + float(stats[stat_name])
	return totals


func get_ranger_passive_definitions() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for passive_id in RANGER_PASSIVE_ORDER:
		var definition: Dictionary = RANGER_PASSIVE_TREE[passive_id].duplicate(true)
		definition["id"] = passive_id
		definitions.append(definition)
	return definitions


func get_ranger_passive_definition(passive_id: String) -> Dictionary:
	if not RANGER_PASSIVE_TREE.has(passive_id):
		return {}
	var definition: Dictionary = RANGER_PASSIVE_TREE[passive_id].duplicate(true)
	definition["id"] = passive_id
	return definition


func is_ranger_passive_unlocked(passive_id: String) -> bool:
	return ranger_unlocked_passives.has(passive_id)


func can_unlock_ranger_passive(passive_id: String) -> bool:
	if _get_active_character_class() != "Ranger" or not RANGER_PASSIVE_TREE.has(passive_id):
		return false
	if is_ranger_passive_unlocked(passive_id):
		return false

	var node: Dictionary = RANGER_PASSIVE_TREE[passive_id]
	if player_level < int(node.get("required_level", 1)):
		return false
	if passive_tree_points < int(node.get("point_cost", 1)):
		return false

	for prerequisite_id in node.get("prerequisites", []):
		if not is_ranger_passive_unlocked(str(prerequisite_id)):
			return false
	return true


func unlock_ranger_passive(passive_id: String) -> bool:
	if not can_unlock_ranger_passive(passive_id):
		return false

	var node: Dictionary = RANGER_PASSIVE_TREE[passive_id]
	var cost := int(node.get("point_cost", 1))
	var previous_passives := ranger_unlocked_passives.duplicate()
	var previous_points := passive_tree_points
	ranger_unlocked_passives.append(passive_id)
	passive_tree_points -= cost

	if not save_character(get_inventory(), get_equipment()):
		ranger_unlocked_passives = previous_passives
		passive_tree_points = previous_points
		return false
	_emit_progression_changed()
	return true


func get_ranger_passive_stat_totals() -> Dictionary:
	var totals := {
		"accuracy": 0.0,
		"critical_chance": 0.0,
		"critical_damage": 0.0,
		"evasion": 0.0,
		"projectile_speed": 0.0,
		"trap_efficiency": 0.0,
		"mana_cost_reduction": 0.0,
		"movement_speed": 0.0,
		"max_health": 0,
		"max_mana": 0
	}
	if _get_active_character_class() != "Ranger":
		return totals

	for passive_id in ranger_unlocked_passives:
		if not RANGER_PASSIVE_TREE.has(passive_id):
			continue
		var stats: Dictionary = RANGER_PASSIVE_TREE[passive_id].get("stats", {})
		for stat_name in stats:
			if typeof(totals.get(stat_name, 0)) == TYPE_INT:
				totals[stat_name] = int(totals.get(stat_name, 0)) + int(stats[stat_name])
			else:
				totals[stat_name] = float(totals.get(stat_name, 0.0)) + float(stats[stat_name])
	return totals


func get_level_state(level_id: int) -> Dictionary:
	var character_index := _find_character_index(_active_character_id)
	if character_index < 0 or level_id < 1 or level_id > LEVEL_SCENES.size():
		return {}

	var character: Dictionary = _characters[character_index]
	var level_states: Variant = character.get("level_states", {})
	if typeof(level_states) != TYPE_DICTIONARY:
		push_error("Saved level states must be a Dictionary.")
		return {}
	var level_state: Variant = level_states.get(str(level_id), {})
	if typeof(level_state) != TYPE_DICTIONARY:
		push_error("Saved state for level %d must be a Dictionary." % level_id)
		return {}
	return level_state.duplicate(true)


func set_level_state(level_id: int, level_state: Dictionary) -> bool:
	var character_index := _find_character_index(_active_character_id)
	if character_index < 0 or level_id < 1 or level_id > LEVEL_SCENES.size():
		push_error("Cannot save state for an invalid level or inactive character.")
		return false

	var previous_character: Dictionary = _characters[character_index]
	var updated_character := previous_character.duplicate(true)
	var level_states: Variant = updated_character.get("level_states", {})
	if typeof(level_states) != TYPE_DICTIONARY:
		push_error("Saved level states must be a Dictionary.")
		return false
	var updated_level_states: Dictionary = level_states
	updated_level_states[str(level_id)] = level_state.duplicate(true)
	updated_character["level_states"] = updated_level_states
	_characters[character_index] = updated_character
	if not _save_roster():
		_characters[character_index] = previous_character
		return false
	return true


func clear_level_state(level_id: int) -> bool:
	var character_index := _find_character_index(_active_character_id)
	if character_index < 0 or level_id < 1 or level_id > LEVEL_SCENES.size():
		push_error("Cannot clear state for an invalid level or inactive character.")
		return false

	var previous_character: Dictionary = _characters[character_index]
	var updated_character := previous_character.duplicate(true)
	var level_states: Variant = updated_character.get("level_states", {})
	if typeof(level_states) != TYPE_DICTIONARY:
		push_error("Saved level states must be a Dictionary.")
		return false
	var updated_level_states: Dictionary = level_states
	if not updated_level_states.has(str(level_id)):
		return true
	updated_level_states.erase(str(level_id))
	updated_character["level_states"] = updated_level_states
	_characters[character_index] = updated_character
	if not _save_roster():
		_characters[character_index] = previous_character
		return false
	return true


## Returns the active character's state for a quest ("" if never accepted).
func get_quest_state(quest_id: String) -> String:
	var character_index := _find_character_index(_active_character_id)
	if character_index < 0:
		return ""
	var quest_states: Variant = _characters[character_index].get("quest_states", {})
	if typeof(quest_states) != TYPE_DICTIONARY:
		push_error("Saved quest states must be a Dictionary.")
		return ""
	return str(quest_states.get(quest_id, ""))


func set_quest_state(quest_id: String, quest_state: String) -> bool:
	var character_index := _find_character_index(_active_character_id)
	if character_index < 0 or quest_id.is_empty():
		push_error("Cannot save quest state for an invalid quest or inactive character.")
		return false

	var previous_character: Dictionary = _characters[character_index]
	var updated_character := previous_character.duplicate(true)
	var quest_states: Variant = updated_character.get("quest_states", {})
	if typeof(quest_states) != TYPE_DICTIONARY:
		push_error("Saved quest states must be a Dictionary.")
		return false
	var updated_quest_states: Dictionary = quest_states
	updated_quest_states[quest_id] = quest_state
	updated_character["quest_states"] = updated_quest_states
	_characters[character_index] = updated_character
	if not _save_roster():
		_characters[character_index] = previous_character
		return false
	return true


func complete_level(level_id: int) -> bool:
	var character_index := _find_character_index(_active_character_id)
	if character_index < 0 or level_id < 1 or level_id > LEVEL_SCENES.size():
		return false

	var previous_character: Dictionary = _characters[character_index]
	var character := previous_character.duplicate(true)
	var completed_levels := _validated_completed_levels(character.get("completed_levels", []))
	if completed_levels.has(level_id):
		return clear_level_state(level_id)

	completed_levels.append(level_id)
	character["completed_levels"] = completed_levels
	var level_states: Variant = character.get("level_states", {})
	if typeof(level_states) != TYPE_DICTIONARY:
		push_error("Saved level states must be a Dictionary.")
		return false
	var updated_level_states: Dictionary = level_states
	updated_level_states.erase(str(level_id))
	character["level_states"] = updated_level_states
	_characters[character_index] = character
	if not _save_roster():
		_characters[character_index] = previous_character
		return false
	return true


func create_character(display_name: String, character_class: String) -> String:
	var clean_name := display_name.strip_edges()
	if clean_name.is_empty() or character_class not in ["Warrior", "Witch", "Ranger"]:
		return ""

	_load_roster()
	var previous_character_id := _active_character_id
	if not previous_character_id.is_empty() and not save_character(get_inventory(), get_equipment()):
		return ""

	var character_id := "character_%d" % Time.get_ticks_usec()
	while _find_character_index(character_id) >= 0:
		character_id += "_1"
	var save_path := "user://characters/%s.json" % character_id
	var directory_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("user://characters")
	)
	if directory_error != OK:
		push_error("Could not create character save directory: %s" % error_string(directory_error))
		return ""

	_characters.append({
		"id": character_id,
		"name": clean_name,
		"class": character_class,
		"save_path": save_path,
		"completed_levels": [],
		"level_states": {},
	})
	_active_character_id = character_id
	_active_save_path = save_path
	_clear_character_data()
	_initialize_witch_skill_state()
	if not save_character([], {}) or not _save_roster():
		_characters.pop_back()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
		_restore_active_character(previous_character_id)
		return ""
	return character_id


func select_character(character_id: String) -> bool:
	var character_index := _find_character_index(character_id)
	if character_index < 0:
		return false
	if _active_character_id == character_id:
		return true
	if not _active_character_id.is_empty() and not save_character(get_inventory(), get_equipment()):
		return false

	var character: Dictionary = _characters[character_index]
	_active_character_id = character_id
	_active_save_path = character["save_path"]
	_clear_character_data()
	_load_character()
	gold_changed.emit(gold)
	return true


func delete_character(character_id: String) -> bool:
	var character_index := _find_character_index(character_id)
	if character_index < 0:
		return false

	var character: Dictionary = _characters[character_index]
	_characters.remove_at(character_index)
	if not _save_roster():
		_characters.insert(character_index, character)
		return false

	if _active_character_id == character_id:
		_active_character_id = ""
		_active_save_path = SAVE_PATH
		_clear_character_data()

	var file_path := str(character["save_path"])
	if FileAccess.file_exists(file_path):
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(file_path))
		if remove_error != OK:
			push_error("Could not delete character save: %s" % error_string(remove_error))
			return false
	return true


func get_inventory() -> Array[ItemData]:
	var items: Array[ItemData] = []
	for record in _inventory_records:
		var item := _item_from_record(record)
		if item != null:
			items.append(item)
	return items


func get_equipment() -> Dictionary:
	var equipment: Dictionary = {}
	for slot_name in _equipment_records:
		var item := _item_from_record(_equipment_records[slot_name])
		if item != null:
			equipment[slot_name] = item
	return equipment


func get_xp_for_next_level() -> int:
	if player_level >= MAX_PLAYER_LEVEL:
		return 0
	return LEVEL_XP_THRESHOLDS[player_level] - LEVEL_XP_THRESHOLDS[player_level - 1]


func get_xp_into_current_level() -> int:
	if player_level >= MAX_PLAYER_LEVEL:
		return 0
	return experience - LEVEL_XP_THRESHOLDS[player_level - 1]


func get_progression_summary() -> String:
	var level_summary := "Level %d / %d" % [player_level, MAX_PLAYER_LEVEL]
	if player_level >= MAX_PLAYER_LEVEL:
		level_summary += "  |  MAX LEVEL"
	else:
		level_summary += "  |  XP: %d / %d" % [
			get_xp_into_current_level(),
			get_xp_for_next_level()
		]
	return "%s\nPassive points: %d  |  Skill points: %d" % [
		level_summary,
		passive_tree_points,
		skill_tree_points
	]


func add_experience(amount: int) -> bool:
	if amount <= 0:
		push_error("Experience gained must be greater than zero.")
		return false
	if player_level >= MAX_PLAYER_LEVEL:
		return true

	var previous_experience := experience
	var previous_level := player_level
	var previous_passive_points := passive_tree_points
	var previous_skill_points := skill_tree_points
	experience = mini(experience + amount, LEVEL_XP_THRESHOLDS[MAX_PLAYER_LEVEL - 1])

	while player_level < MAX_PLAYER_LEVEL \
			and experience >= LEVEL_XP_THRESHOLDS[player_level]:
		player_level += 1
		passive_tree_points += 1
		skill_tree_points += 1

	if not save_character(get_inventory(), get_equipment()):
		experience = previous_experience
		player_level = previous_level
		passive_tree_points = previous_passive_points
		skill_tree_points = previous_skill_points
		return false

	experience_gained.emit(amount)
	_emit_progression_changed()
	for reached_level in range(previous_level + 1, player_level + 1):
		player_leveled_up.emit(reached_level)
	return true


func _emit_progression_changed() -> void:
	progression_changed.emit(
		player_level,
		experience,
		get_xp_into_current_level(),
		get_xp_for_next_level(),
		passive_tree_points,
		skill_tree_points
	)


func add_gold(amount: int) -> void:
	if amount <= 0:
		push_error("Gold pickup amount must be greater than zero.")
		return

	gold += amount
	save_character(get_inventory(), get_equipment())
	gold_changed.emit(gold)


func get_vendor_items() -> Array[ItemData]:
	return [
		_create_item("Iron Sword", "Weapon", Color("#c5d7dc"), 1, 0, 100),
		_create_item("Iron Helm", "Helm", Color("#b8c5c9"), 0, 1, 50),
		_create_item("Oakbound Chestguard", "Chest", Color("#8e754f"), 0, 1, 125),
		_create_item("Trailblazer Legguards", "Legs", Color("#82917b"), 0, 1, 75),
		_create_item("Grips of Thorns", "Gloves", Color("#829b55"), 0, 1, 25),
		_create_item("Wanderer's Boots", "Boots", Color("#9b6741"), 0, 1, 25),
		_create_item("Wolf Fang Ring", "Ring", Color("#d3d0bb"), 1, 0, 150),
		_create_item("Mossstone Ring", "Ring", Color("#66a06b"), 1, 0, 175),
		_create_item("Forest Heart Amulet", "Amulet", Color("#d68e4d"), 1, 0, 200)
	]


func purchase_item(
	item: ItemData,
	inventory: Array[ItemData],
	equipment: Dictionary,
	max_inventory_size: int
) -> bool:
	if item == null:
		push_error("Cannot purchase a null item.")
		return false
	if item.price < 25:
		push_error("Vendor item '%s' has an invalid price." % item.display_name)
		return false
	if inventory.size() >= max_inventory_size or gold < item.price:
		return false

	var updated_inventory := inventory.duplicate()
	updated_inventory.append(item)
	var previous_gold := gold
	gold -= item.price
	if not save_character(updated_inventory, equipment):
		gold = previous_gold
		return false

	gold_changed.emit(gold)
	return true


func get_item_sell_price(item: ItemData) -> int:
	if item == null:
		push_error("Cannot calculate the sale price of a null item.")
		return 0
	return maxi(floori(float(item.price) / 2.0), 1)


func sell_inventory_item(
	inventory: Array[ItemData],
	equipment: Dictionary,
	inventory_index: int
) -> bool:
	if inventory_index < 0 or inventory_index >= inventory.size():
		push_error("Inventory sale index is out of range.")
		return false

	var item := inventory[inventory_index]
	if item == null:
		push_error("Cannot sell a null inventory item.")
		return false

	var updated_inventory := inventory.duplicate()
	updated_inventory.remove_at(inventory_index)
	var sale_price := get_item_sell_price(item)
	var previous_gold := gold
	gold += sale_price
	if not save_character(updated_inventory, equipment):
		gold = previous_gold
		return false

	gold_changed.emit(gold)
	return true


func save_character(inventory: Array[ItemData], equipment: Dictionary) -> bool:
	var inventory_records: Array[Dictionary] = []
	for item in inventory:
		inventory_records.append(_record_from_item(item))

	var equipment_records: Dictionary = {}
	for slot_name in equipment:
		var item: ItemData = equipment[slot_name]
		equipment_records[slot_name] = _record_from_item(item)

	var save_data := {
		"version": SAVE_VERSION,
		"gold": gold,
		"level": player_level,
		"experience": experience,
		"passive_tree_points": passive_tree_points,
		"skill_tree_points": skill_tree_points,
		"witch_skill_ranks": witch_skill_ranks,
		"witch_skill_loadout": witch_skill_loadout,
		"warrior_skill_ranks": warrior_skill_ranks,
		"warrior_skill_loadout": warrior_skill_loadout,
		"ranger_skill_ranks": ranger_skill_ranks,
		"ranger_skill_loadout": ranger_skill_loadout,
		"witch_unlocked_passives": witch_unlocked_passives,
		"warrior_unlocked_passives": warrior_unlocked_passives,
		"ranger_unlocked_passives": ranger_unlocked_passives,
		"inventory": inventory_records,
		"equipment": equipment_records
	}
	var file := FileAccess.open(_active_save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not save character data: %s" % error_string(FileAccess.get_open_error()))
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		push_error("Could not write character save: %s" % error_string(write_error))
		return false
	_inventory_records = inventory_records
	_equipment_records = equipment_records
	return true


func _load_character() -> void:
	if not FileAccess.file_exists(_active_save_path):
		return

	var file := FileAccess.open(_active_save_path, FileAccess.READ)
	if file == null:
		push_error("Could not open character save: %s" % error_string(FileAccess.get_open_error()))
		return

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		push_error(
			"Could not parse character save at line %d: %s" % [
				json.get_error_line(),
				json.get_error_message()
			]
		)
		return

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("Character save must contain a JSON object.")
		return

	var save_data: Dictionary = json.data
	var saved_version: Variant = save_data.get("version", -1)
	if typeof(saved_version) not in [TYPE_INT, TYPE_FLOAT] \
			or float(saved_version) != float(int(saved_version)) \
			or int(saved_version) < 1 or int(saved_version) > SAVE_VERSION:
		push_error("Character save has an unsupported version.")
		return

	var saved_gold: Variant = save_data.get("gold", 0)
	if typeof(saved_gold) not in [TYPE_INT, TYPE_FLOAT] or int(saved_gold) < 0:
		push_error("Character save gold amount is invalid.")
		return
	gold = int(saved_gold)

	var saved_level: Variant = save_data.get("level", 1)
	var saved_experience: Variant = save_data.get("experience", 0)
	var saved_passive_points: Variant = save_data.get("passive_tree_points", 0)
	var saved_skill_points: Variant = save_data.get("skill_tree_points", 0)
	var progression_thresholds: Array[int] = (
		LEGACY_LEVEL_XP_THRESHOLDS
		if int(saved_version) == 1
		else LEVEL_XP_THRESHOLDS
	)
	if typeof(saved_level) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(saved_experience) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(saved_passive_points) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(saved_skill_points) not in [TYPE_INT, TYPE_FLOAT] \
			or float(saved_level) != float(int(saved_level)) \
			or float(saved_experience) != float(int(saved_experience)) \
			or float(saved_passive_points) != float(int(saved_passive_points)) \
			or float(saved_skill_points) != float(int(saved_skill_points)) \
			or int(saved_level) < 1 or int(saved_level) > MAX_PLAYER_LEVEL \
			or int(saved_experience) < 0 \
			or int(saved_experience) > progression_thresholds[MAX_PLAYER_LEVEL - 1] \
			or int(saved_passive_points) < 0 \
			or int(saved_skill_points) < 0 \
			or int(saved_experience) < progression_thresholds[int(saved_level) - 1]:
		push_error("Character save progression data is invalid.")
		return
	player_level = int(saved_level)
	experience = int(saved_experience)
	if int(saved_version) == 1:
		experience = _migrate_legacy_experience(player_level, experience)
	passive_tree_points = int(saved_passive_points)
	skill_tree_points = int(saved_skill_points)
	var raw_witch_skill_ranks: Variant = save_data.get("witch_skill_ranks", {})
	var raw_witch_skill_loadout: Variant = save_data.get("witch_skill_loadout", {})
	if typeof(raw_witch_skill_ranks) != TYPE_DICTIONARY \
			or typeof(raw_witch_skill_loadout) != TYPE_DICTIONARY:
		push_error("Character save Witch skill data is invalid.")
		return
	witch_skill_ranks = _validated_witch_skill_ranks(raw_witch_skill_ranks)
	witch_skill_loadout = _validated_witch_skill_loadout(raw_witch_skill_loadout)
	var raw_warrior_skill_ranks: Variant = save_data.get("warrior_skill_ranks", {})
	var raw_warrior_skill_loadout: Variant = save_data.get("warrior_skill_loadout", {})
	if typeof(raw_warrior_skill_ranks) != TYPE_DICTIONARY \
			or typeof(raw_warrior_skill_loadout) != TYPE_DICTIONARY:
		push_error("Character save Warrior skill data is invalid.")
		return
	warrior_skill_ranks = _validated_warrior_skill_ranks(raw_warrior_skill_ranks)
	warrior_skill_loadout = _validated_warrior_skill_loadout(raw_warrior_skill_loadout)
	var raw_ranger_skill_ranks: Variant = save_data.get("ranger_skill_ranks", {})
	var raw_ranger_skill_loadout: Variant = save_data.get("ranger_skill_loadout", {})
	if typeof(raw_ranger_skill_ranks) != TYPE_DICTIONARY \
			or typeof(raw_ranger_skill_loadout) != TYPE_DICTIONARY:
		push_error("Character save Ranger skill data is invalid.")
		return
	ranger_skill_ranks = _validated_ranger_skill_ranks(raw_ranger_skill_ranks)
	ranger_skill_loadout = _validated_ranger_skill_loadout(raw_ranger_skill_loadout)
	var raw_witch_passives: Variant = save_data.get("witch_unlocked_passives", [])
	witch_unlocked_passives = _validated_witch_passives(raw_witch_passives)
	var raw_warrior_passives: Variant = save_data.get("warrior_unlocked_passives", [])
	warrior_unlocked_passives = _validated_warrior_passives(raw_warrior_passives)
	var raw_ranger_passives: Variant = save_data.get("ranger_unlocked_passives", [])
	ranger_unlocked_passives = _validated_ranger_passives(raw_ranger_passives)

	var raw_inventory: Variant = save_data.get("inventory", [])
	var raw_equipment: Variant = save_data.get("equipment", {})
	if typeof(raw_inventory) != TYPE_ARRAY or typeof(raw_equipment) != TYPE_DICTIONARY:
		push_error("Character save inventory or equipment data is invalid.")
		return

	for raw_item in raw_inventory:
		if typeof(raw_item) != TYPE_DICTIONARY:
			push_error("Ignoring an invalid item in the character inventory save.")
			continue
		var item_record: Dictionary = raw_item
		if _item_from_record(item_record) != null:
			_inventory_records.append(item_record)

	for raw_slot in raw_equipment:
		var slot_name := str(raw_slot)
		if slot_name not in EQUIPMENT_SLOTS:
			push_error("Ignoring unsupported saved equipment slot '%s'." % slot_name)
			continue
		var raw_item: Variant = raw_equipment[raw_slot]
		if typeof(raw_item) != TYPE_DICTIONARY:
			push_error("Ignoring invalid saved equipment in slot '%s'." % slot_name)
			continue
		var item_record: Dictionary = raw_item
		if _item_from_record(item_record) != null:
			_equipment_records[slot_name] = item_record

	_initialize_witch_skill_state()
	if int(saved_version) < SAVE_VERSION:
		save_character(get_inventory(), get_equipment())


func _migrate_legacy_experience(saved_level: int, saved_experience: int) -> int:
	if saved_level >= MAX_PLAYER_LEVEL:
		return LEVEL_XP_THRESHOLDS[MAX_PLAYER_LEVEL - 1]

	var old_level_start := LEGACY_LEVEL_XP_THRESHOLDS[saved_level - 1]
	var old_level_xp := LEGACY_LEVEL_XP_THRESHOLDS[saved_level] - old_level_start
	var progress := float(saved_experience - old_level_start) / float(old_level_xp)
	var new_level_start := LEVEL_XP_THRESHOLDS[saved_level - 1]
	var new_level_xp := LEVEL_XP_THRESHOLDS[saved_level] - new_level_start
	return new_level_start + roundi(new_level_xp * progress)


func _load_roster() -> void:
	if _roster_loaded:
		return
	_roster_loaded = true
	if not FileAccess.file_exists(ROSTER_PATH):
		return

	var file := FileAccess.open(ROSTER_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open character roster: %s" % error_string(FileAccess.get_open_error()))
		return

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_error("Could not parse the character roster.")
		return

	var roster: Dictionary = json.data
	if int(roster.get("version", -1)) != ROSTER_VERSION:
		push_error("Character roster has an unsupported version.")
		return

	var saved_characters: Variant = roster.get("characters", [])
	if typeof(saved_characters) != TYPE_ARRAY:
		push_error("Character roster entries must be an array.")
		return

	for saved_character in saved_characters:
		if typeof(saved_character) != TYPE_DICTIONARY:
			continue
		var character: Dictionary = saved_character
		var character_id: Variant = character.get("id", null)
		var display_name: Variant = character.get("name", null)
		var character_class: Variant = character.get("class", null)
		var save_path: Variant = character.get("save_path", null)
		if typeof(character_id) != TYPE_STRING \
				or typeof(display_name) != TYPE_STRING \
				or typeof(character_class) != TYPE_STRING \
				or typeof(save_path) != TYPE_STRING \
				or character_class not in ["Warrior", "Witch", "Ranger"] \
				or (save_path != SAVE_PATH and not str(save_path).begins_with("user://characters/")):
			continue
		_characters.append({
			"id": character_id,
			"name": display_name,
			"class": character_class,
			"save_path": save_path,
			"completed_levels": _validated_completed_levels(character.get("completed_levels", [])),
			"level_states": _validated_level_states(character.get("level_states", {})),
			"quest_states": _validated_quest_states(character.get("quest_states", {})),
			"endgame_run": _validated_endgame_run(character.get("endgame_run", {})),
			"endgame_clears": _validated_endgame_clears(character.get("endgame_clears", {}))
		})


func _validated_quest_states(raw_states: Variant) -> Dictionary:
	var quest_states := {}
	if typeof(raw_states) != TYPE_DICTIONARY:
		push_error("Ignoring saved quest states that are not a Dictionary.")
		return quest_states
	for quest_id in raw_states:
		var quest_state: Variant = raw_states[quest_id]
		if typeof(quest_id) == TYPE_STRING and typeof(quest_state) == TYPE_STRING:
			quest_states[quest_id] = quest_state
	return quest_states


func _save_roster() -> bool:
	var file := FileAccess.open(ROSTER_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not save character roster: %s" % error_string(FileAccess.get_open_error()))
		return false

	file.store_string(JSON.stringify({
		"version": ROSTER_VERSION,
		"characters": _characters
	}, "\t"))
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		push_error("Could not write character roster: %s" % error_string(write_error))
		return false
	return true


func _find_character_index(character_id: String) -> int:
	for index in range(_characters.size()):
		if _characters[index]["id"] == character_id:
			return index
	return -1


func _get_active_character_class() -> String:
	var character_index := _find_character_index(_active_character_id)
	if character_index < 0:
		return "Warrior"
	return str(_characters[character_index].get("class", "Warrior"))


func _validated_witch_skill_ranks(raw_ranks: Dictionary) -> Dictionary:
	var ranks: Dictionary = {}
	for skill_id in raw_ranks:
		var skill_key := str(skill_id)
		if not WITCH_SKILL_TREE.has(skill_key):
			continue
		var raw_rank: Variant = raw_ranks[skill_id]
		if typeof(raw_rank) not in [TYPE_INT, TYPE_FLOAT] \
				or float(raw_rank) != float(int(raw_rank)):
			continue
		var rank := int(raw_rank)
		if rank >= 1 and rank <= int(WITCH_SKILL_TREE[skill_key]["max_rank"]):
			ranks[skill_key] = rank
	return ranks


func _validated_witch_skill_loadout(raw_loadout: Dictionary) -> Dictionary:
	var loadout: Dictionary = {}
	for raw_slot in raw_loadout:
		var slot := str(raw_slot)
		var skill_id := str(raw_loadout[raw_slot])
		if slot in WITCH_SKILL_SLOTS and witch_skill_ranks.get(skill_id, 0) > 0:
			loadout[slot] = skill_id
	return loadout


func _validated_warrior_skill_ranks(raw_ranks: Dictionary) -> Dictionary:
	var ranks: Dictionary = {}
	for skill_id in raw_ranks:
		var skill_key := str(skill_id)
		if not WARRIOR_SKILL_TREE.has(skill_key):
			continue
		var raw_rank: Variant = raw_ranks[skill_id]
		if typeof(raw_rank) not in [TYPE_INT, TYPE_FLOAT] \
				or float(raw_rank) != float(int(raw_rank)):
			continue
		var rank := int(raw_rank)
		if rank >= 1 and rank <= int(WARRIOR_SKILL_TREE[skill_key]["max_rank"]):
			ranks[skill_key] = rank
	return ranks


func _validated_warrior_skill_loadout(raw_loadout: Dictionary) -> Dictionary:
	var loadout: Dictionary = {}
	for raw_slot in raw_loadout:
		var slot := str(raw_slot)
		var skill_id := str(raw_loadout[raw_slot])
		if slot in WARRIOR_SKILL_SLOTS and warrior_skill_ranks.get(skill_id, 0) > 0:
			loadout[slot] = skill_id
	return loadout


func _validated_ranger_skill_ranks(raw_ranks: Dictionary) -> Dictionary:
	var ranks: Dictionary = {}
	for skill_id in raw_ranks:
		var skill_key := str(skill_id)
		if not RANGER_SKILL_TREE.has(skill_key):
			continue
		var raw_rank: Variant = raw_ranks[skill_id]
		if typeof(raw_rank) not in [TYPE_INT, TYPE_FLOAT] \
				or float(raw_rank) != float(int(raw_rank)):
			continue
		var rank := int(raw_rank)
		if rank >= 1 and rank <= int(RANGER_SKILL_TREE[skill_key]["max_rank"]):
			ranks[skill_key] = rank
	return ranks


func _validated_ranger_skill_loadout(raw_loadout: Dictionary) -> Dictionary:
	var loadout: Dictionary = {}
	for raw_slot in raw_loadout:
		var slot := str(raw_slot)
		var skill_id := str(raw_loadout[raw_slot])
		if slot in RANGER_SKILL_SLOTS and ranger_skill_ranks.get(skill_id, 0) > 0:
			loadout[slot] = skill_id
	return loadout


func _initialize_witch_skill_state() -> void:
	if _get_active_character_class() != "Witch":
		witch_skill_ranks.clear()
		witch_skill_loadout.clear()
		witch_unlocked_passives.clear()
	else:
		if get_witch_skill_rank("firebolt") < 1:
			witch_skill_ranks["firebolt"] = 1
		if witch_skill_loadout.is_empty():
			witch_skill_loadout["Q"] = "firebolt"

	if _get_active_character_class() != "Warrior":
		warrior_skill_ranks.clear()
		warrior_skill_loadout.clear()
	else:
		if get_warrior_skill_rank("heavy_strike") < 1:
			warrior_skill_ranks["heavy_strike"] = 1
		if warrior_skill_loadout.is_empty():
			warrior_skill_loadout["Q"] = "heavy_strike"

	if _get_active_character_class() != "Ranger":
		ranger_skill_ranks.clear()
		ranger_skill_loadout.clear()
		ranger_unlocked_passives.clear()
	else:
		if get_ranger_skill_rank("power_shot") < 1:
			ranger_skill_ranks["power_shot"] = 1
		if ranger_skill_loadout.is_empty():
			ranger_skill_loadout["Q"] = "power_shot"


func _validated_completed_levels(raw_levels: Variant) -> Array[int]:
	var completed_levels: Array[int] = []
	if typeof(raw_levels) != TYPE_ARRAY:
		return completed_levels
	for raw_level in raw_levels:
		if typeof(raw_level) not in [TYPE_INT, TYPE_FLOAT]:
			continue
		var level_id := int(raw_level)
		if level_id >= 1 and level_id <= LEVEL_SCENES.size() and not completed_levels.has(level_id):
			completed_levels.append(level_id)
	return completed_levels


## A saved random map, or {} if it is missing or malformed.
func _validated_endgame_run(raw_run: Variant) -> Dictionary:
	if typeof(raw_run) != TYPE_DICTIONARY or raw_run.is_empty():
		return {}
	for field in ["tier", "layout", "boss", "seed", "hub"]:
		if typeof(raw_run.get(field)) not in [TYPE_INT, TYPE_FLOAT]:
			return {}
	var run := {
		"tier": int(raw_run["tier"]),
		"layout": int(raw_run["layout"]),
		"boss": int(raw_run["boss"]),
		"seed": int(raw_run["seed"]),
		"hub": int(raw_run["hub"]),
		"cleared": bool(raw_run.get("cleared", false)),
	}
	var layout_count := LEVEL_SCENE_PATHS.size()
	if not ENDGAME_TIERS.has(run["tier"]) or not HUBS.has(run["hub"]) \
			or run["layout"] < 0 or run["layout"] >= layout_count \
			or run["boss"] < 0 or run["boss"] >= layout_count:
		return {}
	return run


## Random maps cleared per tier, keyed by the tier as a string.
func _validated_endgame_clears(raw_clears: Variant) -> Dictionary:
	var clears := {}
	if typeof(raw_clears) != TYPE_DICTIONARY:
		return clears
	for tier in ENDGAME_TIERS:
		var count: Variant = raw_clears.get(str(tier), 0)
		if typeof(count) in [TYPE_INT, TYPE_FLOAT] and int(count) > 0:
			clears[str(tier)] = int(count)
	return clears


func _validated_level_states(raw_states: Variant) -> Dictionary:
	var level_states: Dictionary = {}
	if typeof(raw_states) != TYPE_DICTIONARY:
		return level_states
	for raw_level_id in raw_states:
		var level_id := str(raw_level_id).to_int()
		var level_state: Variant = raw_states[raw_level_id]
		if str(raw_level_id) != str(level_id) \
				or level_id < 1 or level_id > LEVEL_SCENES.size() \
				or typeof(level_state) != TYPE_DICTIONARY:
			continue
		level_states[str(level_id)] = level_state.duplicate(true)
	return level_states


func _validated_witch_passives(raw_passives: Variant) -> Array[String]:
	var valid_passives: Array[String] = []
	if typeof(raw_passives) != TYPE_ARRAY:
		return valid_passives
	for raw_id in raw_passives:
		var passive_id := str(raw_id)
		if WITCH_PASSIVE_TREE.has(passive_id) and not valid_passives.has(passive_id):
			valid_passives.append(passive_id)
	return valid_passives


func _validated_warrior_passives(raw_passives: Variant) -> Array[String]:
	var valid_passives: Array[String] = []
	if typeof(raw_passives) != TYPE_ARRAY:
		return valid_passives
	for raw_id in raw_passives:
		var passive_id := str(raw_id)
		if WARRIOR_PASSIVE_TREE.has(passive_id) and not valid_passives.has(passive_id):
			valid_passives.append(passive_id)
	return valid_passives


func _validated_ranger_passives(raw_passives: Variant) -> Array[String]:
	var valid_passives: Array[String] = []
	if typeof(raw_passives) != TYPE_ARRAY:
		return valid_passives
	for raw_id in raw_passives:
		var passive_id := str(raw_id)
		if RANGER_PASSIVE_TREE.has(passive_id) and not valid_passives.has(passive_id):
			valid_passives.append(passive_id)
	return valid_passives


func _clear_character_data() -> void:
	_inventory_records.clear()
	_equipment_records.clear()
	witch_skill_ranks.clear()
	witch_skill_loadout.clear()
	witch_unlocked_passives.clear()
	warrior_unlocked_passives.clear()
	warrior_skill_ranks.clear()
	warrior_skill_loadout.clear()
	gold = 0
	player_level = 1
	experience = 0
	passive_tree_points = 0
	skill_tree_points = 0


func _restore_active_character(character_id: String) -> void:
	if character_id.is_empty():
		_active_character_id = ""
		_active_save_path = SAVE_PATH
		_clear_character_data()
		_load_character()
		return

	var character_index := _find_character_index(character_id)
	if character_index < 0:
		return
	_active_character_id = character_id
	_active_save_path = _characters[character_index]["save_path"]
	_clear_character_data()
	_load_character()


func _record_from_item(item: ItemData) -> Dictionary:
	return {
		"display_name": item.display_name,
		"equipment_slot": item.equipment_slot,
		"icon_color": item.icon_color.to_html(false),
		"damage_bonus": item.damage_bonus,
		"damage_reduction": item.damage_reduction,
		"price": item.price
	}


func _item_from_record(record: Dictionary) -> ItemData:
	var display_name: Variant = record.get("display_name", null)
	var equipment_slot: Variant = record.get("equipment_slot", null)
	var icon_color: Variant = record.get("icon_color", null)
	var damage_bonus: Variant = record.get("damage_bonus", null)
	var damage_reduction: Variant = record.get("damage_reduction", null)
	var price: Variant = record.get("price", 25)
	if typeof(display_name) != TYPE_STRING \
			or typeof(equipment_slot) != TYPE_STRING \
			or typeof(icon_color) != TYPE_STRING \
			or typeof(damage_bonus) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(damage_reduction) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(price) not in [TYPE_INT, TYPE_FLOAT]:
		push_error("Ignoring a character save item with invalid fields.")
		return null

	var item := ItemData.new()
	item.display_name = display_name
	item.equipment_slot = equipment_slot
	item.icon_color = Color.from_string(icon_color, Color.WHITE)
	item.damage_bonus = int(damage_bonus)
	item.damage_reduction = int(damage_reduction)
	item.price = int(price)
	return item


func _create_item(
	item_name: String,
	slot_name: String,
	item_color: Color,
	damage_bonus: int,
	damage_reduction: int,
	item_price: int
) -> ItemData:
	var item := ItemData.new()
	item.display_name = item_name
	item.equipment_slot = slot_name
	item.icon_color = item_color
	item.damage_bonus = damage_bonus
	item.damage_reduction = damage_reduction
	item.price = item_price
	return item
