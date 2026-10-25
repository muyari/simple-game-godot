extends Node

signal progress_changed(defeated: int, total: int)
signal level_completed
signal boss_incoming
signal boss_progress_changed(defeated: int, total: int)
signal chest_loot_opened(chest: TreasureChest)

const WOLF_SCENE = preload("res://wolf.tscn")
const SCORPION_SCENE = preload("res://scorpion.tscn")
const SNAKE_SCENE = preload("res://snake.tscn")
const FROSTBOUND_WRAITH_SCENE = preload("res://frostbound_wraith.tscn")
const CRYSTALBACK_YETI_SCENE = preload("res://crystalback_yeti.tscn")
const SHIVERFANG_ICE_SERPENT_SCENE = preload("res://shiverfang_ice_serpent.tscn")
const IMP_SCENE = preload("res://imp.tscn")
const HELLHOUND_SCENE = preload("res://hellhound.tscn")
const FIRE_FIEND_SCENE = preload("res://fire_fiend.tscn")
const DESERT_BOSS_SCENE = preload("res://desert_boss.tscn")
const ICE_GOLEM_SCENE = preload("res://ice_golem.tscn")
const ICE_BOSS_SCENE = preload("res://ice_boss.tscn")
const ARCHDEMON_SCENE = preload("res://archdemon.tscn")
## Single-monster level bosses; beating one clears the level.
const LEVEL_BOSS_SCENES: Array[String] = ["res://desert_boss.tscn", "res://ice_boss.tscn", "res://archdemon.tscn"]
## Level 4 was once a robot zone; monsters from saves made back then come back as their underworld
## counterparts so those levels can still be finished.
const LEGACY_ENEMY_SCENES := {
	"res://sentinel_hexwalker.tscn": "res://hellhound.tscn",
	"res://neurocore_drone.tscn": "res://fire_fiend.tscn",
	"res://titanforge_exo_unit.tscn": "res://imp.tscn",
	"res://phase_shift_infiltrator.tscn": "res://imp.tscn",
}
const ITEM_PICKUP_SCENE = preload("res://item_pickup.tscn")
const GOLD_PICKUP_SCENE = preload("res://gold_pickup.tscn")
const TREASURE_CHEST_SCENE = preload("res://treasure_chest.tscn")
const APPLE_TREE_SCENE = preload("res://apple_tree.tscn")
const FOREST_GROUND_TEXTURE = preload("res://textures/town_grass.png")
const FOREST_GROUND_TINT := Color(0.84, 0.92, 0.8)
## Forest trees share Oblath's art. Scale range is picked per tree; trunk is the collision radius in world pixels.
const FOREST_TREES: Array[Dictionary] = [
	{"texture": preload("res://textures/town_tree_pine.png"), "scale": Vector2(0.55, 0.72), "trunk": 10.0},
	{"texture": preload("res://textures/town_tree_spruce.png"), "scale": Vector2(0.68, 0.85), "trunk": 9.0},
	{"texture": preload("res://textures/forest_tree_pine_tall.png"), "scale": Vector2(0.6, 0.75), "trunk": 8.0},
	{"texture": preload("res://textures/forest_tree_oak.png"), "scale": Vector2(0.55, 0.68), "trunk": 14.0},
	{"texture": preload("res://textures/forest_tree_maple.png"), "scale": Vector2(0.62, 0.78), "trunk": 11.0},
	{"texture": preload("res://textures/forest_tree_willow.png"), "scale": Vector2(0.62, 0.75), "trunk": 11.0},
	{"texture": preload("res://textures/forest_tree_cedar.png"), "scale": Vector2(0.78, 0.95), "trunk": 7.0},
]
## Big set pieces, at most one per region. Footprint and collision are in world pixels at scale 1.
const FOREST_LANDMARKS: Array[Dictionary] = [
	{"texture": preload("res://textures/forest_cliff_spire.png"), "scale": Vector2(0.62, 0.78), "collision": 48.0},
	{"texture": preload("res://textures/forest_cliff_block.png"), "scale": Vector2(0.6, 0.72), "collision": 62.0},
	{"texture": preload("res://textures/forest_boulder_mossy.png"), "scale": Vector2(0.45, 0.55), "collision": 70.0},
	{"texture": preload("res://textures/forest_cave_mine.png"), "scale": Vector2(0.62, 0.7), "collision": 92.0},
	{"texture": preload("res://textures/forest_cavern.png"), "scale": Vector2(0.58, 0.66), "collision": 96.0},
]
const FOREST_DEBRIS: Array[Dictionary] = [
	{"texture": preload("res://textures/town_stump.png"), "scale": Vector2(0.34, 0.4), "collision": 12.0},
	{"texture": preload("res://textures/forest_stump_small.png"), "scale": Vector2(0.5, 0.6), "collision": 9.0},
	{"texture": preload("res://textures/town_logs.png"), "scale": Vector2(0.42, 0.48), "collision": 14.0},
	{"texture": preload("res://textures/forest_log.png"), "scale": Vector2(0.48, 0.56), "collision": 14.0},
	{"texture": preload("res://textures/town_rock_mossy.png"), "scale": Vector2(0.4, 0.5), "collision": 16.0},
]
const FOREST_UNDERGROWTH: Array[Dictionary] = [
	{"texture": preload("res://textures/town_fern.png"), "scale": Vector2(0.4, 0.5)},
	{"texture": preload("res://textures/town_fern.png"), "scale": Vector2(0.4, 0.5)},
	{"texture": preload("res://textures/town_shrub_green.png"), "scale": Vector2(0.45, 0.6)},
	{"texture": preload("res://textures/town_shrub_round.png"), "scale": Vector2(0.45, 0.6)},
	{"texture": preload("res://textures/town_shrub_conifer.png"), "scale": Vector2(0.45, 0.58)},
	{"texture": preload("res://textures/town_shrub_autumn.png"), "scale": Vector2(0.4, 0.5)},
	{"texture": preload("res://textures/town_sapling.png"), "scale": Vector2(0.45, 0.55)},
]
const FOREST_GROUND_COVER: Array[Dictionary] = [
	{"texture": preload("res://textures/town_grass_clump.png"), "scale": Vector2(0.34, 0.44)},
	{"texture": preload("res://textures/town_grass_clump.png"), "scale": Vector2(0.34, 0.44)},
	{"texture": preload("res://textures/town_flowers.png"), "scale": Vector2(0.34, 0.42)},
	{"texture": preload("res://textures/town_rocks_small.png"), "scale": Vector2(0.3, 0.38)},
]
## Regions (relative to the start) that each hold one apple tree, so there are exactly ten across the map.
## The index in this list becomes the tree's AppleTree.tree_index.
const FOREST_APPLE_TREE_REGIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, -1), Vector2i(2, -1), Vector2i(-2, 0),
	Vector2i(1, 2), Vector2i(-1, -2), Vector2i(3, 1), Vector2i(-3, -1), Vector2i(0, 3),
]
const FOREST_APPLE_TREE_SCALE := 0.68
## Nothing solid is placed this close to where the player enters a level.
const PROP_SPAWN_CLEARING := 150.0
const BOULDERS_TEXTURE = preload("res://textures/forest_boulders.svg")
const DESERT_GROUND_TEXTURE = preload("res://textures/desert_sand_ground.png")
## The sand tile is pixel art; drawn at this scale its grains match the props.
const DESERT_GROUND_SCALE := 2.0
## Sand caves, natural arches and a butte, at most one per region. Collision is the base radius in world
## pixels at scale 1; arches have none so the player can walk beneath them.
const DESERT_LANDMARKS: Array[Dictionary] = [
	{"texture": preload("res://textures/desert_cave_tunnel_arch.png"), "scale": Vector2(0.95, 1.1), "collision": 68.0},
	{"texture": preload("res://textures/desert_cave_round.png"), "scale": Vector2(0.95, 1.1), "collision": 60.0},
	{"texture": preload("res://textures/desert_cave_spire.png"), "scale": Vector2(1.05, 1.2), "collision": 38.0},
	{"texture": preload("res://textures/desert_cave_crag.png"), "scale": Vector2(1.0, 1.15), "collision": 44.0},
	{"texture": preload("res://textures/desert_cave_mesa.png"), "scale": Vector2(0.95, 1.1), "collision": 68.0},
	{"texture": preload("res://textures/desert_cave_slab.png"), "scale": Vector2(0.95, 1.1), "collision": 64.0},
	{"texture": preload("res://textures/desert_arch_a.png"), "scale": Vector2(1.25, 1.45), "collision": 0.0},
	{"texture": preload("res://textures/desert_arch_b.png"), "scale": Vector2(1.25, 1.45), "collision": 0.0},
	{"texture": preload("res://textures/desert_arch_c.png"), "scale": Vector2(1.25, 1.45), "collision": 0.0},
	{"texture": preload("res://textures/desert_arch_d.png"), "scale": Vector2(1.2, 1.4), "collision": 0.0},
	{"texture": preload("res://textures/desert_butte.png"), "scale": Vector2(1.0, 1.15), "collision": 46.0},
]
## Centrepieces for rock outcrops (see _make_rock_outcrop).
const DESERT_OUTCROP_SPIRES: Array[Dictionary] = [
	{"texture": preload("res://textures/desert_stalagmite_tall.png"), "scale": Vector2(1.8, 2.2), "collision": 18.0},
	{"texture": preload("res://textures/desert_stalagmite_medium.png"), "scale": Vector2(1.8, 2.2), "collision": 18.0},
	{"texture": preload("res://textures/desert_spire_tall.png"), "scale": Vector2(1.2, 1.4), "collision": 16.0},
	{"texture": preload("res://textures/desert_hoodoo_a.png"), "scale": Vector2(1.15, 1.35), "collision": 12.0},
	{"texture": preload("res://textures/desert_hoodoo_b.png"), "scale": Vector2(1.15, 1.35), "collision": 12.0},
	{"texture": preload("res://textures/desert_rock_heap_tall.png"), "scale": Vector2(1.0, 1.15), "collision": 32.0},
]
const DESERT_RUIN_WALL = preload("res://textures/desert_ruin_wall.png")
const DESERT_RUBBLE_LOW = preload("res://textures/desert_rubble_low.png")
## Weathered columns for ruins (see _make_ruins).
const DESERT_PILLARS: Array[Texture2D] = [
	preload("res://textures/desert_pillar_ornate.png"),
	preload("res://textures/desert_pillar_a.png"),
	preload("res://textures/desert_pillar_b.png"),
	preload("res://textures/desert_pillar_c.png"),
	preload("res://textures/desert_pillar_d.png"),
]
## Centrepieces for cactus stands (see _make_cactus_stand).
const DESERT_STAND_SAGUAROS: Array[Texture2D] = [
	preload("res://textures/desert_saguaro_l.png"),
	preload("res://textures/desert_saguaro_bloom_l.png"),
	preload("res://textures/desert_saguaro_tall.png"),
	preload("res://textures/desert_saguaro_holed.png"),
	preload("res://textures/desert_saguaro_bent.png"),
]
## Cacti block movement at the trunk.
const DESERT_CACTI: Array[Dictionary] = [
	{"texture": preload("res://textures/desert_saguaro_xs.png"), "scale": Vector2(1.35, 1.6), "trunk": 6.0},
	{"texture": preload("res://textures/desert_saguaro_s.png"), "scale": Vector2(1.35, 1.6), "trunk": 7.0},
	{"texture": preload("res://textures/desert_saguaro_m.png"), "scale": Vector2(1.35, 1.6), "trunk": 8.0},
	{"texture": preload("res://textures/desert_saguaro_l.png"), "scale": Vector2(1.35, 1.6), "trunk": 9.0},
	{"texture": preload("res://textures/desert_saguaro_bloom_l.png"), "scale": Vector2(1.35, 1.6), "trunk": 9.0},
	{"texture": preload("res://textures/desert_saguaro_bloom_m.png"), "scale": Vector2(1.35, 1.6), "trunk": 8.0},
	{"texture": preload("res://textures/desert_saguaro_bent.png"), "scale": Vector2(1.35, 1.6), "trunk": 8.0},
	{"texture": preload("res://textures/desert_saguaro_tall.png"), "scale": Vector2(1.35, 1.6), "trunk": 8.0},
	{"texture": preload("res://textures/desert_saguaro_holed.png"), "scale": Vector2(1.35, 1.6), "trunk": 9.0},
	{"texture": preload("res://textures/desert_cactus_column_a.png"), "scale": Vector2(1.1, 1.3), "trunk": 8.0},
	{"texture": preload("res://textures/desert_cactus_column_b.png"), "scale": Vector2(1.1, 1.3), "trunk": 8.0},
	{"texture": preload("res://textures/desert_cactus_column_c.png"), "scale": Vector2(1.1, 1.3), "trunk": 8.0},
	{"texture": preload("res://textures/desert_cactus_column_d.png"), "scale": Vector2(1.1, 1.3), "trunk": 7.0},
	{"texture": preload("res://textures/desert_cactus_column_e.png"), "scale": Vector2(1.1, 1.3), "trunk": 8.0},
	{"texture": preload("res://textures/desert_cactus_flowering.png"), "scale": Vector2(1.1, 1.3), "trunk": 7.0},
	{"texture": preload("res://textures/desert_cactus_broken.png"), "scale": Vector2(1.1, 1.3), "trunk": 7.0},
	{"texture": preload("res://textures/desert_cactus_bud.png"), "scale": Vector2(1.0, 1.2), "trunk": 6.0},
	{"texture": preload("res://textures/desert_barrel_bloom_a.png"), "scale": Vector2(0.8, 0.95), "trunk": 16.0},
	{"texture": preload("res://textures/desert_barrel_bloom_b.png"), "scale": Vector2(0.8, 0.95), "trunk": 16.0},
	{"texture": preload("res://textures/desert_barrel_bloom_c.png"), "scale": Vector2(0.8, 0.95), "trunk": 15.0},
	{"texture": preload("res://textures/desert_barrel.png"), "scale": Vector2(0.75, 0.9), "trunk": 14.0},
	{"texture": preload("res://textures/desert_saguaro_classic_a.png"), "scale": Vector2(1.0, 1.25), "trunk": 8.0},
	{"texture": preload("res://textures/desert_saguaro_classic_b.png"), "scale": Vector2(1.0, 1.25), "trunk": 8.0},
	{"texture": preload("res://textures/desert_barrel_red.png"), "scale": Vector2(0.55, 0.7), "trunk": 15.0},
	{"texture": preload("res://textures/desert_prickly_pear_tall.png"), "scale": Vector2(0.7, 0.85), "trunk": 13.0},
	{"texture": preload("res://textures/desert_prickly_pear_bloom.png"), "scale": Vector2(0.7, 0.85), "trunk": 13.0},
	{"texture": preload("res://textures/desert_cactus_rose.png"), "scale": Vector2(0.7, 0.85), "trunk": 7.0},
]
const DESERT_ROCKS: Array[Dictionary] = [
	{"texture": preload("res://textures/desert_rock_boulder.png"), "scale": Vector2(1.2, 1.45), "collision": 18.0},
	{"texture": preload("res://textures/desert_rock_pair.png"), "scale": Vector2(1.1, 1.3), "collision": 16.0},
	{"texture": preload("res://textures/desert_rock_trio.png"), "scale": Vector2(1.1, 1.3), "collision": 14.0},
	{"texture": preload("res://textures/desert_rock_cluster.png"), "scale": Vector2(1.1, 1.3), "collision": 14.0},
	{"texture": preload("res://textures/desert_rock_flat.png"), "scale": Vector2(1.1, 1.3), "collision": 16.0},
	{"texture": preload("res://textures/desert_rock_round.png"), "scale": Vector2(1.0, 1.25), "collision": 17.0},
	{"texture": preload("res://textures/desert_rock_spire_broken.png"), "scale": Vector2(1.1, 1.3), "collision": 15.0},
	{"texture": preload("res://textures/desert_stalagmite_small.png"), "scale": Vector2(1.1, 1.3), "collision": 14.0},
	{"texture": preload("res://textures/desert_stalagmite_twin.png"), "scale": Vector2(1.1, 1.3), "collision": 13.0},
	{"texture": preload("res://textures/desert_rock_pile_low.png"), "scale": Vector2(1.0, 1.15), "collision": 24.0},
	{"texture": preload("res://textures/desert_rock_pile_mid.png"), "scale": Vector2(1.0, 1.15), "collision": 20.0},
	{"texture": preload("res://textures/desert_rock_pile_small.png"), "scale": Vector2(1.0, 1.15), "collision": 16.0},
	{"texture": preload("res://textures/desert_boulders_pair.png"), "scale": Vector2(1.0, 1.1), "collision": 22.0},
	{"texture": preload("res://textures/desert_spire_mid.png"), "scale": Vector2(1.0, 1.2), "collision": 12.0},
	{"texture": preload("res://textures/desert_spire_short.png"), "scale": Vector2(1.0, 1.2), "collision": 12.0},
	{"texture": preload("res://textures/desert_rubble_heap.png"), "scale": Vector2(0.9, 1.05), "collision": 26.0},
	{"texture": preload("res://textures/desert_rubble_low.png"), "scale": Vector2(0.95, 1.1), "collision": 18.0},
]
## Dry scrub that characters walk through.
const DESERT_BRUSH: Array[Dictionary] = [
	{"texture": preload("res://textures/desert_brush_a.png"), "scale": Vector2(0.75, 0.95)},
	{"texture": preload("res://textures/desert_brush_b.png"), "scale": Vector2(0.75, 0.95)},
	{"texture": preload("res://textures/desert_brush_c.png"), "scale": Vector2(0.75, 0.95)},
	{"texture": preload("res://textures/desert_brush_d.png"), "scale": Vector2(0.7, 0.9)},
	{"texture": preload("res://textures/desert_brush_e.png"), "scale": Vector2(0.7, 0.9)},
	{"texture": preload("res://textures/desert_brush_f.png"), "scale": Vector2(0.7, 0.9)},
	{"texture": preload("res://textures/desert_brush_g.png"), "scale": Vector2(0.7, 0.9)},
	{"texture": preload("res://textures/desert_brush_h.png"), "scale": Vector2(0.7, 0.9)},
	{"texture": preload("res://textures/desert_brush_i.png"), "scale": Vector2(0.7, 0.9)},
	{"texture": preload("res://textures/desert_brush_j.png"), "scale": Vector2(0.8, 1.0)},
	{"texture": preload("res://textures/desert_cactus_nub.png"), "scale": Vector2(0.9, 1.1)},
	{"texture": preload("res://textures/desert_rocks_small.png"), "scale": Vector2(0.9, 1.1)},
	{"texture": preload("res://textures/desert_agave.png"), "scale": Vector2(0.55, 0.7)},
	{"texture": preload("res://textures/desert_dry_branches_a.png"), "scale": Vector2(0.55, 0.7)},
	{"texture": preload("res://textures/desert_dry_branches_b.png"), "scale": Vector2(0.55, 0.7)},
	{"texture": preload("res://textures/desert_dry_grass.png"), "scale": Vector2(0.5, 0.65)},
]
## Low plants that grow together in patches; collision > 0 for the prickly ones.
const DESERT_PATCH_PLANTS: Array[Dictionary] = [
	{"texture": preload("res://textures/desert_agave.png"), "scale": Vector2(0.55, 0.7), "collision": 0.0},
	{"texture": preload("res://textures/desert_prickly_pear_bloom.png"), "scale": Vector2(0.65, 0.8), "collision": 13.0},
	{"texture": preload("res://textures/desert_prickly_pear_tall.png"), "scale": Vector2(0.65, 0.8), "collision": 13.0},
	{"texture": preload("res://textures/desert_barrel_red.png"), "scale": Vector2(0.5, 0.62), "collision": 15.0},
	{"texture": preload("res://textures/desert_barrel_bloom_a.png"), "scale": Vector2(0.7, 0.85), "collision": 16.0},
	{"texture": preload("res://textures/desert_dry_grass.png"), "scale": Vector2(0.45, 0.6), "collision": 0.0},
	{"texture": preload("res://textures/desert_brush_d.png"), "scale": Vector2(0.65, 0.8), "collision": 0.0},
	{"texture": preload("res://textures/desert_cactus_nub.png"), "scale": Vector2(0.9, 1.1), "collision": 0.0},
]
## Flat sand detail drawn under everything: tracks, cracks, sinkholes and scattered stones.
const DESERT_GROUND_DECALS: Array[Dictionary] = [
	{"texture": preload("res://textures/desert_sand_mound.png"), "scale": Vector2(1.3, 1.6)},
	{"texture": preload("res://textures/desert_footprints.png"), "scale": Vector2(1.0, 1.2)},
	{"texture": preload("res://textures/desert_tracks.png"), "scale": Vector2(1.0, 1.2)},
	{"texture": preload("res://textures/desert_stone_ring.png"), "scale": Vector2(1.1, 1.3)},
	{"texture": preload("res://textures/desert_cracked_earth.png"), "scale": Vector2(1.3, 1.6)},
	{"texture": preload("res://textures/desert_sun_cracks.png"), "scale": Vector2(1.2, 1.5)},
	{"texture": preload("res://textures/desert_pebbles.png"), "scale": Vector2(1.1, 1.3)},
	{"texture": preload("res://textures/desert_sinkhole.png"), "scale": Vector2(1.1, 1.3)},
]
const ICE_GROUND_TEXTURE = preload("res://textures/ice_snow_ground.png")
## The snow tile is pixel art; drawn at this scale its ripples match the props.
const ICE_GROUND_SCALE := 2.0
const ICE_BLOCK = preload("res://textures/ice_block.png")
## Carved ice columns for frozen ruins (see _make_frozen_ruins).
const ICE_PILLARS: Array[Texture2D] = [
	preload("res://textures/ice_pillar_twisted.png"),
	preload("res://textures/ice_pillar_ornate.png"),
	preload("res://textures/ice_pillar_slim.png"),
]
const ICE_CRYSTALS: Array[Dictionary] = [
	{"texture": preload("res://textures/ice_crystals_a.png"), "scale": Vector2(0.8, 1.0), "collision": 16.0},
	{"texture": preload("res://textures/ice_crystals_b.png"), "scale": Vector2(0.8, 1.0), "collision": 16.0},
	{"texture": preload("res://textures/ice_crystals_c.png"), "scale": Vector2(0.8, 1.0), "collision": 16.0},
	{"texture": preload("res://textures/ice_spike_tall.png"), "scale": Vector2(0.9, 1.1), "collision": 7.0},
	{"texture": preload("res://textures/ice_spike_short.png"), "scale": Vector2(0.9, 1.1), "collision": 7.0},
]
## Frosted cave rock spires, centrepieces for rock outcrops (see _make_ice_outcrop).
const ICE_STALAGMITES: Array[Dictionary] = [
	{"texture": preload("res://textures/ice_stalagmite_a.png"), "scale": Vector2(0.95, 1.15), "collision": 12.0},
	{"texture": preload("res://textures/ice_stalagmite_b.png"), "scale": Vector2(0.95, 1.15), "collision": 12.0},
	{"texture": preload("res://textures/ice_stalagmite_c.png"), "scale": Vector2(0.95, 1.15), "collision": 12.0},
	{"texture": preload("res://textures/ice_stalagmite_d.png"), "scale": Vector2(0.95, 1.15), "collision": 12.0},
	{"texture": preload("res://textures/ice_stalagmite_e.png"), "scale": Vector2(0.95, 1.15), "collision": 11.0},
]
const ICE_ROCKS: Array[Dictionary] = [
	{"texture": preload("res://textures/ice_rock_a.png"), "scale": Vector2(0.65, 0.8), "collision": 24.0},
	{"texture": preload("res://textures/ice_rock_b.png"), "scale": Vector2(0.65, 0.8), "collision": 24.0},
	{"texture": preload("res://textures/ice_rock_c.png"), "scale": Vector2(0.65, 0.8), "collision": 22.0},
	{"texture": preload("res://textures/ice_rock_d.png"), "scale": Vector2(0.65, 0.8), "collision": 24.0},
	{"texture": preload("res://textures/ice_rock_e.png"), "scale": Vector2(0.65, 0.8), "collision": 24.0},
	{"texture": preload("res://textures/ice_rock_f.png"), "scale": Vector2(0.65, 0.8), "collision": 22.0},
	{"texture": preload("res://textures/ice_rock_g.png"), "scale": Vector2(0.65, 0.8), "collision": 24.0},
	{"texture": preload("res://textures/ice_rock_h.png"), "scale": Vector2(0.65, 0.8), "collision": 24.0},
	{"texture": preload("res://textures/ice_rock_i.png"), "scale": Vector2(0.65, 0.8), "collision": 24.0},
	{"texture": preload("res://textures/ice_rock_j.png"), "scale": Vector2(0.65, 0.8), "collision": 24.0},
	{"texture": preload("res://textures/ice_rock_k.png"), "scale": Vector2(0.65, 0.8), "collision": 22.0},
	{"texture": preload("res://textures/ice_rock_l.png"), "scale": Vector2(0.65, 0.8), "collision": 24.0},
	{"texture": preload("res://textures/ice_rock_m.png"), "scale": Vector2(0.65, 0.8), "collision": 24.0},
	{"texture": preload("res://textures/ice_rock_n.png"), "scale": Vector2(0.65, 0.8), "collision": 24.0},
	{"texture": preload("res://textures/ice_rock_o.png"), "scale": Vector2(0.65, 0.8), "collision": 24.0},
	{"texture": preload("res://textures/ice_rock_p.png"), "scale": Vector2(0.65, 0.8), "collision": 24.0},
	{"texture": preload("res://textures/ice_rock_q.png"), "scale": Vector2(0.65, 0.8), "collision": 24.0},
	{"texture": preload("res://textures/ice_rock_r.png"), "scale": Vector2(0.65, 0.8), "collision": 22.0},
	{"texture": preload("res://textures/ice_rock_s.png"), "scale": Vector2(0.65, 0.8), "collision": 22.0},
	{"texture": preload("res://textures/ice_rock_low.png"), "scale": Vector2(0.65, 0.8), "collision": 22.0},
	{"texture": preload("res://textures/ice_rock_pile_a.png"), "scale": Vector2(0.65, 0.8), "collision": 22.0},
	{"texture": preload("res://textures/ice_rock_pile_b.png"), "scale": Vector2(0.65, 0.8), "collision": 22.0},
]
## Frozen tree stumps, solid at the trunk.
const ICE_STUMPS: Array[Dictionary] = [
	{"texture": preload("res://textures/ice_stump_a.png"), "scale": Vector2(0.7, 0.85), "collision": 16.0},
	{"texture": preload("res://textures/ice_stump_b.png"), "scale": Vector2(0.7, 0.85), "collision": 16.0},
	{"texture": preload("res://textures/ice_stump_c.png"), "scale": Vector2(0.7, 0.85), "collision": 16.0},
	{"texture": preload("res://textures/ice_stump_d.png"), "scale": Vector2(0.7, 0.85), "collision": 16.0},
	{"texture": preload("res://textures/ice_stump_e.png"), "scale": Vector2(0.7, 0.85), "collision": 16.0},
	{"texture": preload("res://textures/ice_stump_f.png"), "scale": Vector2(0.7, 0.85), "collision": 16.0},
	{"texture": preload("res://textures/ice_stump_g.png"), "scale": Vector2(0.7, 0.85), "collision": 16.0},
]
## Low heaps of snow that characters wade through.
const ICE_SNOW_PILES: Array[Dictionary] = [
	{"texture": preload("res://textures/ice_snow_pile_a.png"), "scale": Vector2(0.6, 0.8)},
	{"texture": preload("res://textures/ice_snow_pile_b.png"), "scale": Vector2(0.6, 0.8)},
	{"texture": preload("res://textures/ice_snow_pile_c.png"), "scale": Vector2(0.6, 0.8)},
	{"texture": preload("res://textures/ice_drift_small.png"), "scale": Vector2(0.9, 1.1)},
]
## Long wind-blown drifts, drawn flat under characters.
const ICE_DRIFTS: Array[Dictionary] = [
	{"texture": preload("res://textures/ice_drift_wide.png"), "scale": Vector2(0.8, 1.05)},
	{"texture": preload("res://textures/ice_drift_wave.png"), "scale": Vector2(0.8, 1.05)},
	{"texture": preload("res://textures/ice_drift_mid.png"), "scale": Vector2(0.8, 1.05)},
	{"texture": preload("res://textures/ice_drift_round.png"), "scale": Vector2(0.8, 1.05)},
	{"texture": preload("res://textures/ice_drift_large.png"), "scale": Vector2(0.8, 1.05)},
]
## Flat snow detail drawn under everything: scattered chunks of snow and ice.
const ICE_GROUND_DECALS: Array[Dictionary] = [
	{"texture": preload("res://textures/ice_snow_chunks_a.png"), "scale": Vector2(0.9, 1.1)},
	{"texture": preload("res://textures/ice_snow_chunks_b.png"), "scale": Vector2(0.9, 1.1)},
	{"texture": preload("res://textures/ice_snow_chunks_c.png"), "scale": Vector2(0.9, 1.1)},
	{"texture": preload("res://textures/ice_drift_small.png"), "scale": Vector2(1.0, 1.2)},
]
const UNDERWORLD_GROUND_TEXTURE = preload("res://textures/underworld_ground.png")
## The cobble tile is pixel art; drawn at this scale its stones match the props.
const UNDERWORLD_GROUND_SCALE := 2.0
const SOOT_SHADOW := Color(0.08, 0.02, 0.02, 0.45)
## Flat lava-veined patches of ground drawn under everything.
const UNDERWORLD_DECALS: Array[Dictionary] = [
	{"texture": preload("res://textures/underworld_decal_lava_ring.png"), "scale": Vector2(0.9, 1.2)},
]
const OBSIDIAN_CRAGS: Array[Dictionary] = [
	{"texture": preload("res://textures/underworld_obsidian_crag_a.png"), "scale": Vector2(0.85, 1.0), "collision": 30.0},
	{"texture": preload("res://textures/underworld_obsidian_crag_b.png"), "scale": Vector2(0.85, 1.0), "collision": 32.0},
	{"texture": preload("res://textures/underworld_obsidian_cluster_a.png"), "scale": Vector2(0.85, 1.0), "collision": 30.0},
	{"texture": preload("res://textures/underworld_obsidian_cluster_tall.png"), "scale": Vector2(0.85, 1.0), "collision": 28.0},
]
const OBSIDIAN_SPIRES: Array[Dictionary] = [
	{"texture": preload("res://textures/underworld_obsidian_spire_a.png"), "scale": Vector2(0.85, 1.05), "collision": 12.0},
	{"texture": preload("res://textures/underworld_obsidian_spire_b.png"), "scale": Vector2(0.85, 1.05), "collision": 12.0},
	{"texture": preload("res://textures/underworld_obsidian_spire_c.png"), "scale": Vector2(0.85, 1.05), "collision": 12.0},
	{"texture": preload("res://textures/underworld_obsidian_spire_d.png"), "scale": Vector2(0.85, 1.05), "collision": 12.0},
	{"texture": preload("res://textures/underworld_obsidian_spire_e.png"), "scale": Vector2(0.85, 1.05), "collision": 13.0},
	{"texture": preload("res://textures/underworld_obsidian_column.png"), "scale": Vector2(0.85, 1.05), "collision": 14.0},
]
const OBSIDIAN_ROCKS: Array[Dictionary] = [
	{"texture": preload("res://textures/underworld_obsidian_boulder.png"), "scale": Vector2(0.8, 0.95), "collision": 22.0},
	{"texture": preload("res://textures/underworld_obsidian_rock_flat.png"), "scale": Vector2(0.85, 1.0), "collision": 16.0},
	{"texture": preload("res://textures/underworld_obsidian_nub_a.png"), "scale": Vector2(0.9, 1.1), "collision": 9.0},
	{"texture": preload("res://textures/underworld_obsidian_nub_b.png"), "scale": Vector2(0.9, 1.1), "collision": 10.0},
]
## Ruined gateways, the centrepiece of a gate ruin (see _make_ruined_gate).
const UNDERWORLD_ARCHES: Array[Texture2D] = [
	preload("res://textures/underworld_arch_dark.png"),
	preload("res://textures/underworld_arch_gargoyle.png"),
	preload("res://textures/underworld_arch_brimstone.png"),
	preload("res://textures/underworld_arch_chained.png"),
	preload("res://textures/underworld_arch_demon.png"),
]
const UNDERWORLD_PILLARS: Array[Dictionary] = [
	{"texture": preload("res://textures/underworld_pillar_gothic_a.png"), "scale": Vector2(0.85, 1.0), "collision": 14.0},
	{"texture": preload("res://textures/underworld_pillar_gothic_b.png"), "scale": Vector2(0.85, 1.0), "collision": 14.0},
	{"texture": preload("res://textures/underworld_pillar_skull_a.png"), "scale": Vector2(0.8, 0.95), "collision": 12.0},
	{"texture": preload("res://textures/underworld_pillar_skull_b.png"), "scale": Vector2(0.8, 0.95), "collision": 12.0},
	{"texture": preload("res://textures/underworld_pillar_skeleton.png"), "scale": Vector2(0.8, 0.95), "collision": 14.0},
	{"texture": preload("res://textures/underworld_column_broken.png"), "scale": Vector2(0.85, 1.0), "collision": 11.0},
	{"texture": preload("res://textures/underworld_column_skull.png"), "scale": Vector2(0.85, 1.0), "collision": 12.0},
]
const UNDERWORLD_BONES: Array[Dictionary] = [
	{"texture": preload("res://textures/underworld_bones_pile_a.png"), "scale": Vector2(0.75, 0.9)},
	{"texture": preload("res://textures/underworld_bones_pile_b.png"), "scale": Vector2(0.7, 0.85)},
]
const UNDERWORLD_SKELETON = preload("res://textures/underworld_skeleton.png")
## Torture-yard pieces; "glow" props get firelight (see _ignite).
const UNDERWORLD_TORMENTS: Array[Dictionary] = [
	{"texture": preload("res://textures/underworld_rack.png"), "scale": Vector2(0.75, 0.85), "collision": 30.0},
	{"texture": preload("res://textures/underworld_iron_maiden.png"), "scale": Vector2(0.8, 0.9), "collision": 18.0},
	{"texture": preload("res://textures/underworld_wheel.png"), "scale": Vector2(0.75, 0.85), "collision": 22.0},
	{"texture": preload("res://textures/underworld_cage.png"), "scale": Vector2(0.8, 0.9), "collision": 24.0},
	{"texture": preload("res://textures/underworld_chains_a.png"), "scale": Vector2(0.75, 0.85), "collision": 16.0},
	{"texture": preload("res://textures/underworld_chains_b.png"), "scale": Vector2(0.75, 0.85), "collision": 10.0},
	{"texture": preload("res://textures/underworld_shackles.png"), "scale": Vector2(0.7, 0.8), "collision": 0.0},
]
const UNDERWORLD_SUPPLIES: Array[Dictionary] = [
	{"texture": preload("res://textures/underworld_crate_a.png"), "scale": Vector2(0.75, 0.85), "collision": 14.0},
	{"texture": preload("res://textures/underworld_crate_b.png"), "scale": Vector2(0.75, 0.85), "collision": 15.0},
	{"texture": preload("res://textures/underworld_barrel_a.png"), "scale": Vector2(0.75, 0.85), "collision": 12.0},
	{"texture": preload("res://textures/underworld_barrel_b.png"), "scale": Vector2(0.75, 0.85), "collision": 12.0},
	{"texture": preload("res://textures/underworld_crate_skull_a.png"), "scale": Vector2(0.7, 0.8), "collision": 20.0},
	{"texture": preload("res://textures/underworld_crate_skull_b.png"), "scale": Vector2(0.7, 0.8), "collision": 20.0},
]
## Fires burning in the dark. "flame" is the height of the flames above the base, as a fraction of the art.
const UNDERWORLD_FIRES: Array[Dictionary] = [
	{"texture": preload("res://textures/underworld_brazier_box.png"), "scale": Vector2(0.75, 0.85), "collision": 18.0, "flame": 0.75},
	{"texture": preload("res://textures/underworld_cauldron.png"), "scale": Vector2(0.85, 0.95), "collision": 12.0, "flame": 0.8},
	{"texture": preload("res://textures/underworld_fire_grate.png"), "scale": Vector2(0.75, 0.85), "collision": 18.0, "flame": 0.5},
]
const UNDERWORLD_ALTARS: Array[Dictionary] = [
	{"texture": preload("res://textures/underworld_altar_stone.png"), "scale": Vector2(0.75, 0.85), "collision": 34.0},
	{"texture": preload("res://textures/underworld_altar_demon.png"), "scale": Vector2(0.8, 0.9), "collision": 26.0},
	{"texture": preload("res://textures/underworld_altar_blood.png"), "scale": Vector2(0.75, 0.85), "collision": 34.0},
	{"texture": preload("res://textures/underworld_altar_candles.png"), "scale": Vector2(0.75, 0.85), "collision": 34.0, "flame": 0.85},
]
const UNDERWORLD_GARGOYLES: Array[Dictionary] = [
	{"texture": preload("res://textures/underworld_gargoyle_a.png"), "scale": Vector2(0.75, 0.85), "collision": 18.0},
	{"texture": preload("res://textures/underworld_gargoyle_b.png"), "scale": Vector2(0.75, 0.85), "collision": 18.0},
	{"texture": preload("res://textures/underworld_gargoyle_c.png"), "scale": Vector2(0.75, 0.85), "collision": 20.0},
]
const MAX_FOREST_ENEMIES = 10
const MAX_DESERT_ENEMIES = 15
const MAX_ICE_ENEMIES = 12
const MAX_UNDERWORLD_ENEMIES = 16
const SPAWN_EDGE_MARGIN = 128.0
## Restored monsters start at least this far from the player, outside Wolf.AGGRO_RANGE.
const ARRIVAL_CLEARANCE = 700.0
## Once every monster has spawned, survivors waiting out of range are brought to the player one at a
## time, this often (seconds), after STRAGGLER_ARRIVAL_GRACE seconds in the level.
const STRAGGLER_INTERVAL = 4.0
const STRAGGLER_ARRIVAL_GRACE = 6.0
const SCENERY_PRELOAD_RADIUS = 1
const ITEM_DROP_CHANCE = 0.1
## Extra drops (e.g. from Hoarder monsters) scatter up to this far so they don't stack.
const EXTRA_DROP_SCATTER = 28.0
## Fresh drops hop this far (min, max) out of the monster, each its own way, so gold and gear don't stack.
const DROP_HOP_DISTANCE = Vector2(20.0, 38.0)
const SCENERY_CLEARANCE = 24.0
const FOREST_BOSS_PACK_SIZE = 3
const BOSS_PACK_SPREAD = 90.0
const ALPHA_WOLF_SCALE = 1.25
const ALPHA_WOLF_HEALTH_MULTIPLIER = 3.0
const ALPHA_WOLF_DAMAGE_MULTIPLIER = 1.25
const ALPHA_WOLF_EXPERIENCE = 60
const BOSS_ROLE_META = "boss_role"
const CHEST_MIN_ITEMS = 1
const CHEST_MAX_ITEMS = 2

