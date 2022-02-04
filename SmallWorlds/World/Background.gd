extends Node2D

export var TreeScene: PackedScene
export var BushScene: PackedScene
export var GrassScene: PackedScene
export var TallGrassScene: PackedScene
export var RockScene: PackedScene

# Noise
export(float) var octaves = 1
export(float) var period = 20
export(float) var persistance = 0.7
export(float) var grass_cap = 0.5
export(Vector2) var dirt_caps = Vector2(0.2, 0.1)
export(Vector3) var environment_caps = Vector3(0.4, 0.3, 0.05)

# Tilemap Logic
export(int) var chunk_size = 20
export(int) var tile_size = 16
export(int) var cliff_size = 32
export(Vector2) var map_size = Vector2(10, 10)

var noise : Object = null
var offsets = [[-1, -1], [0, -1], [1, -1], 
			   [-1,  0], [0,  0], [1,  0],
			   [-1,  1], [0,  1], [1,  1]]
var enemy_positions = []
var displayed_chunks = []
var scenes_on_node = {}
var last_player_position = Vector2.ZERO

# Multi threads
var thread

onready var grass_tile = $GrassTileMap
onready var dirt_tile = $DirtTileMap
onready var flower_tile = $FlowerTileMap
onready var water_tile = $WaterTileMap
onready var cliff_tile = $DirtCliffTileMap

# Called when the node enters the scene tree for the first time.
func _ready():
	noise = OpenSimplexNoise.new()
	# noise.seed = randi()
	noise.octaves = octaves
	noise.period = period
	noise.persistence = persistance
#	make_grass_map()
#	make_dirt_map()
#	make_flower_map()
#	clean_map()
	update_tilemaps(true)

#func _process(delta):
#	if Globals.player == null:
#		return
#
#	if Globals.player != null and Globals.dead == false:
#		last_player_position = Globals.player.global_position
#
#	update_tilemaps(false)

func update_tilemaps(all_tiles: bool):
	var new_chunks = []
	if all_tiles:
		for x in map_size.x:
			for y in map_size.y:
				new_chunks.append(Vector2(x, y))
	else:
		new_chunks = get_3x3_chunks_around_current()
	
	var diff = new_chunks.size() != displayed_chunks.size() 
	for new_chunk in new_chunks:
		if !displayed_chunks.has(new_chunk):
			create_chunk(new_chunk)
			diff = true

	if diff:
#		for old_chunk in displayed_chunks:
#			if !new_chunks.has(old_chunk):
#				delete_chunk(old_chunk)
		
		displayed_chunks = new_chunks
		for chunk in displayed_chunks:
			clean_map(chunk)
		
		# Not for chunk logic
		for chunk in displayed_chunks:
			clean_map(chunk)
#		scenes_on_node.clear()

		var render_start = Vector2.ONE * -1000
		
		# separate from chunck logic
		create_cliff()
		cliff_tile.update_bitmask_region(render_start, map_size * chunk_size)
		
		grass_tile.update_bitmask_region(render_start, map_size * chunk_size)
		dirt_tile.update_bitmask_region(render_start, map_size * chunk_size)
		water_tile.update_bitmask_region(render_start, map_size * chunk_size)
		flower_tile.update_bitmask_region(render_start, map_size * chunk_size)

func create_cliff() -> void:
	var last_grass = map_size.y * chunk_size
	var last_pos = (last_grass)/2 + 1
	for i in range(-1, last_pos):
		cliff_tile.set_cell(-1, i, 0)
		cliff_tile.set_cell(i, -1, 0)
		cliff_tile.set_cell(last_pos-1, i, 0)
		cliff_tile.set_cell(i, last_pos-1, 0)
		
		grass_tile.set_cell(-2, i*2, 1)
		grass_tile.set_cell(-2, i*2 + 1, 1)
		grass_tile.set_cell(-1, i*2, 1)
		grass_tile.set_cell(-1, i*2 + 1, 1)
		
		grass_tile.set_cell(i*2, -2, 1)
		grass_tile.set_cell(i*2 + 1, -2, 1)
		grass_tile.set_cell(i*2, -1, 1)
		grass_tile.set_cell(i*2 + 1, -1, 1)
		
		grass_tile.set_cell(last_grass + 1, i*2, 1)
		grass_tile.set_cell(last_grass + 1, i*2 + 1, 1)
		grass_tile.set_cell(last_grass, i*2, 1)
		grass_tile.set_cell(last_grass, i*2 + 1, 1)
		
		grass_tile.set_cell(i*2, last_grass + 1, 1)
		grass_tile.set_cell(i*2 + 1, last_grass + 1, 1)
		grass_tile.set_cell(i*2, last_grass, 1)
		grass_tile.set_cell(i*2 + 1, last_grass, 1)
	
	# Delete entrance
	for i in range(4, 7):
		cliff_tile.set_cell(i, -1, -1)
	for i in range(3, 8):
		grass_tile.set_cell(i*2, 0, 1)
		grass_tile.set_cell(i*2 + 1, 0, 1)

func create_chunk(new_chunk_coords: Vector2) -> void:
	scenes_on_node[new_chunk_coords] = []
	for x in range(new_chunk_coords.x * chunk_size, (new_chunk_coords.x + 1) * chunk_size):
		for y in range(new_chunk_coords.y * chunk_size, (new_chunk_coords.y + 1) * chunk_size):
			make_grass_map(x, y)
			make_dirt_map(x, y)
			make_flower_map(x, y, new_chunk_coords)

