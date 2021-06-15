extends Node2D

export(float) var octaves = 1.0
export(float) var period = 12
export(float) var persistance = 0.7
export(float) var grass_cap = 0.5
export(Vector2) var dirt_caps = Vector2(0.3, 0.05)
export(Vector3) var environment_caps = Vector3(0.4, 0.3, 0.04)

var noise : Object = null
var map_size : Vector2 = Vector2(200, 200)
var directions = [Vector2.UP, Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]

onready var grassTile = $GrassTileMap
onready var dirtTile = $DirtTileMap
onready var flowerTile = $FlowerTileMap

# Called when the node enters the scene tree for the first time.
func _ready():
	noise = OpenSimplexNoise.new()
	# noise.seed = randi()
	noise.octaves = octaves
	noise.period = period
	# noise.persistence = persistance
	make_grass_map()
	make_dirt_map()
	make_flower_map()
	clean_map()
	
	grassTile.update_bitmask_region(Vector2.ZERO, map_size)
	dirtTile.update_bitmask_region(Vector2.ZERO, map_size)
	flowerTile.update_bitmask_region(Vector2.ZERO, map_size)

func make_grass_map() -> void:
	for x in map_size.x:
		for y in map_size.y:
			dirtTile.set_cell(x, y, 5, false, false, false, Vector2(0,randi() % 3))
			var a = noise.get_noise_2d(x, y)
			if a < grass_cap:
				grassTile.set_cell(x, y, 1)
			else:
				dirtTile.set_cell(x, y, -1)

func make_dirt_map() -> void:
	for x in map_size.x:
		for y in map_size.y:
			var a = noise.get_noise_2d(x, y)
			if a < dirt_caps.x and a > dirt_caps.y:
				grassTile.set_cell(x, y, -1)

func make_flower_map() -> void:
	for x in map_size.x:
		for y in map_size.y:
			var a = noise.get_noise_2d(x, y)
			if a < environment_caps.x and a > environment_caps.y or a < environment_caps.z:
				var chance = randi() % 100
				if chance < 10:
					flowerTile.set_cell(x, y, 2, false, false, false, Vector2(randi() % 4, randi() % 4))
				elif chance < 12:
					flowerTile.set_cell(x, y, 3, false, false, false, Vector2(randi() % 3, 0))

func clean_map() -> void:
	for x in map_size.x:
		for y in map_size.y:
			if grassTile.get_cell(x, y) == -1 and dirtTile.get_cell(x, y) == -1:
				for dir in directions:
					dirtTile.set_cell(x + dir.x, y + dir.y, -1)

#func get_subtile_coord(tilemap: TileMap, id: int) -> Vector2:
#	var tiles = tilemap
#	var rect = tilemap.tile_set.tile_get_region(id)
#	var x = randi() % int(rect.size.x / something)
#	var y = randi() % int(rect.size.y / something)
#	return Vector2(x, y)