@export var player_path: NodePath = NodePath("../Player")
@export_enum("Forest", "Desert", "Ice Caves", "Underworld") var biome := 0
@export_range(1, 25, 1) var area_level := 1

var player: Player
var player_camera: Camera2D
var level_id := 0
var region_size := Vector2.ZERO
var region_origin := Vector2.ZERO
var current_region := Vector2i.ZERO
var last_player_position := Vector2.ZERO
var enemies_spawned := 0
var enemies_defeated := 0
var boss_spawned := false
var boss_wolves_defeated := 0
var level_is_complete := false
var spawned_enemy_regions: Dictionary = {}
var generated_scenery_regions: Dictionary = {}
var scenery_placements_by_region: Dictionary = {}
var active_scenery_region := Vector2i.ZERO
var item_pool: Array[ItemData] = []
var loot_random := RandomNumberGenerator.new()
## Counts down to bringing in the next straggler; starts at the arrival grace period.
var straggler_timer := STRAGGLER_ARRIVAL_GRACE


func _ready() -> void:
	var ground := get_node_or_null("../Background/Sprite2D") as Sprite2D
	if ground != null:
		if biome == 0:
			# Same grass as Oblath, a shade darker under the canopy.
			ground.texture = FOREST_GROUND_TEXTURE
			ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			ground.modulate = FOREST_GROUND_TINT
		elif biome == 1:
			ground.texture = DESERT_GROUND_TEXTURE
			ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			ground.scale = Vector2.ONE * DESERT_GROUND_SCALE
		elif biome == 2:
			ground.texture = ICE_GROUND_TEXTURE
			ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			ground.scale = Vector2.ONE * ICE_GROUND_SCALE
		elif biome == 3:
			ground.texture = UNDERWORLD_GROUND_TEXTURE
			ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			ground.scale = Vector2.ONE * UNDERWORLD_GROUND_SCALE

	player = get_node_or_null(player_path) as Player
	if player == null:
		push_error("LevelController could not find its player at %s." % player_path)
		set_physics_process(false)
		return

	player_camera = player.get_node_or_null("Camera2D") as Camera2D
	if player_camera == null:
		push_error("LevelController could not find the player's Camera2D.")
		set_physics_process(false)
		return

	region_size = get_viewport().get_visible_rect().size / player_camera.zoom
	if region_size.x <= 0.0 or region_size.y <= 0.0:
		push_error("LevelController requires a viewport with a non-zero size.")
		set_physics_process(false)
		return

	level_id = _get_level_id()
	var level_state: Dictionary = GameState.get_level_state(level_id)
	if level_state.is_empty():
		region_origin = player.global_position + player_camera.offset / player_camera.zoom
		current_region = _get_region_for_position(_get_camera_center())
	elif not _restore_level_state(level_state):
		level_state.clear()
		enemies_spawned = 0
		enemies_defeated = 0
		boss_spawned = false
		boss_wolves_defeated = 0
		spawned_enemy_regions.clear()
	last_player_position = player.global_position
	_create_item_pool()
	loot_random.randomize()
	_generate_nearby_scenery(current_region)
	if not level_state.is_empty():
		call_deferred("_restore_active_enemies", level_state.get("enemies", []))
		call_deferred("_restore_level_drops", level_state.get("drops", []))
	player.died.connect(_on_player_died)
	if biome == 0:
		get_parent().add_child.call_deferred(ForestAmbience.new())
	elif biome == 1:
		get_parent().add_child.call_deferred(DesertAmbience.new())
	elif biome == 2:
		get_parent().add_child.call_deferred(IceAmbience.new())
	elif biome == 3:
		get_parent().add_child.call_deferred(UnderworldAmbience.new())
	call_deferred("_emit_initial_progress")


