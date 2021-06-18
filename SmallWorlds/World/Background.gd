extends Node2D

export var TreeScene: PackedScene
export var BushScene: PackedScene
export var GrassScene: PackedScene
export var TallGrassScene: PackedScene

export(float) var octaves = 1
export(float) var period = 20
export(float) var persistance = 0.7
export(float) var grass_cap = 0.5
export(Vector2) var dirt_caps = Vector2(0.2, 0.1)
export(Vector3) var environment_caps = Vector3(0.4, 0.3, 0.05)

var noise : Object = null
var map_size : Vector2 = Vector2(200, 200)
var directions = [Vector2.UP, Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
var enemy_positions = []

onready var grass_tile = $GrassTileMap
onready var dirt_tile = $DirtTileMap
onready var flower_tile = $FlowerTileMap
onready var water_tile = $WaterTileMap

# Called when the node enters the scene tree for the first time.
func _ready():
	noise = OpenSimplexNoise.new()
	# noise.seed = randi()
	noise.octaves = octaves
	noise.period = period
	noise.persistence = persistance
	make_grass_map()
	make_dirt_map()
	make_flower_map()
	clean_map()
	
	grass_tile.update_bitmask_region(Vector2.ZERO, map_size)
	dirt_tile.update_bitmask_region(Vector2.ZERO, map_size)
	water_tile.update_bitmask_region(Vector2.ZERO, map_size)
	flower_tile.update_bitmask_region(Vector2.ZERO, map_size)

func make_grass_map() -> void:
	for x in map_size.x:
		for y in map_size.y:
			dirt_tile.set_cell(x, y, 5, false, false, false, Vector2(0,randi() % 3))
			var a = noise.get_noise_2d(x, y)
			if a < grass_cap:
				grass_tile.set_cell(x, y, 1)
			else:
				water_tile.set_cell(x, y, 4)
				dirt_tile.set_cell(x, y, -1)

func make_dirt_map() -> void:
	for x in map_size.x:
		for y in map_size.y:
			var a = noise.get_noise_2d(x, y)
			if a < dirt_caps.x and a > dirt_caps.y:
				grass_tile.set_cell(x, y, -1)

func make_flower_map() -> void:
	for x in map_size.x:
		for y in map_size.y:
			var a = noise.get_noise_2d(x, y)
			if a < environment_caps.x and a > environment_caps.y or a < environment_caps.z:
				var pos_a = abs(a)
				var local_position = flower_tile.map_to_world(Vector2(x, y))
				var g_position = flower_tile.to_global(local_position)
				var chance = int(((pos_a * 10000) - int(pos_a * 10000)) * 100)
				if chance < 10:
					flower_tile.set_cell(x, y, 2, false, false, false, Vector2(randi() % 4, randi() % 4))
				elif chance < 12:
					flower_tile.set_cell(x, y, 3, false, false, false, Vector2(randi() % 3, 0))
				elif chance < 13:
					Globals.instance_scene_on_node(TreeScene, get_parent().get_node("YSort/Trees"), g_position)
				elif chance < 14:
					Globals.instance_scene_on_node(BushScene, get_parent().get_node("YSort/Bushes"), g_position)
				elif chance < 15:
					Globals.instance_scene_on_node(GrassScene, get_parent().get_node("YSort/Grass"), g_position)
				elif chance < 20:
					Globals.instance_scene_on_node(TallGrassScene, get_parent().get_node("YSort/TallGrass"), g_position)
				elif chance < 21:
					enemy_positions.append(g_position)

func clean_map() -> void:
	for x in map_size.x:
		for y in map_size.y:
			if grass_tile.get_cell(x, y) == -1 and dirt_tile.get_cell(x, y) == -1:
				for dir in directions:
					water_tile.set_cell(x + dir.x, y + dir.y, 4)
	
	for x in map_size.x:
		for y in map_size.y:
			if grass_tile.get_cell(x, y) != -1 and dirt_tile.get_cell(x, y) != -1 and water_tile.get_cell(x, y) != -1:
				dirt_tile.set_cell(x, y, -1)

#func get_subtile_coord(tilemap: TileMap, id: int) -> Vector2:
#	var tiles = tilemap
#	var rect = tilemap.tile_set.tile_get_region(id)
#	var x = randi() % int(rect.size.x / something)
#	var y = randi() % int(rect.size.y / something)
#	return Vector2(x, y)
