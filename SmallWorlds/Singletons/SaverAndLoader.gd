extends Node

const SAVE_DIR = "user://saves/"
const SAVE_PATH = SAVE_DIR + "save.dat"
const WORLD_DIR = SAVE_DIR + "worlds/"
const PLAYER_DIR = SAVE_DIR + "players/"
const ENCRYPTION = "ThisIsBecauseOfRaul"

var is_loading = false
var current_world = ""
var current_player = ""
var custom_data = {
}
var custom_data_player = {
	player_name = "",
	player_id = 0,
	player_shader = 0,
	player_position = Vector2(176, -40),
	player_level = 0,
	player_health = 4,
	player_max_health = 4,
	player_soul = 0,
	player_max_soul = 5,
	player_research = [0,0],
	spawn_enabled = false,
	spawn = Vector2.ZERO
}
var custom_data_world = {
	world_seed = 0,
	world_name = "",
	world_fires = []
}
var empty_player

func _ready():
	empty_player = custom_data_player

func save_game():
	# Check for directories
	var dir = Directory.new()
	if !dir.dir_exists(SAVE_DIR):
		dir.make_dir_recursive(SAVE_DIR)
	
	var save_game = File.new()
	var error = save_game.open_encrypted_with_pass(SAVE_PATH, File.WRITE, ENCRYPTION)
	if error != OK:
		print("Error saving")
		return
	
	save_game.store_var(custom_data)
	
#	var persistingNodes = get_tree().get_nodes_in_group("Persists")
#	for node in persistingNodes:
#		var node_data = node.save()
#		save_game.store_line(to_json(node_data))
	save_game.close()
	print("Saved: ", custom_data)

func save_player():
	var dir = Directory.new()
	if !dir.dir_exists(PLAYER_DIR):
		dir.make_dir_recursive(PLAYER_DIR)
	
	var save_player = File.new()
	var error = save_player.open_encrypted_with_pass(PLAYER_DIR + custom_data_player.player_name + "_" + str(custom_data_player.player_id), File.WRITE, ENCRYPTION)
	if error != OK:
		print("Error saving player")
		return
	
	save_player.store_var(custom_data_player)
	save_player.close()
	print("Saved player: ", custom_data_player)

func save_world():
	var dir = Directory.new()
	if !dir.dir_exists(WORLD_DIR):
		dir.make_dir_recursive(WORLD_DIR)
	
	var save_world = File.new()
	var error = save_world.open_encrypted_with_pass(WORLD_DIR + custom_data_world.world_name + "_" + str(custom_data_world.world_seed), File.WRITE, ENCRYPTION)
	if error != OK:
		print("Error saving world")
		return
	
	save_world.store_var(custom_data_world)
	save_world.close()
	print("Saved world: ", custom_data_world)

func load_game():
	var save_game = File.new()
	if not save_game.file_exists(SAVE_PATH):
		return
	
#	var persistingNodes = get_tree().get_nodes_in_group("Persists")
#	for node in persistingNodes:
#		node.queue_free()
	
	var error = save_game.open_encrypted_with_pass(SAVE_PATH, File.READ, ENCRYPTION)
	if error != OK:
		print("Error loading")
		return
	
	var new_custom_data = save_game.get_var()
	for key in new_custom_data.keys():
		custom_data[key] = new_custom_data[key]
	
#	while save_game.get_position() < save_game.get_len():
#		var current_line = parse_json(save_game.get_line())
#		if current_line != null:
#			var newNode = load(current_line["filename"]).instance()
#			get_node(current_line["parent"]).add_child(newNode)
#			newNode.position = Vector2(current_line["position_x"], current_line["position_y"])
#			for property in current_line.keys():
#				if (property == "filename" or property == "parent" or 
#				property == "position_x" or property == "position_y"):
#					continue
#
#				newNode.set(property, current_line[property])
	save_game.close()
	print("Loaded: ", custom_data)

func load_player():
	var save_player = File.new()
	var PLAYER_PATH = PLAYER_DIR + current_player
	if not save_player.file_exists(PLAYER_PATH):
		return
	
	var error = save_player.open_encrypted_with_pass(PLAYER_PATH, File.READ, ENCRYPTION)
	if error != OK:
		print("Error loading player")
		return
	
	var new_custom_data_player = save_player.get_var()
	for key in new_custom_data_player.keys():
		custom_data_player[key] = new_custom_data_player[key]
	
	save_player.close()
	print("Loaded player: ", custom_data_player)

func open_player_file(player_path):
	var save_player = File.new()
	var PLAYER_PATH = PLAYER_DIR + player_path
	
	if not save_player.file_exists(PLAYER_PATH):
		return
	
	var error = save_player.open_encrypted_with_pass(PLAYER_PATH, File.READ, ENCRYPTION)
	if error != OK:
		print("Error loading player")
		return {}
	
	var player_data = save_player.get_var()
	save_player.close()
	
	for key in empty_player.keys():
		if not player_data.has(key):
			player_data[key] = empty_player[key]
	return player_data

func load_world():
	var save_world = File.new()
	var WORLD_PATH = WORLD_DIR + current_world
	if not save_world.file_exists(WORLD_PATH):
		return
	
	var error = save_world.open_encrypted_with_pass(WORLD_PATH, File.READ, ENCRYPTION)
	if error != OK:
		print("Error loading world")
		return
	
	var new_custom_data_world = save_world.get_var()
	for key in new_custom_data_world.keys():
		custom_data_world[key] = new_custom_data_world[key]
	
	save_world.close()
	print("Loaded world: ", custom_data_world)

func delete_player_file(player_path) -> bool:
	var dir = Directory.new()
	var complete_path = PLAYER_DIR + player_path
	if dir.file_exists(complete_path):
		dir.remove(complete_path)
		return true
	return false
