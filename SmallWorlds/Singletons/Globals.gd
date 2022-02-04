extends Node

var music = 100
var sfx = 100
var player : Object = null
var dead = true
var world : Object = null
var server_world : Object = null
var ENEMY_DISTANCE_TO_PLAYERS = 400
var icon_dict = {0:0, 1:3, 2:4}

var Reflection = preload("res://Effects/Reflection.tscn")

func get_music_volume():
	return Settings._settings["audio"]["music"]

func get_sfx_volume():
	return Settings._settings["audio"]["sfx"]

func instance_scene_on_node(scene, node, position):
	var instance = scene.instance()
	node.call_deferred("add_child", instance)
	instance.global_position = position
	return instance

func instance_scene_on_node_with_name(scene, node, position, new_name):
	var instance = scene.instance()
	instance.name = new_name
	node.call_deferred("add_child", instance)
	instance.global_position = position
	return instance

func instance_scene_on_world(scene, position):
	var instance = scene.instance()
	world.call_deferred("add_child", instance)
	instance.global_position = position
	return instance

func instance_scene_on_world_with_name(scene, position, new_name):
	var instance = scene.instance()
	instance.name = new_name
	world.call_deferred("add_child", instance)
	instance.global_position = position
	return instance

func delete_from_global(node_name):
	world.get_node(node_name).queue_free()

func add_enemy_spawn(g_position) -> void:
	if server_world == null:
		server_world = get_node("/root/Network/ServerWorld")
	server_world.add_spawn_point(g_position)

func add_all_spawns() -> void:
	var world_generator = get_node("/root/World/Background")
	for pos in world_generator.enemy_positions:
		add_enemy_spawn(pos)

func create_reflection_ignore_pos(current_sprite: Sprite, new_name: String) -> RemoteTransform2D:
	var remote_transform = RemoteTransform2D.new()
	var water_tilemap = get_node("/root/World/Background/WaterTileMap")
	var reflection = instance_scene_on_node_with_name(Reflection, water_tilemap, Vector2.ZERO, new_name)
	reflection.copy_sprite = current_sprite
	reflection.ignore_pos = true
	remote_transform.call_deferred("set_remote_node", "/root/World/Background/WaterTileMap/" + new_name)
	return remote_transform

func create_reflection(current_sprite: Sprite, new_name: String) -> RemoteTransform2D:
	var remote_transform = RemoteTransform2D.new()
	var water_tilemap = get_node("/root/World/Background/WaterTileMap")
	var reflection = instance_scene_on_node_with_name(Reflection, water_tilemap, Vector2.ZERO, new_name)
	reflection.copy_sprite = current_sprite
	remote_transform.call_deferred("set_remote_node", "/root/World/Background/WaterTileMap/" + new_name)
	return remote_transform

func delete_reflection(new_name: String) -> void:
	var tilemap = get_node("/root/World/Background/WaterTileMap")
	if tilemap.has_node(new_name):
	 tilemap.get_node(new_name).queue_free()

func get_player_positions() -> Vector2:
	var player_positions = []
	for player_data in Network.players.values():
		player_positions.append(player_data["Position"])
	return player_positions

func quit_game():
	server_world = null
	world = null
	player = null
