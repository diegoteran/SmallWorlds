extends Node2D

export var playerTemplate: PackedScene # = preload("res://Player/Player.tscn")
var enemy_spawn: Dictionary = {"Bat": preload("res://Enemies/Bat.tscn"), "StingFly": preload("res://Enemies/StingFly.tscn")}
var last_world_state_time = 0

var world_state_buffer = []
var interpolation_offset = 100

var server = Network
var max_enemy_spawned = -1

onready var players = $YSort/Players
onready var enemies = $YSort/Enemies
onready var dirt = $Background/DirtTileMap
onready var world = $YSort

func _ready():
#	Music.list_play()
	Globals.world = world
	pass

func ServerDied():
	# warning-ignore:return_value_discarded
#	Music.list_stop()
	get_tree().call_deferred("change_scene", "res://Menus/TitleScreen.tscn")
	queue_free()

func SpawnNewPlayer(player_id: int, spawn_position: Vector2):
	var new_player = playerTemplate.instance()
	new_player.global_position = spawn_position
	new_player.name = str(player_id)
	new_player.set_network_master(player_id)
	players.call_deferred("add_child", new_player)

func DespawnPlayer(player_id: int):
	var player = players.get_node(str(player_id))
	yield(get_tree().create_timer(0.2), "timeout")  # 13 episode, better way to do it
	if player != null:
		player.queue_free()

func KillPlayer(player_id: int):
	DespawnPlayer(player_id)
	yield(get_tree().create_timer(1.0), "timeout")
	SpawnNewPlayer(player_id, server.players[player_id]["Position"])


func SpawnNewEnemy(enemy_id, enemy_dict):
	var new_enemy = enemy_spawn[enemy_dict["EnemyType"]].instance()
	new_enemy.position = enemy_dict["EnemyLocation"]
#	new_enemy.hp = enemy_dict["EnemyHealth"]
#	new_enemy.type = enemy_dict["EnemyType"]
	new_enemy.stateServer = enemy_dict["EnemyState"]
	new_enemy.name = str(enemy_id)
	enemies.add_child(new_enemy, true)


func UpdateWorldState(world_state):
	if world_state["T"] > last_world_state_time:
		last_world_state_time = world_state["T"]
		world_state_buffer.append(world_state.duplicate(true))


func _physics_process(_delta):
	var render_time = server.client_clock - interpolation_offset
	if world_state_buffer.size() > 1:
		while (world_state_buffer.size() > 2 and render_time > world_state_buffer[2]["T"]):
			world_state_buffer.remove(0)
		# Interpolate
		if world_state_buffer.size() > 2 and world_state_buffer[2]["T"] != world_state_buffer[1]["T"]:
			SpawnEnemies()

func SpawnEnemies():
	for enemy in world_state_buffer[2]["Enemies"].keys():
		if not world_state_buffer[1]["Enemies"].has(enemy):
			continue
		if world_state_buffer[2]["Enemies"][enemy]["EnemyState"] != "Dead" and enemy > max_enemy_spawned:  # Only respawn them if they are not dead
			print("spawning enemy")
			max_enemy_spawned = enemy
			SpawnNewEnemy(enemy, world_state_buffer[2]["Enemies"][enemy])