func _emit_initial_progress() -> void:
	progress_changed.emit(enemies_defeated, _get_max_enemies())
	if biome == 0 and boss_spawned:
		boss_progress_changed.emit(boss_wolves_defeated, FOREST_BOSS_PACK_SIZE)
	elif _has_level_boss() and boss_spawned:
		boss_progress_changed.emit(0, 1)


func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED]:
		save_current_level_state()


func _restore_level_state(level_state: Dictionary) -> bool:
	var saved_spawned: Variant = level_state.get("enemies_spawned", 0)
	var saved_defeated: Variant = level_state.get("enemies_defeated", 0)
	if typeof(saved_spawned) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(saved_defeated) not in [TYPE_INT, TYPE_FLOAT]:
		push_error("Saved level enemy counts are invalid.")
		GameState.clear_level_state(level_id)
		region_origin = player.global_position + player_camera.offset / player_camera.zoom
		current_region = _get_region_for_position(_get_camera_center())
		return false

	enemies_spawned = clampi(int(saved_spawned), 0, _get_max_enemies())
	enemies_defeated = clampi(int(saved_defeated), 0, enemies_spawned)
	boss_spawned = bool(level_state.get("boss_spawned", false))
	var saved_boss_defeated: Variant = level_state.get("boss_wolves_defeated", 0)
	if typeof(saved_boss_defeated) in [TYPE_INT, TYPE_FLOAT]:
		boss_wolves_defeated = clampi(int(saved_boss_defeated), 0, FOREST_BOSS_PACK_SIZE)
	var saved_origin: Variant = _vector_from_record(
		level_state.get("region_origin", []),
		"region origin"
	)
	if saved_origin == null:
		GameState.clear_level_state(level_id)
		region_origin = player.global_position + player_camera.offset / player_camera.zoom
		current_region = _get_region_for_position(_get_camera_center())
		return false
	region_origin = Vector2(saved_origin)

	var saved_region: Variant = level_state.get("current_region", [])
	if typeof(saved_region) == TYPE_ARRAY and saved_region.size() == 2:
		current_region = Vector2i(int(saved_region[0]), int(saved_region[1]))
	else:
		current_region = _get_region_for_position(_get_camera_center())

	var saved_regions: Variant = level_state.get("spawned_enemy_regions", [])
	if typeof(saved_regions) != TYPE_ARRAY:
		push_error("Saved cleared-area list is invalid.")
		GameState.clear_level_state(level_id)
		return false
	for saved_region_entry in saved_regions:
		if typeof(saved_region_entry) != TYPE_ARRAY or saved_region_entry.size() != 2:
			push_error("Ignoring an invalid saved cleared area.")
			continue
		spawned_enemy_regions[_region_key(
			Vector2i(int(saved_region_entry[0]), int(saved_region_entry[1]))
		)] = true
	return true


