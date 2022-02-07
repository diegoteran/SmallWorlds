extends Node

const SAVE_PATH = "res://savegame.save"

var is_loading = false
var custom_data = {
	player_name = "",
	position_x = 80,
	position_y = 80,
	player_level = 0,
	soul = 0,
	rocks = [0, 0],
	fires_x = [80],
	fires_y = [80]
#	missiles_unlocked = false,
#	boss_defeated = false
}

func save_game():
	var save_game = File.new()
	save_game.open(SAVE_PATH, File.WRITE)
	
	save_game.store_line(to_json(custom_data))
	
#	var persistingNodes = get_tree().get_nodes_in_group("Persists")
#	for node in persistingNodes:
#		var node_data = node.save()
#		save_game.store_line(to_json(node_data))
	save_game.close()
	print("Saved: ", custom_data)
	
func load_game():
	var save_game = File.new()
	if not save_game.file_exists(SAVE_PATH):
		return
	
#	var persistingNodes = get_tree().get_nodes_in_group("Persists")
#	for node in persistingNodes:
#		node.queue_free()
	
	save_game.open(SAVE_PATH, File.READ)
	
	if not save_game.eof_reached():
		var new_custom_data = parse_json(save_game.get_line())
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
	save_game()
