extends Node

const DEFAULT_PORT = 28960
const MAX_CLIENTS = 20

var server = null
var client = null
var world_seed = 42069

var ip_address = ""
var current_player_username = ""
var players = {}
var fires = []

# Client
var decimal_collector : float = 0
var latency = 0
var client_clock = OS.get_system_time_msecs()
var latency_array = []
var delta_latency = 0

# Server
var world
var player_state_collection = {}

signal connection_error

func _ready() -> void:
	if OS.get_name() == "Windows":
		ip_address = IP.get_local_addresses()[1]
	elif OS.get_name() == "Android":
		ip_address = IP.get_local_addresses()[0]
	else:
		ip_address = IP.get_local_addresses()[3]
	
#	for ip in IP.get_local_addresses():
#		if ip.begins_with("71.227.") and not ip.ends_with(".1"):
	
	# warning-ignore:return_value_discarded
	get_tree().connect("connected_to_server", self, "_connected_ok")
	# warning-ignore:return_value_discarded
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	# warning-ignore:return_value_discarded
	get_tree().connect("connection_failed", self, "_connection_failed")
	# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_connected", self, "_player_connected")
	# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

func _physics_process(delta): #0.01667  60fps
	client_clock += int(delta * 1000) + delta_latency
	delta_latency = 0
	decimal_collector += (delta * 1000) - int(delta * 1000)
	if decimal_collector >= 1.00:
		client_clock += 1
		decimal_collector -= 1.00

func _server_disconnected():
	get_node("LatencyTimer").queue_free()
	if get_tree().get_network_unique_id() > 1:
		quit_game()

func create_server(mp) -> void:
	server = NetworkedMultiplayerENet.new()
	var port = DEFAULT_PORT
	var num_clients = MAX_CLIENTS
	if mp == false: 
		server.set_bind_ip("127.0.0.1")
	var err = server.create_server(port, num_clients)
	
	if (err != OK):
		# warning-ignore:standalone_expression
		ip_address == "127.0.0.1"
		join_server()
		return
	
	get_tree().set_network_peer(server)
	add_child(preload("res://Network/ServerWorld.tscn").instance())
	add_child(preload("res://Network/StateProcessing.tscn").instance())
	
	var player_data = SaverAndLoader.custom_data_player
	players[1] = {"Name" : player_data.player_name, "Position" : player_data.player_position, "Level" : player_data.player_level, "Shader" : player_data.player_shader}
	
	# Fire logic
	fires =  SaverAndLoader.custom_data_world.world_fires
	
	# Set world seed
	world_seed = SaverAndLoader.custom_data_world.world_seed
	print(world_seed)
	seed(world_seed)
	
	# warning-ignore:return_value_discarded
	get_tree().change_scene("res://World/World.tscn")
	call_deferred("spawn_player")
	# Add Enemy spawns created by background - not implemented
	# Globals.add_all_spawns()

func spawn_player():
	get_node("../World").SpawnNewPlayer(get_tree().get_network_unique_id(), players[1]["Position"])

func join_server() -> void:
	print("Trying to join server")
	client = NetworkedMultiplayerENet.new()
	var err = client.create_client(ip_address, DEFAULT_PORT)
	if (err != OK):
		print("error: " + str(err))
		emit_signal("connection_error")
		return
	
	get_tree().set_network_peer(client)
	print(get_tree().network_peer.get_connection_status())

func _player_connected(player_id) -> void:
	print("Player " + str(player_id) + " has connected")

func _player_disconnected(player_id) -> void:
	unregister_player(player_id)
	print("Player " + str(player_id) + " has disconnected")

func _connection_failed():
	emit_signal("connection_error")
	print("Failed to connect")

func _connected_ok():
	print("Successfully connected to the server")
	rpc_id(1, "user_ready", get_tree().get_network_unique_id())
	
	# Sync
	rpc_id(1, "FetchServerTime", OS.get_system_time_msecs())
	# latency adjustment
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.name = "LatencyTimer"
	timer.connect("timeout", self, "DetermineLatency")
	self.add_child(timer)

remote func user_ready(player_id):
	if get_tree().is_network_server():
		rpc_id(player_id, "register_in_game", world_seed, fires)

