extends Node

var music = 100
var sfx = 100
var player : Object = null
var world : Object = null
var server_world : Object = null

func get_music_volume():
	return Settings._settings["audio"]["music"]

func get_sfx_volume():
	return Settings._settings["audio"]["sfx"]

func instance_scene_on_node(scene, node, position):
	var instance = scene.instance()
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

func add_enemy_spawn(g_position):
	if server_world == null:
		server_world = get_node("/root/Network/ServerWorld")
	server_world.add_spawn_point(g_position)

func add_all_spawns():
	var world_generator = get_node("/root/World/Background")
	for pos in world_generator.enemy_positions:
		add_enemy_spawn(pos)

func quit_game():
	server_world = null
	world = null
	player = null
