extends Node

var enemy_id_counter = 1
var enemy_maximum = 20
var enemy_types = ["Bat", "Bat", "Bat", "StingFly"]
var enemy_spawn_points = []
var open_locations = []
var occupied_locations = {}
var enemy_list = {}

func _ready():
	var timer = Timer.new()
	timer.wait_time = 0.01
	timer.autostart = true
	timer.connect("timeout", self, "SpawnEnemy")
	self.add_child(timer)


func SpawnEnemy():
#	enemy_spawn_points = []
#	open_locations = []
#	for i in range(enemy_maximum):
#		enemy_spawn_points.append(Vector2(2*i, 2*i))
#		open_locations.append(i)
	if enemy_list.size() >= enemy_maximum or !Network.players.has(1):# or enemy_spawn_points.size() == 0:
		pass
	else:
		# Generate random
		enemy_spawn_points = []
		open_locations = []
		
		var time_out = 3
		while enemy_spawn_points.size() < enemy_maximum:
			enemy_spawn_points.append_array(generate_possible_spawn_points())
			time_out -= 1
			if time_out <= 0:
				break
		
		if enemy_spawn_points.size() <= 0:
				return

		for i in range(enemy_spawn_points.size()):
			open_locations.append(i)
		
		# previous code
		var type = enemy_types[randi() % enemy_types.size()]
		var rng_location_index = randi() % open_locations.size()
		var location = enemy_spawn_points[open_locations[rng_location_index]]
		
		# Adjust Fly spawn
		if (location.x / Globals.world_size) * (location.y / Globals.world_size) < randf() - 0.3:
			type = "Bat"
		
		occupied_locations[enemy_id_counter] = open_locations[rng_location_index]
		open_locations.remove(rng_location_index)
		enemy_list[enemy_id_counter] = {"EnemyType": type, "EnemyLocation": location, "EnemyHealth": 5, "EnemyState": "Idle", "time_out": 1}
		enemy_id_counter += 1



	for enemy in enemy_list.keys():
		if enemy_list[enemy]["EnemyState"] == "Dead":
			if enemy_list[enemy]["time_out"] == 0:
				enemy_list.erase(enemy)
			else:
				enemy_list[enemy]["time_out"] = enemy_list[enemy]["time_out"] - 1


func NPCKilled(enemy_id):
	if enemy_list.has(enemy_id) and enemy_list[enemy_id]["EnemyState"] != "Dead":
		enemy_list[enemy_id]["EnemyState"] = "Dead"
		open_locations.append(occupied_locations[enemy_id])
		occupied_locations.erase(enemy_id)

func add_spawn_point(g_position):
	enemy_spawn_points.append(g_position)
	open_locations.append(open_locations.size())

func generate_possible_spawn_points() -> Vector2:
	var possible_spawn_points = []
	var player_positions = Globals.get_player_positions()
	
	for pos in player_positions:
		var new_spawn = pos + Vector2(randf() - randf() , randf() - randf()).normalized() * rand_range(Globals.ENEMY_DISTANCE_TO_PLAYERS[0], Globals.ENEMY_DISTANCE_TO_PLAYERS[1])
		var possible = true
		for pos2 in player_positions:
			if new_spawn.distance_to(pos2) < Globals.ENEMY_DISTANCE_TO_PLAYERS[0] - 0.1 or new_spawn.x < 10 or new_spawn.y < 10 or new_spawn.x > Globals.world_size - 10 or new_spawn.y > Globals.world_size - 10:
				possible = false
				break
		if possible:
			possible_spawn_points.append(new_spawn)
	
	return possible_spawn_points