remote func register_in_game(new_world_seed, new_fires):  # Only the client sends this once.
	fires = new_fires
	world_seed = new_world_seed
	seed(world_seed)
	var player_data = SaverAndLoader.custom_data_player
	var new_player_info = {"Name" : player_data.player_name, "Position" :  player_data.player_position, "Level" : player_data.player_level, "Shader" : player_data.player_shader}
	# warning-ignore:return_value_discarded
	get_tree().change_scene("res://World/World.tscn")
	rpc("register_new_player", get_tree().get_network_unique_id(), new_player_info)
	register_new_player(get_tree().get_network_unique_id(), new_player_info)
#	# fires
#	Globals.add_fires()

remote func register_new_player(player_id, player_info):
	if get_tree().is_network_server(): # Only the server sends this once per client.
		for peer_id in players:
			rpc_id(player_id, "register_new_player", peer_id, players[peer_id])
	
	players[player_id] = player_info
	call_deferred("spawn_new_player", player_id, player_info["Position"])
	print(str(get_tree().get_network_unique_id()) + " registers " + str(player_id))

func spawn_new_player(player_id, position):
	get_node("../World").SpawnNewPlayer(player_id, position)

remote func unregister_player(player_id):
	players.erase(player_id)
	get_node("../World").DespawnPlayer(player_id)

func quit_game():
	var player_info = players[get_tree().get_network_unique_id()]
	var custom_data_player = {
		player_name = player_info["Name"],
		player_position = player_info["Position"],
	}
	Globals.quit_game()
	for key in custom_data_player.keys():
		SaverAndLoader.custom_data_player[key] = custom_data_player[key]
	SaverAndLoader.save_player()
	if(get_tree().is_network_server()):
		SaverAndLoader.save_world()
		for node in get_children():
			node.queue_free()
	get_tree().set_network_peer(null)
	players.clear()
	server = null
	client = null
	get_node("../World").ServerDied()

remotesync func set_player_position(player_id: int, pos : Vector2):
	players[player_id]["Position"] = pos

# ----------------------------------------------------------------------------
# ---------------------------- CLIENT CODE -----------------------------------
# ----------------------------------------------------------------------------

func NPCKilled(enemy_id):
	if get_tree().is_network_server():
		SendNPCKilled(enemy_id)
		return
	rpc_id(1, "SendNPCKilled", enemy_id)

remote func ReceiveWorldState(world_state):
	get_node("../World").UpdateWorldState(world_state)


# Client Side Latency

func DetermineLatency():
	rpc_id(1, "DetermineLatencyServer", OS.get_system_time_msecs())

remote func ReturnServerTime(server_time, client_time):
	latency = (OS.get_system_time_msecs() - client_time) / 2
	client_clock = server_time + latency

remote func ReturnLatency(client_time):
	latency_array.append((OS.get_system_time_msecs() - client_time) / 2)
	if latency_array.size() == 9:
		var total_latency = 0
		latency_array.sort()
		var mid_point = latency_array[4]
		for i in range(latency_array.size()-1, -1, -1):
			if latency_array[i] > (2 * mid_point) and latency_array[i] > 20:
				latency_array.remove(i)
			else:
				total_latency += latency_array[i]
		delta_latency = (total_latency / latency_array.size()) - latency
		latency = total_latency / latency_array.size()
		latency_array.clear()


# ----------------------------------------------------------------------------
# ------------------------------ SERVER CODE ---------------------------------
# ----------------------------------------------------------------------------

func SendWorldState(world_state):
	if get_tree().is_network_server():
		ReceiveWorldState(world_state)
	rpc_unreliable_id(0, "ReceiveWorldState", world_state)

remote func SendNPCKilled(enemy_id):
	get_node("ServerWorld").NPCKilled(enemy_id)

# Server side Latency

remote func FetchServerTime(client_time):
	var player_id = get_tree().get_rpc_sender_id()
	if player_id == 0:
		player_id = 1
	rpc_id(player_id, "ReturnServerTime", OS.get_system_time_msecs(), client_time)

remote func DetermineLatencyServer(client_time):
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(player_id, "ReturnLatency", client_time)