func save_current_level_state() -> bool:
	if level_id == 0:
		push_error("Cannot save level state for an unsupported scene.")
		return false
	if level_is_complete:
		return true

	var enemy_records: Array[Dictionary] = []
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		var enemy := enemy_node as Wolf
		# Imps an Archdemon summons are part of its fight, not the level's tally.
		if enemy == null or enemy.health <= 0.0 or enemy.scene_file_path.is_empty() \
				or enemy.has_meta(Archdemon.SUMMONED_META):
			continue
		enemy_records.append({
			"scene_path": enemy.scene_file_path,
			"position": [enemy.global_position.x, enemy.global_position.y],
			"health": enemy.health,
			"modifiers": enemy.modifier_ids,
			"boss_role": str(enemy.get_meta(BOSS_ROLE_META, ""))
		})

	var drop_records: Array[Dictionary] = []
	for drop_node in get_tree().get_nodes_in_group("level_drops"):
		var item_pickup := drop_node as ItemPickup
		if item_pickup != null:
			if item_pickup.item == null:
				push_error("Cannot save an item pickup without item data.")
				continue
			drop_records.append({
				"type": "item",
				"position": [item_pickup.global_position.x, item_pickup.global_position.y],
				"item": _item_to_record(item_pickup.item)
			})
			continue

		var gold_pickup := drop_node as GoldPickup
		if gold_pickup != null:
			drop_records.append({
				"type": "gold",
				"position": [gold_pickup.global_position.x, gold_pickup.global_position.y],
				"amount": gold_pickup.amount
			})

	var cleared_regions: Array[Array] = []
	for region_key in spawned_enemy_regions:
		var coordinates := str(region_key).split(",")
		if coordinates.size() == 2:
			cleared_regions.append([coordinates[0].to_int(), coordinates[1].to_int()])

	var level_state := {
		"enemies_spawned": enemies_spawned,
		"enemies_defeated": enemies_defeated,
		"boss_spawned": boss_spawned,
		"boss_wolves_defeated": boss_wolves_defeated,
		"player_position": [player.global_position.x, player.global_position.y],
		"region_origin": [region_origin.x, region_origin.y],
		"current_region": [current_region.x, current_region.y],
		"spawned_enemy_regions": cleared_regions,
		"enemies": enemy_records,
		"drops": drop_records
	}
	if not GameState.set_level_state(level_id, level_state):
		push_error("Could not persist progress for level %d." % level_id)
		return false
	return true


func _save_level_state() -> void:
	if not save_current_level_state():
		push_error("Could not save the current level state.")


func _restore_active_enemies(raw_enemies: Variant) -> void:
	if typeof(raw_enemies) != TYPE_ARRAY:
		push_error("Saved active enemy list is invalid.")
		return

	for raw_enemy in raw_enemies:
		if typeof(raw_enemy) != TYPE_DICTIONARY:
			push_error("Ignoring an invalid saved enemy.")
			continue
		var enemy_record: Dictionary = raw_enemy
		var scene_path: Variant = enemy_record.get("scene_path", null)
		var saved_health: Variant = enemy_record.get("health", null)
		if typeof(scene_path) != TYPE_STRING \
				or typeof(saved_health) not in [TYPE_INT, TYPE_FLOAT]:
			push_error("Ignoring saved enemy with invalid fields.")
			continue
		var boss_role := str(enemy_record.get("boss_role", ""))
		if boss_role in ["alpha", "pack"]:
			var boss_position: Variant = _vector_from_record(
				enemy_record.get("position", []),
				"boss wolf position"
			)
			if boss_position != null:
				_spawn_boss_wolf(_clear_of_arrival(Vector2(boss_position)), boss_role == "alpha", float(saved_health))
			continue
		var enemy_scene := _get_enemy_scene(str(scene_path))
		if enemy_scene == null:
			push_error("Ignoring saved enemy with unsupported scene '%s'." % scene_path)
			continue
		var enemy := enemy_scene.instantiate() as Wolf
		if enemy == null:
			push_error("Saved enemy scene '%s' does not use the Wolf script." % scene_path)
			continue
		var enemy_position: Variant = _vector_from_record(
			enemy_record.get("position", []),
			"enemy position"
		)
		if enemy_position == null:
			enemy.free()
			continue

		enemy.target_path = NodePath("../Player")
		enemy.modifier_ids = MonsterModifiers.sanitize(enemy_record.get("modifiers", []))
		if str(scene_path) in LEVEL_BOSS_SCENES:
			enemy.always_alert = true
			enemy.died.connect(_on_level_boss_died.bind(enemy))
		else:
			enemy.died.connect(_on_enemy_died.bind(enemy))
		get_parent().add_child(enemy)
		enemy.global_position = _clear_of_arrival(Vector2(enemy_position))
		enemy.health = clampf(float(saved_health), 0.0, enemy.max_health)
		var health_bar := enemy.get_node_or_null("HealthBar") as ProgressBar
		if health_bar != null:
			health_bar.value = enemy.health


## Moves a restored monster that would be waiting on top of the player's arrival point out to
## ARRIVAL_CLEARANCE, so returning to a level never drops the player into a fight.
func _clear_of_arrival(world_position: Vector2) -> Vector2:
	var offset := world_position - player.global_position
	if offset.length() >= ARRIVAL_CLEARANCE:
		return world_position
	var direction := offset.normalized() if not offset.is_zero_approx() else Vector2.RIGHT.rotated(randf() * TAU)
	return player.global_position + direction * ARRIVAL_CLEARANCE


func _restore_level_drops(raw_drops: Variant) -> void:
	if typeof(raw_drops) != TYPE_ARRAY:
		push_error("Saved level drop list is invalid.")
		return

	for raw_drop in raw_drops:
		if typeof(raw_drop) != TYPE_DICTIONARY:
			push_error("Ignoring an invalid saved level drop.")
			continue
		var drop_record: Dictionary = raw_drop
		var drop_type: Variant = drop_record.get("type", null)
		var drop_position: Variant = _vector_from_record(
			drop_record.get("position", []),
			"drop position"
		)
		if drop_position == null:
			continue

		match drop_type:
			"gold":
				var amount: Variant = drop_record.get("amount", null)
				if typeof(amount) not in [TYPE_INT, TYPE_FLOAT] \
						or int(amount) < 1 or int(amount) > GoldPickup.MAX_AMOUNT:
					push_error("Ignoring saved gold pickup with invalid amount.")
					continue
				_spawn_gold_pickup(drop_position, int(amount))
			"item":
				var item_record: Variant = drop_record.get("item", null)
				if typeof(item_record) != TYPE_DICTIONARY:
					push_error("Ignoring saved item pickup with invalid item data.")
					continue
				var item := _item_from_record(item_record)
				if item == null:
					continue
				_spawn_item_pickup(item, drop_position)
			_:
				push_error("Ignoring saved pickup with unsupported type '%s'." % drop_type)


func _item_to_record(item: ItemData) -> Dictionary:
	return {
		"display_name": item.display_name,
		"equipment_slot": item.equipment_slot,
		"icon_color": item.icon_color.to_html(true),
		"damage_bonus": item.damage_bonus,
		"damage_reduction": item.damage_reduction,
		"price": item.price
	}


func _item_from_record(raw_item: Dictionary) -> ItemData:
	var display_name: Variant = raw_item.get("display_name", null)
	var equipment_slot: Variant = raw_item.get("equipment_slot", null)
	var icon_color: Variant = raw_item.get("icon_color", null)
	var damage_bonus: Variant = raw_item.get("damage_bonus", null)
	var damage_reduction: Variant = raw_item.get("damage_reduction", null)
	var price: Variant = raw_item.get("price", null)
	if typeof(display_name) != TYPE_STRING \
			or typeof(equipment_slot) != TYPE_STRING \
			or typeof(icon_color) != TYPE_STRING \
			or typeof(damage_bonus) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(damage_reduction) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(price) not in [TYPE_INT, TYPE_FLOAT]:
		push_error("Ignoring saved item pickup with invalid item fields.")
		return null

	var item := ItemData.new()
	item.display_name = display_name
	item.equipment_slot = equipment_slot
	item.icon_color = Color.from_string(icon_color, Color.WHITE)
	item.damage_bonus = int(damage_bonus)
	item.damage_reduction = int(damage_reduction)
	item.price = int(price)
	return item