func clean_map(new_chunk_coords: Vector2) -> void:
	for x in range(new_chunk_coords.x * chunk_size, (new_chunk_coords.x + 1) * chunk_size):
		for y in range(new_chunk_coords.y * chunk_size, (new_chunk_coords.y + 1) * chunk_size):
			clean_map_1(x, y)
			clean_map_2(x, y)

func make_grass_map(x, y) -> void:
	dirt_tile.set_cell(x, y, 5, false, false, false, Vector2(0,randi() % 3))
	var a = noise.get_noise_2d(x, y)
	if a < grass_cap:
		grass_tile.set_cell(x, y, 1)
	else:
		water_tile.set_cell(x, y, 4)
		dirt_tile.set_cell(x, y, -1)

func make_dirt_map(x, y) -> void:
	var a = noise.get_noise_2d(x, y)
	if a < dirt_caps.x and a > dirt_caps.y:
		grass_tile.set_cell(x, y, -1)

func make_flower_map(x, y, new_chunk_coords) -> void:
	var a = noise.get_noise_2d(x, y)
	if a < environment_caps.x and a > environment_caps.y or a < environment_caps.z:
		var pos_a = abs(a)
		var local_position = flower_tile.map_to_world(Vector2(x, y))
		var g_position = flower_tile.to_global(local_position)
		var chance = ((pos_a * 10000) - int(pos_a * 10000)) * 100
		if chance < 10:
			flower_tile.set_cell(x, y, 2, false, false, false, Vector2(randi() % 4, randi() % 4))
		elif chance < 12:
			flower_tile.set_cell(x, y, 3, false, false, false, Vector2(randi() % 3, 0))
		elif chance < 13:
			scenes_on_node[new_chunk_coords].append(Globals.instance_scene_on_node(TreeScene, get_parent().get_node("YSort/Trees"), g_position))
		elif chance < 14:
			scenes_on_node[new_chunk_coords].append(Globals.instance_scene_on_node(BushScene, get_parent().get_node("YSort/Bushes"), g_position))
		elif chance < 16:
			scenes_on_node[new_chunk_coords].append(Globals.instance_scene_on_node(GrassScene, get_parent().get_node("YSort/Grass"), g_position))
		elif chance < 20:
			scenes_on_node[new_chunk_coords].append(Globals.instance_scene_on_node(TallGrassScene, get_parent().get_node("YSort/TallGrass"), g_position))
#			scenes_on_node[new_chunk_coords].append(Globals.instance_scene_on_node(TallGrassScene, get_parent().get_node("YSort/TallGrass"), g_position + Vector2(10, 10)))
#			scenes_on_node[new_chunk_coords].append(Globals.instance_scene_on_node(TallGrassScene, get_parent().get_node("YSort/TallGrass"), g_position + Vector2(0, 15)))
#			scenes_on_node[new_chunk_coords].append(Globals.instance_scene_on_node(TallGrassScene, get_parent().get_node("YSort/TallGrass"), g_position + Vector2(10, 0)))
#					Globals.instance_scene_on_node(TallGrassScene, get_parent().get_node("YSort/TallGrass"), g_position + Vector2(10, 10))
#					Globals.instance_scene_on_node(TallGrassScene, get_parent().get_node("YSort/TallGrass"), g_position + Vector2(0, 15))
#					Globals.instance_scene_on_node(TallGrassScene, get_parent().get_node("YSort/TallGrass"), g_position + Vector2(10, 0))
#				elif chance < 26:
#					enemy_positions.append(g_position)
		elif chance < 20.5:
			scenes_on_node[new_chunk_coords].append(Globals.instance_scene_on_node(RockScene, get_parent().get_node("YSort/Rocks"), g_position))

func clean_map_1(x, y) -> void:
	if grass_tile.get_cell(x, y) == -1 and dirt_tile.get_cell(x, y) == -1:
		for offset in offsets:
			water_tile.set_cell(x + offset[0], y + offset[1], 4)

func clean_map_2(x, y) -> void:
	if grass_tile.get_cell(x, y) != -1 and dirt_tile.get_cell(x, y) != -1 and water_tile.get_cell(x, y) != -1:
		dirt_tile.set_cell(x, y, -1)

func delete_chunk(old_chunk_coords: Vector2) -> void:
#	for x in range(old_chunk_coords.x * chunk_size, (old_chunk_coords.x + 1) * chunk_size):
#		for y in range(old_chunk_coords.y * chunk_size, (old_chunk_coords.y + 1) * chunk_size):
#			grass_tile.set_cell(x, y, -1)
#			dirt_tile.set_cell(x, y, -1)
#			water_tile.set_cell(x, y, -1)
#			flower_tile.set_cell(x, y, -1)
	for old_scene in scenes_on_node[old_chunk_coords]:
		old_scene.queue_free()
	scenes_on_node.erase(old_chunk_coords)

func get_current_chunk_coords() -> Vector2:
	return Vector2(int(last_player_position.x / (tile_size * chunk_size)), int(last_player_position.y / (tile_size * chunk_size)))

func get_3x3_chunks_around_current():
	var current_chunk = get_current_chunk_coords()
	
	var chunk_coords = []
	for offset in offsets:
		if (current_chunk.x + offset[0] >= 0 and current_chunk.y + offset[1] >= 0):
			chunk_coords.append(Vector2(current_chunk.x + offset[0], current_chunk.y + offset[1]))

	return chunk_coords

#func get_subtile_coord(tilemap: TileMap, id: int) -> Vector2:
#	var tiles = tilemap
#	var rect = tilemap.tile_set.tile_get_region(id)
#	var x = randi() % int(rect.size.x / something)
#	var y = randi() % int(rect.size.y / something)
#	return Vector2(x, y)
