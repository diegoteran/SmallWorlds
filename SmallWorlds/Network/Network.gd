extends Node

const DEFAULT_PORT = 28960
const MAX_CLIENTS = 6

var server = null
var client = null

var ip_address = ""
var current_player_username = ""
var players = {}

# CLient
var decimal_collector : float = 0
var latency = 0
var client_clock = OS.get_system_time_msecs()
var latency_array = []
var delta_latency = 0

#SERVER
var world
var player_state_collection = {}

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
	if mp == false:
		port += 1203
	var err = server.create_server(port, MAX_CLIENTS)
	
	if (err != OK):
		# warning-ignore:standalone_expression
		ip_address == "127.0.0.1"
		join_server()
		return
	
	get_tree().set_network_peer(server)
	add_child(preload("res://Network/ServerWorld.tscn").instance())
	add_child(preload("res://Network/StateProcessing.tscn").instance())
	
	var player_data = SaverAndLoader.custom_data
	players[1] = {"Name" : player_data.player_name, "Position" : Vector2(player_data.position_x, player_data.position_y)}
	get_node("../World").SpawnNewPlayer(get_tree().get_network_unique_id(), players[1]["Position"])
	
	# Add Enemy spawns created by background
	Globals.add_all_spawns()

func join_server() -> void:
	client = NetworkedMultiplayerENet.new()
	var err = client.create_client(ip_address, DEFAULT_PORT)
	if (err != OK):
		return
	
	get_tree().set_network_peer(client)

func _player_connected(player_id) -> void:
	print("Player " + str(player_id) + " has connected")

func _player_disconnected(player_id) -> void:
	unregister_player(player_id)
	print("Player " + str(player_id) + " has disconnected")

func _connection_failed():
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
		rpc_id(player_id, "register_in_game")

remote func register_in_game():  # Only the client sends this once.
	var player_data = SaverAndLoader.custom_data
	var new_player_info = {"Name" : player_data.player_name, "Position" :  Vector2(player_data.position_x, player_data.position_y)}
	print("what")
	rpc("register_new_player", get_tree().get_network_unique_id(), new_player_info)
	register_new_player(get_tree().get_network_unique_id(), new_player_info)

remote func register_new_player(player_id, player_info):
	if get_tree().is_network_server(): # Only the server sends this once per client.
		for peer_id in players:
			rpc_id(player_id, "register_new_player", peer_id, players[peer_id])
	
	players[player_id] = player_info
	get_node("../World").SpawnNewPlayer(player_id, player_info["Position"])
	print(str(get_tree().get_network_unique_id()) + " registers " + str(player_id))

remote func unregister_player(player_id):
	players.erase(player_id)
	get_node("../World").DespawnPlayer(player_id)

func quit_game():
	var player_info = players[get_tree().get_network_unique_id()]
	var custom_data = {
		player_name = player_info["Name"],
		position_x = player_info["Position"].x,
		position_y = player_info["Position"].y,
	}
	Globals.quit_game()
	for key in custom_data.keys():
		SaverAndLoader.custom_data[key] = custom_data[key]
	SaverAndLoader.save_game()
	if(get_tree().is_network_server()):
		for node in get_children():
			node.queue_free()
	get_tree().set_network_peer(null)
	players.clear()
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