func _get_enemy_scene(scene_path: String) -> PackedScene:
	if LEGACY_ENEMY_SCENES.has(scene_path):
		scene_path = LEGACY_ENEMY_SCENES[scene_path]
	match scene_path:
		"res://wolf.tscn":
			return WOLF_SCENE
		"res://scorpion.tscn":
			return SCORPION_SCENE
		"res://snake.tscn":
			return SNAKE_SCENE
		"res://frostbound_wraith.tscn":
			return FROSTBOUND_WRAITH_SCENE
		"res://crystalback_yeti.tscn":
			return CRYSTALBACK_YETI_SCENE
		"res://shiverfang_ice_serpent.tscn":
			return SHIVERFANG_ICE_SERPENT_SCENE
		"res://imp.tscn":
			return IMP_SCENE
		"res://hellhound.tscn":
			return HELLHOUND_SCENE
		"res://fire_fiend.tscn":
			return FIRE_FIEND_SCENE
		"res://archdemon.tscn":
			return ARCHDEMON_SCENE
		"res://desert_boss.tscn":
			return DESERT_BOSS_SCENE
		"res://ice_golem.tscn":
			return ICE_GOLEM_SCENE
		"res://ice_boss.tscn":
			return ICE_BOSS_SCENE
	return null


func _vector_from_record(value: Variant, field_name: String) -> Variant:
	if typeof(value) != TYPE_ARRAY or value.size() != 2 \
			or typeof(value[0]) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(value[1]) not in [TYPE_INT, TYPE_FLOAT]:
		push_error("Saved %s is invalid." % field_name)
		return null
	return Vector2(float(value[0]), float(value[1]))


func _region_key(region: Vector2i) -> String:
	return "%d,%d" % [region.x, region.y]


func _get_level_id() -> int:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return 0
	return GameState.get_level_id(current_scene.scene_file_path)


func _physics_process(delta: float) -> void:
	if enemies_spawned >= _get_max_enemies():
		_call_in_straggler(delta)
		return

	var camera_center := _get_camera_center()
	var entered_region := _get_region_for_position(camera_center)
	if entered_region != current_region:
		var movement := player.global_position - last_player_position
		_generate_nearby_scenery(entered_region)
		var region_key := _region_key(entered_region)
		if movement.length_squared() > 0.0 and not spawned_enemy_regions.has(region_key):
			if _spawn_enemy(movement.normalized()):
				spawned_enemy_regions[region_key] = true
				_save_level_state()
		current_region = entered_region

	last_player_position = player.global_position


## With nothing left to spawn, moves one survivor that is waiting out of range to just off-screen and sets
## it on the player, so the last monsters of a level never have to be hunted down across the map.
func _call_in_straggler(delta: float) -> void:
	straggler_timer -= delta
	if straggler_timer > 0.0:
		return
	straggler_timer = STRAGGLER_INTERVAL
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Wolf
		if enemy == null or enemy.health <= 0.0 or enemy.is_alert:
			continue
		var direction := Vector2.RIGHT.rotated(randf() * TAU)
		enemy.global_position = player.global_position + direction * _get_spawn_distance(direction)
		enemy.alert()
		return


func _generate_nearby_scenery(center_region: Vector2i) -> void:
	for x_offset in range(-SCENERY_PRELOAD_RADIUS, SCENERY_PRELOAD_RADIUS + 1):
		for y_offset in range(-SCENERY_PRELOAD_RADIUS, SCENERY_PRELOAD_RADIUS + 1):
			_generate_scenery_for_region(center_region + Vector2i(x_offset, y_offset))


func _create_item_pool() -> void:
	item_pool = GameState.get_vendor_items()


## drop_offset is where the drop hops out of (the monster) relative to world_position; zero places it without a hop.
func _spawn_item_pickup(item: ItemData, world_position: Vector2, drop_offset := Vector2.ZERO) -> void:
	var pickup := ITEM_PICKUP_SCENE.instantiate() as ItemPickup
	if pickup == null:
		push_error("The item pickup scene root must use the ItemPickup script.")
		return

	pickup.item = item
	pickup.drop_offset = drop_offset
	pickup.collected.connect(_save_level_state)
	get_parent().add_child(pickup)
	pickup.global_position = world_position


func _spawn_gold_pickup(world_position: Vector2, amount := 0, drop_offset := Vector2.ZERO) -> void:
	var pickup := GOLD_PICKUP_SCENE.instantiate() as GoldPickup
	if pickup == null:
		push_error("The gold pickup scene root must use the GoldPickup script.")
		return

	pickup.amount = amount if amount > 0 else loot_random.randi_range(1, 3)
	pickup.drop_offset = drop_offset
	pickup.collected.connect(_save_level_state)
	get_parent().add_child(pickup)
	pickup.global_position = world_position


func _generate_scenery_for_region(region: Vector2i) -> void:
	if generated_scenery_regions.has(region):
		return
	generated_scenery_regions[region] = true
	active_scenery_region = region

	var random := RandomNumberGenerator.new()
	random.seed = int(region.x) * 73856093 ^ int(region.y) * 19349663
	var region_center := region_origin + Vector2(region) * region_size

	if biome == 1:
		_generate_desert_scenery(random, region_center)
		return
	if biome == 2:
		_generate_ice_scenery(random, region_center)
		return
	if biome == 3:
		_generate_underworld_scenery(random, region_center)
		return
	_generate_forest_scenery(random, region, region_center)


func _generate_forest_scenery(random: RandomNumberGenerator, region: Vector2i, region_center: Vector2) -> void:
	# Regions tile edge to edge, so forest props may use the whole region.
	var spread := region_size * 0.48
	var floor_detail := ForestFloor.new()
	floor_detail.seed_value = random.randi()
	floor_detail.half_extents = region_size * 0.5
	floor_detail.position = region_center
	floor_detail.z_index = -8
	get_parent().call_deferred("add_child", floor_detail)

	var apple_index := FOREST_APPLE_TREE_REGIONS.find(region)
	if apple_index >= 0:
		_add_forest_apple_tree(random, apple_index, region_center, spread)

	if random.randf() < 0.5:
		var landmark: Dictionary = FOREST_LANDMARKS[random.randi() % FOREST_LANDMARKS.size()]
		var collision: float = landmark["collision"]
		_try_add_prop(random, landmark, region_center, spread * 0.8, Vector2(collision, collision * 0.5), collision)

	for _tree_index in random.randi_range(6, 9):
		var tree: Dictionary = FOREST_TREES[random.randi() % FOREST_TREES.size()]
		var trunk: float = tree["trunk"]
		_try_add_prop(random, tree, region_center, spread, Vector2(trunk + 30.0, 16.0), trunk)

	for _debris_index in random.randi_range(1, 3):
		var debris: Dictionary = FOREST_DEBRIS[random.randi() % FOREST_DEBRIS.size()]
		var collision: float = debris["collision"]
		_try_add_prop(random, debris, region_center, spread, Vector2(collision + 10.0, 10.0), collision)

	for _plant_index in random.randi_range(4, 7):
		var plant: Dictionary = FOREST_UNDERGROWTH[random.randi() % FOREST_UNDERGROWTH.size()]
		_try_add_prop(random, plant, region_center, spread, Vector2(12.0, 8.0))

	for _cover_index in random.randi_range(6, 10):
		var cover: Dictionary = FOREST_GROUND_COVER[random.randi() % FOREST_GROUND_COVER.size()]
		var scale_range: Vector2 = cover["scale"]
		_add_flat_sprite(
			cover["texture"],
			region_center + _random_region_offset(random, spread),
			random.randf_range(scale_range.x, scale_range.y),
			-4
		)


func _add_forest_apple_tree(random: RandomNumberGenerator, apple_index: int, region_center: Vector2, spread: Vector2) -> void:
	for _attempt in 32:
		var base_position := region_center + _random_region_offset(random, spread * 0.8)
		if not _claim_prop_spot(base_position, Vector2(34.0, 14.0)):
			continue
		var apple_tree := APPLE_TREE_SCENE.instantiate() as AppleTree
		apple_tree.tree_index = apple_index
		apple_tree.position = base_position
		apple_tree.get_node("Sprite2D").scale = Vector2.ONE * FOREST_APPLE_TREE_SCALE
		get_parent().call_deferred("add_child", apple_tree)
		return
	push_warning("No room for forest apple tree %d." % apple_index)


## Places a standing prop at a free random spot, with a solid base when collision_radius > 0 and a
## sun shadow on the sand when cast_shadow is set.
func _try_add_prop(
	random: RandomNumberGenerator,
	prop: Dictionary,
	region_center: Vector2,
	spread: Vector2,
	footprint: Vector2,
	collision_radius := 0.0,
	cast_shadow := false
) -> void:
	var scale_range: Vector2 = prop["scale"]
	var uniform_scale := random.randf_range(scale_range.x, scale_range.y)
	for _attempt in 12:
		var base_position := region_center + _random_region_offset(random, spread)
		if not _claim_prop_spot(base_position, footprint * maxf(uniform_scale, 0.6), collision_radius > 0.0):
			continue
		var sprite := _make_standing_sprite(prop["texture"], uniform_scale)
		if prop.has("flame"):
			_ignite(sprite, prop["flame"])
		if cast_shadow:
			_add_prop_shadow(sprite)
		if collision_radius <= 0.0:
			sprite.position = base_position
			get_parent().call_deferred("add_child", sprite)
			return
		var obstacle := StaticBody2D.new()
		obstacle.collision_mask = 0
		obstacle.position = base_position
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = collision_radius * maxf(uniform_scale, 0.6)
		collision.shape = shape
		# The circle sits on the ground just behind the prop's base.
		collision.position = Vector2(0.0, -shape.radius * 0.6)
		obstacle.add_child(collision)
		obstacle.add_child(sprite)
		get_parent().call_deferred("add_child", obstacle)
		return


## Flat ground cover drawn below characters; it may overlap anything.
func _add_flat_sprite(texture: Texture2D, world_position: Vector2, uniform_scale: float, z := 0) -> void:
	var sprite := _make_standing_sprite(texture, uniform_scale)
	sprite.position = world_position
	sprite.z_index = z
	get_parent().call_deferred("add_child", sprite)


## A sprite whose node origin is the bottom of the art, so y-sorting treats it as standing on the ground.
func _make_standing_sprite(texture: Texture2D, uniform_scale: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * uniform_scale
	sprite.offset = Vector2(0.0, -texture.get_height() * 0.5)
	return sprite


## Reserves a footprint (half size, resting on base_position) if it is clear of other props and,
## for solid props, of the player's entry point.
func _claim_prop_spot(base_position: Vector2, footprint: Vector2, solid := true) -> bool:
	var center := base_position - Vector2(0.0, footprint.y)
	var entry_point := region_origin - player_camera.offset / player_camera.zoom
	if solid and center.distance_to(entry_point) < PROP_SPAWN_CLEARING + footprint.x:
		return false
	if not _has_scenery_clearance(center, footprint):
		return false
	var placements: Array = scenery_placements_by_region.get(active_scenery_region, [])
	placements.append({"position": center, "half_size": footprint})
	scenery_placements_by_region[active_scenery_region] = placements
	return true


func _generate_desert_scenery(random: RandomNumberGenerator, region_center: Vector2) -> void:
	# Regions tile edge to edge, so desert props may use the whole region.
	var spread := region_size * 0.48
	var floor_detail := DesertFloor.new()
	floor_detail.seed_value = random.randi()
	floor_detail.half_extents = region_size * 0.5
	floor_detail.position = region_center
	floor_detail.z_index = -8
	get_parent().call_deferred("add_child", floor_detail)

	for _decal_index in random.randi_range(4, 6):
		var decal: Dictionary = DESERT_GROUND_DECALS[random.randi() % DESERT_GROUND_DECALS.size()]
		var scale_range: Vector2 = decal["scale"]
		var sprite := _make_standing_sprite(decal["texture"], random.randf_range(scale_range.x, scale_range.y))
		sprite.position = region_center + _random_region_offset(random, spread)
		sprite.flip_h = random.randf() < 0.5
		sprite.z_index = -6
		get_parent().call_deferred("add_child", sprite)

	if random.randf() < 0.55:
		var landmark: Dictionary = DESERT_LANDMARKS[random.randi() % DESERT_LANDMARKS.size()]
		var collision: float = landmark["collision"]
		_try_add_prop(random, landmark, region_center, spread * 0.8, Vector2(collision, collision * 0.5), collision, true)

	if random.randf() < 0.5:
		_try_add_cluster(random, _make_rock_outcrop(random), region_center, spread * 0.85, Vector2(80.0, 34.0))
	if random.randf() < 0.3:
		_try_add_cluster(random, _make_ruins(random), region_center, spread * 0.8, Vector2(160.0, 52.0))
	for _stand_index in random.randi_range(3, 4):
		_try_add_cluster(random, _make_cactus_stand(random), region_center, spread, Vector2(60.0, 26.0))
	for _patch_index in random.randi_range(1, 2):
		_try_add_cluster(random, _make_plant_patch(random), region_center, spread, Vector2(50.0, 22.0))

	for _cactus_index in random.randi_range(5, 8):
		var cactus: Dictionary = DESERT_CACTI[random.randi() % DESERT_CACTI.size()]
		var trunk: float = cactus["trunk"]
		_try_add_prop(random, cactus, region_center, spread, Vector2(trunk + 18.0, 12.0), trunk, true)

	for _rock_index in random.randi_range(1, 2):
		var rock: Dictionary = DESERT_ROCKS[random.randi() % DESERT_ROCKS.size()]
		var collision: float = rock["collision"]
		_try_add_prop(random, rock, region_center, spread, Vector2(collision + 10.0, 10.0), collision, true)

	for _brush_index in random.randi_range(7, 11):
		var brush: Dictionary = DESERT_BRUSH[random.randi() % DESERT_BRUSH.size()]
		_try_add_prop(random, brush, region_center, spread, Vector2(12.0, 8.0), 0.0, true)


## A rocky outcrop: one tall spire or rock heap with smaller rocks and scrub gathered around its base.
func _make_rock_outcrop(random: RandomNumberGenerator) -> Array[Dictionary]:
	var spire: Dictionary = DESERT_OUTCROP_SPIRES[random.randi() % DESERT_OUTCROP_SPIRES.size()]
	var pieces: Array[Dictionary] = [{
		"texture": spire["texture"], "scale": _random_scale(random, spire),
		"offset": Vector2.ZERO, "collision": spire["collision"],
	}]
	for _rock in random.randi_range(2, 3):
		var rock: Dictionary = DESERT_ROCKS[random.randi() % DESERT_ROCKS.size()]
		pieces.append({
			"texture": rock["texture"], "scale": random.randf_range(1.0, 1.3),
			"offset": _cluster_offset(random, 30.0, 58.0), "collision": rock["collision"],
		})
	for _scrub in random.randi_range(1, 2):
		var brush: Dictionary = DESERT_BRUSH[random.randi() % DESERT_BRUSH.size()]
		pieces.append({
			"texture": brush["texture"], "scale": _random_scale(random, brush),
			"offset": _cluster_offset(random, 50.0, 76.0), "collision": 0.0,
		})
	return pieces


## Ruins: a crumbling wall with weathered pillars and rubble scattered around it.
func _make_ruins(random: RandomNumberGenerator) -> Array[Dictionary]:
	var pieces: Array[Dictionary] = [{
		"texture": DESERT_RUIN_WALL, "scale": random.randf_range(1.0, 1.15),
		"offset": Vector2.ZERO, "collision": 34.0,
	}]
	for index in random.randi_range(2, 4):
		# Pillars stand in a loose row, as if they once held up a roof.
		var side := -1.0 if index % 2 == 0 else 1.0
		pieces.append({
			"texture": DESERT_PILLARS[random.randi() % DESERT_PILLARS.size()],
			"scale": random.randf_range(0.9, 1.05),
			"offset": Vector2(side * random.randf_range(75.0, 115.0), random.randf_range(-24.0, 30.0)),
			"collision": 11.0,
		})
	for _rubble in random.randi_range(1, 2):
		pieces.append({
			"texture": DESERT_RUBBLE_LOW, "scale": random.randf_range(0.8, 1.0),
			"offset": _cluster_offset(random, 50.0, 90.0), "collision": 0.0,
		})
	return pieces


## A stand of cacti: one tall saguaro with smaller cacti and scrub at its feet.
func _make_cactus_stand(random: RandomNumberGenerator) -> Array[Dictionary]:
	var pieces: Array[Dictionary] = [{
		"texture": DESERT_STAND_SAGUAROS[random.randi() % DESERT_STAND_SAGUAROS.size()],
		"scale": random.randf_range(1.5, 1.75), "offset": Vector2.ZERO, "collision": 9.0,
	}]
	for _cactus in random.randi_range(1, 2):
		var cactus: Dictionary = DESERT_CACTI[random.randi() % DESERT_CACTI.size()]
		pieces.append({
			"texture": cactus["texture"], "scale": _random_scale(random, cactus) * 0.8,
			"offset": _cluster_offset(random, 28.0, 52.0), "collision": cactus["trunk"],
		})
	for _scrub in random.randi_range(1, 2):
		var brush: Dictionary = DESERT_BRUSH[random.randi() % DESERT_BRUSH.size()]
		pieces.append({
			"texture": brush["texture"], "scale": _random_scale(random, brush) * 0.9,
			"offset": _cluster_offset(random, 36.0, 64.0), "collision": 0.0,
		})
	return pieces


## A patch of low desert plants growing together.
func _make_plant_patch(random: RandomNumberGenerator) -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	for index in random.randi_range(3, 5):
		var plant: Dictionary = DESERT_PATCH_PLANTS[random.randi() % DESERT_PATCH_PLANTS.size()]
		pieces.append({
			"texture": plant["texture"], "scale": _random_scale(random, plant),
			"offset": Vector2.ZERO if index == 0 else _cluster_offset(random, 22.0, 48.0),
			"collision": plant["collision"],
		})
	return pieces


## A scale within a prop table entry.s "scale" range.
func _random_scale(random: RandomNumberGenerator, prop: Dictionary) -> float:
	var scale_range: Vector2 = prop["scale"]
	return random.randf_range(scale_range.x, scale_range.y)


## A spot around a cluster's centre, flattened for the top-down view.
func _cluster_offset(random: RandomNumberGenerator, min_radius: float, max_radius: float) -> Vector2:
	var angle := random.randf() * TAU
	return Vector2(cos(angle), sin(angle) * 0.5) * random.randf_range(min_radius, max_radius)


## Places a group of props as one solid set piece. Each piece is {texture, scale, offset, collision};
## pieces with collision > 0 get their own collision circle.
func _try_add_cluster(
	random: RandomNumberGenerator,
	pieces: Array[Dictionary],
	region_center: Vector2,
	spread: Vector2,
	footprint: Vector2
) -> void:
	for _attempt in 12:
		var base_position := region_center + _random_region_offset(random, spread)
		if not _claim_prop_spot(base_position, footprint):
			continue
		var cluster := StaticBody2D.new()
		cluster.collision_mask = 0
		cluster.position = base_position
		# Pieces further back are drawn first so nearer ones overlap them.
		pieces.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["offset"].y < b["offset"].y)
		for piece in pieces:
			var piece_scale: float = piece["scale"]
			var sprite := _make_standing_sprite(piece["texture"], piece_scale)
			sprite.position = piece["offset"]
			sprite.flip_h = random.randf() < 0.5
			_add_prop_shadow(sprite)
			if piece.has("flame"):
				_ignite(sprite, piece["flame"])
			cluster.add_child(sprite)
			var collision_radius: float = piece["collision"]
			if collision_radius > 0.0:
				var collision := CollisionShape2D.new()
				var shape := CircleShape2D.new()
				shape.radius = collision_radius * piece_scale
				collision.shape = shape
				collision.position = sprite.position + Vector2(0.0, -shape.radius * 0.6)
				cluster.add_child(collision)
		get_parent().call_deferred("add_child", cluster)
		return


## A shadow on the ground under a standing sprite (origin at the bottom of its art): warm on sand,
## cold blue on snow, sooty in the underworld.
func _add_prop_shadow(sprite: Sprite2D) -> void:
	var color := SunShadow.COLOR
	if biome == 2:
		color = IceCreature.SHADOW_COLOR
	elif biome == 3:
		color = SOOT_SHADOW
	SunShadow.attach(sprite, Vector2(0.0, -2.0), sprite.texture.get_width() * 1.1, true, color)


func _generate_ice_scenery(random: RandomNumberGenerator, region_center: Vector2) -> void:
	# Regions tile edge to edge, so ice props may use the whole region.
	var spread := region_size * 0.48
	var floor_detail := IceFloor.new()
	floor_detail.seed_value = random.randi()
	floor_detail.half_extents = region_size * 0.5
	floor_detail.position = region_center
	floor_detail.z_index = -8
	get_parent().call_deferred("add_child", floor_detail)

	for _decal_index in random.randi_range(3, 5):
		var decal: Dictionary = ICE_GROUND_DECALS[random.randi() % ICE_GROUND_DECALS.size()]
		var sprite := _make_standing_sprite(decal["texture"], _random_scale(random, decal))
		sprite.position = region_center + _random_region_offset(random, spread)
		sprite.flip_h = random.randf() < 0.5
		sprite.z_index = -6
		get_parent().call_deferred("add_child", sprite)

	for _drift_index in random.randi_range(1, 2):
		var drift: Dictionary = ICE_DRIFTS[random.randi() % ICE_DRIFTS.size()]
		var drift_sprite := _make_standing_sprite(drift["texture"], _random_scale(random, drift))
		drift_sprite.position = region_center + _random_region_offset(random, spread)
		drift_sprite.flip_h = random.randf() < 0.5
		drift_sprite.z_index = -4
		get_parent().call_deferred("add_child", drift_sprite)

	var landmark_roll := random.randf()
	if landmark_roll < 0.3:
		_try_add_cluster(random, _make_frozen_ruins(random), region_center, spread * 0.8, Vector2(130.0, 48.0))
	elif landmark_roll < 0.55:
		var block := {"texture": ICE_BLOCK, "scale": Vector2(0.75, 0.9)}
		_try_add_prop(random, block, region_center, spread * 0.8, Vector2(52.0, 26.0), 44.0, true)

	if random.randf() < 0.5:
		_try_add_cluster(random, _make_ice_outcrop(random), region_center, spread * 0.85, Vector2(70.0, 30.0))
	for _garden_index in random.randi_range(1, 2):
		_try_add_cluster(random, _make_crystal_garden(random), region_center, spread, Vector2(56.0, 24.0))
	if random.randf() < 0.45:
		_try_add_cluster(random, _make_stump_grove(random), region_center, spread, Vector2(64.0, 26.0))

	for _rock_index in random.randi_range(3, 4):
		var rock: Dictionary = ICE_ROCKS[random.randi() % ICE_ROCKS.size()]
		var collision: float = rock["collision"]
		_try_add_prop(random, rock, region_center, spread, Vector2(collision + 6.0, 10.0), collision, true)
	for _crystal_index in random.randi_range(2, 3):
		var crystal: Dictionary = ICE_CRYSTALS[random.randi() % ICE_CRYSTALS.size()]
		var crystal_collision: float = crystal["collision"]
		_try_add_prop(random, crystal, region_center, spread, Vector2(crystal_collision + 10.0, 10.0), crystal_collision, true)
	for _stump_index in random.randi_range(1, 2):
		var stump: Dictionary = ICE_STUMPS[random.randi() % ICE_STUMPS.size()]
		var stump_collision: float = stump["collision"]
		_try_add_prop(random, stump, region_center, spread, Vector2(stump_collision + 8.0, 10.0), stump_collision, true)
	if random.randf() < 0.7:
		var spire: Dictionary = ICE_STALAGMITES[random.randi() % ICE_STALAGMITES.size()]
		var spire_collision: float = spire["collision"]
		_try_add_prop(random, spire, region_center, spread, Vector2(spire_collision + 10.0, 10.0), spire_collision, true)
	for _pile_index in random.randi_range(4, 6):
		var pile: Dictionary = ICE_SNOW_PILES[random.randi() % ICE_SNOW_PILES.size()]
		_try_add_prop(random, pile, region_center, spread, Vector2(16.0, 8.0), 0.0, true)


## Frozen ruins: carved ice columns in a loose row, with crystals and snow heaped around their feet.
func _make_frozen_ruins(random: RandomNumberGenerator) -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	var column_count := random.randi_range(2, 4)
	for index in column_count:
		# Columns stand in a row, as if they once held up a roof; some have fallen.
		var x := (index - (column_count - 1) * 0.5) * random.randf_range(62.0, 80.0)
		pieces.append({
			"texture": ICE_PILLARS[random.randi() % ICE_PILLARS.size()],
			"scale": random.randf_range(0.85, 1.0),
			"offset": Vector2(x, random.randf_range(-10.0, 14.0)),
			"collision": 12.0,
		})
	for _crystal in random.randi_range(1, 2):
		var crystal: Dictionary = ICE_CRYSTALS[random.randi() % 3]
		pieces.append({
			"texture": crystal["texture"], "scale": _random_scale(random, crystal) * 0.85,
			"offset": _cluster_offset(random, 50.0, 100.0), "collision": crystal["collision"],
		})
	for _pile in random.randi_range(1, 2):
		var pile: Dictionary = ICE_SNOW_PILES[random.randi() % ICE_SNOW_PILES.size()]
		pieces.append({
			"texture": pile["texture"], "scale": _random_scale(random, pile),
			"offset": _cluster_offset(random, 40.0, 110.0), "collision": 0.0,
		})
	return pieces


## A frosted rock outcrop: one cave spire with snowy boulders and a snow heap gathered at its base.
func _make_ice_outcrop(random: RandomNumberGenerator) -> Array[Dictionary]:
	var spire: Dictionary = ICE_STALAGMITES[random.randi() % ICE_STALAGMITES.size()]
	var pieces: Array[Dictionary] = [{
		"texture": spire["texture"], "scale": _random_scale(random, spire) * 1.2,
		"offset": Vector2.ZERO, "collision": spire["collision"],
	}]
	for _rock in random.randi_range(2, 3):
		var rock: Dictionary = ICE_ROCKS[random.randi() % ICE_ROCKS.size()]
		pieces.append({
			"texture": rock["texture"], "scale": _random_scale(random, rock),
			"offset": _cluster_offset(random, 34.0, 60.0), "collision": rock["collision"],
		})
	var pile: Dictionary = ICE_SNOW_PILES[random.randi() % ICE_SNOW_PILES.size()]
	pieces.append({
		"texture": pile["texture"], "scale": _random_scale(random, pile),
		"offset": _cluster_offset(random, 50.0, 76.0), "collision": 0.0,
	})
	return pieces


## A bed of ice crystals pushing up through the snow.
func _make_crystal_garden(random: RandomNumberGenerator) -> Array[Dictionary]:
	var centre: Dictionary = ICE_CRYSTALS[random.randi() % 3]
	var pieces: Array[Dictionary] = [{
		"texture": centre["texture"], "scale": _random_scale(random, centre),
		"offset": Vector2.ZERO, "collision": centre["collision"],
	}]
	for _spike in random.randi_range(1, 2):
		var spike: Dictionary = ICE_CRYSTALS[3 + random.randi() % 2]
		pieces.append({
			"texture": spike["texture"], "scale": _random_scale(random, spike) * 0.8,
			"offset": _cluster_offset(random, 26.0, 48.0), "collision": spike["collision"],
		})
	if random.randf() < 0.6:
		var pile: Dictionary = ICE_SNOW_PILES[random.randi() % ICE_SNOW_PILES.size()]
		pieces.append({
			"texture": pile["texture"], "scale": _random_scale(random, pile) * 0.85,
			"offset": _cluster_offset(random, 34.0, 60.0), "collision": 0.0,
		})
	return pieces


## What is left of a frozen grove: a few iced-over stumps half buried in snow.
func _make_stump_grove(random: RandomNumberGenerator) -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	for index in random.randi_range(2, 3):
		var stump: Dictionary = ICE_STUMPS[random.randi() % ICE_STUMPS.size()]
		pieces.append({
			"texture": stump["texture"], "scale": _random_scale(random, stump),
			"offset": Vector2.ZERO if index == 0 else _cluster_offset(random, 40.0, 70.0),
			"collision": stump["collision"],
		})
	for _pile in random.randi_range(1, 2):
		var pile: Dictionary = ICE_SNOW_PILES[random.randi() % ICE_SNOW_PILES.size()]
		pieces.append({
			"texture": pile["texture"], "scale": _random_scale(random, pile),
			"offset": _cluster_offset(random, 30.0, 64.0), "collision": 0.0,
		})
	return pieces


func _generate_underworld_scenery(random: RandomNumberGenerator, region_center: Vector2) -> void:
	# Regions tile edge to edge, so underworld props may use the whole region.
	var spread := region_size * 0.48
	var floor_detail := UnderworldFloor.new()
	floor_detail.seed_value = random.randi()
	floor_detail.half_extents = region_size * 0.5
	floor_detail.position = region_center
	floor_detail.z_index = -8
	get_parent().call_deferred("add_child", floor_detail)

	for _decal_index in random.randi_range(1, 3):
		var decal: Dictionary = UNDERWORLD_DECALS[random.randi() % UNDERWORLD_DECALS.size()]
		var sprite := _make_standing_sprite(decal["texture"], _random_scale(random, decal))
		sprite.position = region_center + _random_region_offset(random, spread)
		sprite.flip_h = random.randf() < 0.5
		sprite.z_index = -6
		get_parent().call_deferred("add_child", sprite)

	for _pool_index in random.randi_range(0, 2):
		_try_add_lava_pool(random, region_center, spread * 0.85)

	var landmark_roll := random.randf()
	if landmark_roll < 0.3:
		_try_add_cluster(random, _make_ruined_gate(random), region_center, spread * 0.8, Vector2(150.0, 50.0))
	elif landmark_roll < 0.55:
		_try_add_cluster(random, _make_dark_shrine(random), region_center, spread * 0.8, Vector2(140.0, 50.0))

	if random.randf() < 0.55:
		_try_add_cluster(random, _make_obsidian_outcrop(random), region_center, spread * 0.85, Vector2(80.0, 32.0))
	for _field_index in random.randi_range(1, 2):
		_try_add_cluster(random, _make_bone_field(random), region_center, spread, Vector2(64.0, 26.0))
	if random.randf() < 0.35:
		_try_add_cluster(random, _make_torture_yard(random), region_center, spread * 0.85, Vector2(110.0, 40.0))
	if random.randf() < 0.3:
		_try_add_cluster(random, _make_supply_cache(random), region_center, spread, Vector2(60.0, 24.0))

	for _spire_index in random.randi_range(2, 3):
		var spire: Dictionary = OBSIDIAN_SPIRES[random.randi() % OBSIDIAN_SPIRES.size()]
		var spire_collision: float = spire["collision"]
		_try_add_prop(random, spire, region_center, spread, Vector2(spire_collision + 10.0, 10.0), spire_collision, true)
	for _rock_index in random.randi_range(2, 3):
		var rock: Dictionary = OBSIDIAN_ROCKS[random.randi() % OBSIDIAN_ROCKS.size()]
		var rock_collision: float = rock["collision"]
		_try_add_prop(random, rock, region_center, spread, Vector2(rock_collision + 8.0, 10.0), rock_collision, true)
	for _fire_index in random.randi_range(1, 2):
		var fire: Dictionary = UNDERWORLD_FIRES[random.randi() % UNDERWORLD_FIRES.size()]
		var fire_collision: float = fire["collision"]
		_try_add_prop(random, fire, region_center, spread, Vector2(fire_collision + 10.0, 10.0), fire_collision, true)
	for _bones_index in random.randi_range(2, 3):
		var bones: Dictionary = UNDERWORLD_BONES[random.randi() % UNDERWORLD_BONES.size()]
		_try_add_prop(random, bones, region_center, spread, Vector2(18.0, 8.0), 0.0, true)


## A pool of lava set into the ground; it burns, so it keeps clear of props and the entry point.
func _try_add_lava_pool(random: RandomNumberGenerator, region_center: Vector2, spread: Vector2) -> void:
	var half_size := Vector2(random.randf_range(52.0, 96.0), 0.0)
	half_size.y = half_size.x * random.randf_range(0.42, 0.52)
	for _attempt in 12:
		var center := region_center + _random_region_offset(random, spread)
		if not _claim_prop_spot(center + Vector2(0.0, half_size.y), half_size * 1.15):
			continue
		var pool := LavaPool.new()
		pool.seed_value = random.randi()
		pool.half_size = half_size
		pool.position = center
		pool.z_index = -5
		get_parent().call_deferred("add_child", pool)
		return


## A ruined gateway: an arch flanked by pillars, with obsidian rubble strewn about.
func _make_ruined_gate(random: RandomNumberGenerator) -> Array[Dictionary]:
	var pieces: Array[Dictionary] = [{
		"texture": UNDERWORLD_ARCHES[random.randi() % UNDERWORLD_ARCHES.size()],
		"scale": random.randf_range(0.9, 1.05), "offset": Vector2.ZERO, "collision": 0.0,
	}]
	for side in [-1.0, 1.0]:
		if random.randf() < 0.75:
			var pillar: Dictionary = UNDERWORLD_PILLARS[random.randi() % 2]
			pieces.append({
				"texture": pillar["texture"], "scale": _random_scale(random, pillar),
				"offset": Vector2(side * random.randf_range(95.0, 125.0), random.randf_range(-6.0, 16.0)),
				"collision": pillar["collision"],
			})
	for _rubble in random.randi_range(1, 2):
		var rock: Dictionary = OBSIDIAN_ROCKS[random.randi() % OBSIDIAN_ROCKS.size()]
		pieces.append({
			"texture": rock["texture"], "scale": _random_scale(random, rock) * 0.85,
			"offset": _cluster_offset(random, 70.0, 120.0), "collision": rock["collision"],
		})
	return pieces


## A dark shrine: an altar watched over by gargoyles, lit by braziers.
func _make_dark_shrine(random: RandomNumberGenerator) -> Array[Dictionary]:
	var altar: Dictionary = UNDERWORLD_ALTARS[random.randi() % UNDERWORLD_ALTARS.size()]
	var pieces: Array[Dictionary] = [_piece(random, altar, Vector2.ZERO)]
	for side in [-1.0, 1.0]:
		var gargoyle: Dictionary = UNDERWORLD_GARGOYLES[random.randi() % UNDERWORLD_GARGOYLES.size()]
		pieces.append(_piece(random, gargoyle, Vector2(side * random.randf_range(85.0, 105.0), random.randf_range(-14.0, -4.0))))
	for side in [-1.0, 1.0]:
		if random.randf() < 0.7:
			var fire: Dictionary = UNDERWORLD_FIRES[1 if random.randf() < 0.6 else 0]
			pieces.append(_piece(random, fire, Vector2(side * random.randf_range(52.0, 66.0), random.randf_range(20.0, 34.0))))
	return pieces


## An obsidian outcrop: one big crag with spires and shards gathered around its base.
func _make_obsidian_outcrop(random: RandomNumberGenerator) -> Array[Dictionary]:
	var crag: Dictionary = OBSIDIAN_CRAGS[random.randi() % OBSIDIAN_CRAGS.size()]
	var pieces: Array[Dictionary] = [_piece(random, crag, Vector2.ZERO)]
	for _spire in random.randi_range(1, 2):
		var spire: Dictionary = OBSIDIAN_SPIRES[random.randi() % OBSIDIAN_SPIRES.size()]
		pieces.append(_piece(random, spire, _cluster_offset(random, 40.0, 66.0), 0.85))
	for _rock in random.randi_range(1, 2):
		var rock: Dictionary = OBSIDIAN_ROCKS[random.randi() % OBSIDIAN_ROCKS.size()]
		pieces.append(_piece(random, rock, _cluster_offset(random, 46.0, 76.0)))
	return pieces


## Where something died badly: bone heaps, a skeleton and a skull-capped column or two.
func _make_bone_field(random: RandomNumberGenerator) -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	var pillar: Dictionary = UNDERWORLD_PILLARS[2 + random.randi() % 5]
	pieces.append(_piece(random, pillar, Vector2.ZERO))
	for _bones in random.randi_range(2, 3):
		var bones: Dictionary = UNDERWORLD_BONES[random.randi() % UNDERWORLD_BONES.size()]
		pieces.append(_piece(random, bones, _cluster_offset(random, 30.0, 64.0)))
	if random.randf() < 0.4:
		pieces.append({
			"texture": UNDERWORLD_SKELETON, "scale": random.randf_range(0.75, 0.85),
			"offset": _cluster_offset(random, 36.0, 60.0), "collision": 0.0,
		})
	return pieces


## Torture yard: a few instruments of torment around a burning brazier.
func _make_torture_yard(random: RandomNumberGenerator) -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	var choices := range(UNDERWORLD_TORMENTS.size())
	choices.shuffle()
	for index in random.randi_range(2, 3):
		var torment: Dictionary = UNDERWORLD_TORMENTS[choices[index]]
		var x := (index - 1) * random.randf_range(62.0, 78.0)
		pieces.append(_piece(random, torment, Vector2(x, random.randf_range(-12.0, 12.0))))
	pieces.append(_piece(random, UNDERWORLD_FIRES[0], _cluster_offset(random, 60.0, 90.0) + Vector2(0.0, 26.0)))
	return pieces


## A cache of crates and barrels, some packed with skulls.
func _make_supply_cache(random: RandomNumberGenerator) -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	for index in random.randi_range(2, 4):
		var supply: Dictionary = UNDERWORLD_SUPPLIES[random.randi() % UNDERWORLD_SUPPLIES.size()]
		pieces.append(_piece(random, supply, Vector2.ZERO if index == 0 else _cluster_offset(random, 26.0, 50.0)))
	return pieces


## A cluster piece from a prop table entry, carrying its collision and any flames.
func _piece(random: RandomNumberGenerator, prop: Dictionary, offset: Vector2, scale_factor := 1.0) -> Dictionary:
	var piece := {
		"texture": prop["texture"], "scale": _random_scale(random, prop) * scale_factor,
		"offset": offset, "collision": prop.get("collision", 0.0),
	}
	if prop.has("flame"):
		piece["flame"] = prop["flame"]
	return piece


## Firelight and rising embers for a burning prop; `flame` is how high up the art the fire sits.
func _ignite(sprite: Sprite2D, flame: float) -> void:
	var height := sprite.texture.get_height()
	var flame_position := Vector2(0.0, -height * flame)
	FireGlow.attach(sprite, flame_position, height * 1.7, Color("#ff6a1f"), 0.6)
	var embers := CPUParticles2D.new()
	embers.position = flame_position
	embers.amount = 6
	embers.lifetime = 1.4
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(sprite.texture.get_width() * 0.2, 3.0)
	embers.direction = Vector2.UP
	embers.spread = 20.0
	embers.gravity = Vector2.ZERO
	embers.initial_velocity_min = 18.0
	embers.initial_velocity_max = 36.0
	embers.scale_amount_min = 1.5
	embers.scale_amount_max = 2.5
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	fade.colors = PackedColorArray([Color("#fff1a8"), Color("#ff8a2a"), Color(0.85, 0.2, 0.05, 0.0)])
	embers.color_ramp = fade
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	embers.material = additive
	sprite.add_child(embers)


func _random_region_offset(random: RandomNumberGenerator, safe_area: Vector2) -> Vector2:
	return Vector2(
		random.randf_range(-safe_area.x, safe_area.x),
		random.randf_range(-safe_area.y, safe_area.y)
	)


func _has_scenery_clearance(world_position: Vector2, half_size: Vector2) -> bool:
	for x_offset in range(-1, 2):
		for y_offset in range(-1, 2):
			var nearby_region := active_scenery_region + Vector2i(x_offset, y_offset)
			var placements: Array = scenery_placements_by_region.get(nearby_region, [])
			for placement in placements:
				var other_position: Vector2 = placement["position"]
				var other_half_size: Vector2 = placement["half_size"]
				var separation := world_position - other_position
				if absf(separation.x) < half_size.x + other_half_size.x + SCENERY_CLEARANCE \
						and absf(separation.y) < half_size.y + other_half_size.y + SCENERY_CLEARANCE:
					return false
	return true


func _get_camera_center() -> Vector2:
	return player.global_position + player_camera.offset / player_camera.zoom


func _get_region_for_position(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori((world_position.x - region_origin.x + region_size.x * 0.5) / region_size.x),
		floori((world_position.y - region_origin.y + region_size.y * 0.5) / region_size.y)
	)


func _get_max_enemies() -> int:
	match biome:
		1:
			return MAX_DESERT_ENEMIES
		2:
			return MAX_ICE_ENEMIES
		3:
			return MAX_UNDERWORLD_ENEMIES
	return MAX_FOREST_ENEMIES


func _spawn_enemy(direction: Vector2) -> bool:
	var enemy_scene: PackedScene = WOLF_SCENE
	if biome == 1:
		enemy_scene = SCORPION_SCENE if loot_random.randf() < 0.75 else SNAKE_SCENE
	elif biome == 2:
		enemy_scene = CRYSTALBACK_YETI_SCENE if loot_random.randf() < 0.55 else ICE_GOLEM_SCENE
	elif biome == 3:
		var demon_roll := loot_random.randf()
		if demon_roll < 0.45:
			enemy_scene = IMP_SCENE
		elif demon_roll < 0.75:
			enemy_scene = HELLHOUND_SCENE
		else:
			enemy_scene = FIRE_FIEND_SCENE
	var enemy := enemy_scene.instantiate() as Wolf
	if enemy == null:
		push_error("The enemy scene root must use the Wolf base script.")
		set_physics_process(false)
		return false

	enemy.target_path = NodePath("../Player")
	enemy.modifier_ids = MonsterModifiers.roll(loot_random, area_level)
	enemy.died.connect(_on_enemy_died.bind(enemy))
	get_parent().add_child(enemy)
	enemy.global_position = player.global_position + direction * _get_spawn_distance(direction)
	# Fresh spawns are encounters ahead of the player, so they come straight at them.
	enemy.alert()
	enemies_spawned += 1
	return true


## Levels that end with a single boss monster rather than the forest's wolf pack.
func _has_level_boss() -> bool:
	return biome in [1, 2, 3]


func _spawn_level_boss() -> void:
	var boss_scene: PackedScene = DESERT_BOSS_SCENE
	if biome == 2:
		boss_scene = ICE_BOSS_SCENE
	elif biome == 3:
		boss_scene = ARCHDEMON_SCENE
	var boss := boss_scene.instantiate() as Wolf
	if boss == null:
		push_error("The level boss scene root must use the Wolf base script.")
		set_physics_process(false)
		return

	boss.always_alert = true
	boss.target_path = NodePath("../Player")
	boss.died.connect(_on_level_boss_died.bind(boss))
	get_parent().add_child(boss)
	var spawn_direction := player.facing
	if spawn_direction.is_zero_approx():
		spawn_direction = Vector2.RIGHT
	boss.global_position = player.global_position + spawn_direction * _get_spawn_distance(spawn_direction)
	boss_spawned = true
	boss_incoming.emit()
	boss_progress_changed.emit(0, 1)


func _get_spawn_distance(direction: Vector2) -> float:
	var half_view := region_size * 0.5
	var horizontal_distance := INF
	var vertical_distance := INF
	if not is_zero_approx(direction.x):
		horizontal_distance = half_view.x / absf(direction.x)
	if not is_zero_approx(direction.y):
		vertical_distance = half_view.y / absf(direction.y)
	return minf(horizontal_distance, vertical_distance) + SPAWN_EDGE_MARGIN


func _on_enemy_died(enemy: Wolf) -> void:
	enemies_defeated += 1
	progress_changed.emit(enemies_defeated, _get_max_enemies())
	var experience_reward := _get_scaled_experience_reward(enemy)
	if not player.gain_experience(experience_reward):
		push_error("Could not award %d XP for defeating %s." % [
			experience_reward,
			enemy.name
		])
	_drop_enemy_loot(enemy)

	var max_enemies := _get_max_enemies()
	if biome == 0 and enemies_defeated == max_enemies and not boss_spawned:
		_spawn_wolf_boss_pack()
		_save_level_state()
	elif _has_level_boss() and enemies_defeated == max_enemies and not boss_spawned:
		_spawn_level_boss()
		_save_level_state()
	else:
		_save_level_state()


func _on_level_boss_died(boss: Wolf) -> void:
	var experience_reward := _get_scaled_experience_reward(boss)
	if not player.gain_experience(experience_reward):
		push_error("Could not award %d XP for defeating the level boss." % experience_reward)
	_drop_enemy_loot(boss, true)
	if biome in [2, 3]:
		# The Cryohydra and the Archdemon guard a hoard as well.
		_spawn_treasure_chest(boss.global_position + Vector2(0.0, 40.0))
	_complete_current_level()


func _spawn_wolf_boss_pack() -> void:
	boss_spawned = true
	boss_wolves_defeated = 0
	boss_incoming.emit()
	var spawn_direction := player.facing
	if spawn_direction.is_zero_approx():
		spawn_direction = Vector2.RIGHT
	var pack_center := player.global_position \
			+ spawn_direction * _get_spawn_distance(spawn_direction)
	var flank := Vector2(-spawn_direction.y, spawn_direction.x) * BOSS_PACK_SPREAD
	_spawn_boss_wolf(pack_center, true)
	_spawn_boss_wolf(pack_center + flank, false)
	_spawn_boss_wolf(pack_center - flank, false)
	boss_progress_changed.emit(boss_wolves_defeated, FOREST_BOSS_PACK_SIZE)


## Spawns one wolf of the forest boss pack. Pass saved_health >= 0 when restoring a save.
func _spawn_boss_wolf(world_position: Vector2, is_alpha: bool, saved_health := -1.0) -> void:
	var wolf := WOLF_SCENE.instantiate() as Wolf
	if wolf == null:
		push_error("The wolf scene root must use the Wolf script.")
		return

	wolf.target_path = NodePath("../Player")
	wolf.set_meta(BOSS_ROLE_META, "alpha" if is_alpha else "pack")
	wolf.always_alert = true
	if is_alpha:
		wolf.name = "AlphaWolf"
		wolf.monster_name = "Alpha Wolf"
		wolf.scale = Vector2.ONE * ALPHA_WOLF_SCALE
		wolf.max_health = Wolf.MAX_HEALTH * ALPHA_WOLF_HEALTH_MULTIPLIER
		wolf.attack_damage = roundi(Wolf.ATTACK_DAMAGE * ALPHA_WOLF_DAMAGE_MULTIPLIER)
		wolf.experience_reward = ALPHA_WOLF_EXPERIENCE
	wolf.died.connect(_on_boss_wolf_died.bind(wolf))
	get_parent().add_child(wolf)
	wolf.global_position = world_position
	if saved_health >= 0.0:
		wolf.health = clampf(saved_health, 0.0, wolf.max_health)
		wolf.health_bar.value = wolf.health


func _on_boss_wolf_died(wolf: Wolf) -> void:
	var experience_reward := _get_scaled_experience_reward(wolf)
	if not player.gain_experience(experience_reward):
		push_error("Could not award %d XP for defeating %s." % [experience_reward, wolf.name])
	_drop_enemy_loot(wolf)
	boss_wolves_defeated = mini(boss_wolves_defeated + 1, FOREST_BOSS_PACK_SIZE)
	boss_progress_changed.emit(boss_wolves_defeated, FOREST_BOSS_PACK_SIZE)
	if boss_wolves_defeated < FOREST_BOSS_PACK_SIZE:
		_save_level_state()
		return

	_spawn_treasure_chest(wolf.global_position)
	_complete_current_level()


func _spawn_treasure_chest(world_position: Vector2) -> void:
	var chest := TREASURE_CHEST_SCENE.instantiate() as TreasureChest
	if chest == null:
		push_error("The treasure chest scene root must use the TreasureChest script.")
		return

	chest.opened.connect(_on_treasure_chest_opened.bind(chest))
	get_parent().call_deferred("add_child", chest)
	chest.position = world_position


func _on_treasure_chest_opened(chest: TreasureChest) -> void:
	if not chest.loot_rolled:
		chest.loot_rolled = true
		# Quest items (like Rendel's coat) come first, and only while their quest is at the right stage.
		chest.loot.append_array(Quests.create_chest_quest_items())
		if item_pool.is_empty():
			push_error("The treasure chest has no loot table to draw from.")
		else:
			var item_count := mini(
				loot_random.randi_range(CHEST_MIN_ITEMS, CHEST_MAX_ITEMS),
				item_pool.size()
			)
			var candidates := item_pool.duplicate()
			for _index in item_count:
				chest.loot.append(candidates.pop_at(loot_random.randi_range(0, candidates.size() - 1)))
	chest_loot_opened.emit(chest)


func _complete_current_level() -> void:
	level_is_complete = true
	level_completed.emit()


func _get_scaled_experience_reward(enemy: Wolf) -> int:
	var area_multiplier := 1.0 + float(area_level - 1) * 0.5
	return maxi(roundi(enemy.experience_reward * area_multiplier), 1)


func _drop_enemy_loot(enemy: Wolf, is_level_boss := false) -> void:
	var origin := enemy.global_position
	var gold_amount := mini(
		roundi(loot_random.randi_range(1, 3) * enemy.get_gold_multiplier()),
		GoldPickup.MAX_AMOUNT
	)
	var gold_hop := _drop_hop()
	_spawn_gold_pickup(origin + gold_hop, gold_amount, -gold_hop)
	if is_level_boss:
		var boss_gear := _create_desert_gear(true)
		if biome == 2:
			boss_gear = _create_ice_gear(true)
		elif biome == 3:
			boss_gear = _create_underworld_gear(true)
		var boss_hop := _drop_hop()
		_spawn_item_pickup(boss_gear, origin + boss_hop, -boss_hop)
	elif loot_random.randf() < ITEM_DROP_CHANCE:
		_drop_random_enemy_item(origin, _drop_hop())
	for _extra_drop in enemy.get_extra_item_drops():
		var scatter := Vector2(
			loot_random.randf_range(-EXTRA_DROP_SCATTER, EXTRA_DROP_SCATTER),
			loot_random.randf_range(-EXTRA_DROP_SCATTER, EXTRA_DROP_SCATTER)
		)
		_drop_random_enemy_item(origin, _drop_hop() + scatter)


## A random hop for a fresh drop: where it lands relative to the monster.
func _drop_hop() -> Vector2:
	var distance := loot_random.randf_range(DROP_HOP_DISTANCE.x, DROP_HOP_DISTANCE.y)
	return Vector2.RIGHT.rotated(loot_random.randf() * TAU) * distance


## Drops a random piece of the area's gear, hopping from origin out to origin + hop.
func _drop_random_enemy_item(origin: Vector2, hop: Vector2) -> void:
	var item: ItemData = null
	if biome == 1:
		item = _create_desert_gear(false)
	elif biome == 2:
		item = _create_ice_gear(false)
	elif biome == 3:
		item = _create_underworld_gear(false)
	elif not item_pool.is_empty():
		item = item_pool[loot_random.randi_range(0, item_pool.size() - 1)]
	if item != null:
		_spawn_item_pickup(item, origin + hop, -hop)


func _create_desert_gear(is_boss_drop: bool) -> ItemData:
	var gear_choice := loot_random.randi_range(0, 2)
	var bonus := 3 if is_boss_drop else 2
	var prefix := "Scorched" if is_boss_drop else "Dune"
	var item := ItemData.new()
	item.price = 25

	match gear_choice:
		0:
			item.display_name = "%s Scimitar" % prefix
			item.equipment_slot = "Weapon"
			item.icon_color = Color("#e7a74b")
			item.damage_bonus = bonus
		1:
			item.display_name = "%s Helm" % prefix
			item.equipment_slot = "Helm"
			item.icon_color = Color("#d4a76a")
			item.damage_reduction = bonus
		2:
			item.display_name = "%s Signet Ring" % prefix
			item.equipment_slot = "Ring"
			item.icon_color = Color("#d8bc59")
			item.damage_bonus = bonus

	return item


## Ice Caves gear, a step up from the desert's; the Cryohydra drops the best of it.
func _create_ice_gear(is_boss_drop: bool) -> ItemData:
	var gear_choice := loot_random.randi_range(0, 2)
	var bonus := 4 if is_boss_drop else 3
	var prefix := "Glacial" if is_boss_drop else "Rimefrost"
	var item := ItemData.new()
	item.price = 35

	match gear_choice:
		0:
			item.display_name = "%s Axe" % prefix
			item.equipment_slot = "Weapon"
			item.icon_color = Color("#7fd0f5")
			item.damage_bonus = bonus
		1:
			item.display_name = "%s Helm" % prefix
			item.equipment_slot = "Helm"
			item.icon_color = Color("#a9c8e6")
			item.damage_reduction = bonus
		2:
			item.display_name = "%s Band" % prefix
			item.equipment_slot = "Ring"
			item.icon_color = Color("#c6ecff")
			item.damage_bonus = bonus

	return item


func _on_player_died() -> void:
	set_physics_process(false)
	_save_level_state()


## Underworld gear, a step up from the Ice Caves'; the Archdemon drops the best of it.
func _create_underworld_gear(is_boss_drop: bool) -> ItemData:
	var gear_choice := loot_random.randi_range(0, 2)
	var bonus := 5 if is_boss_drop else 4
	var prefix := "Hellforged" if is_boss_drop else "Brimstone"
	var item := ItemData.new()
	item.price = 45

	match gear_choice:
		0:
			item.display_name = "%s Trident" % prefix
			item.equipment_slot = "Weapon"
			item.icon_color = Color("#ff7a3d")
			item.damage_bonus = bonus
		1:
			item.display_name = "%s Horned Helm" % prefix
			item.equipment_slot = "Helm"
			item.icon_color = Color("#d9573a")
			item.damage_reduction = bonus
		2:
			item.display_name = "%s Ember Ring" % prefix
			item.equipment_slot = "Ring"
			item.icon_color = Color("#ffb347")
			item.damage_bonus = bonus

	return item
