extends Control

onready var multiplayerConfigure = $MultiplayerConfigure
onready var serverAddress = $MultiplayerConfigure/CenterContainer/VBoxContainer/ServerAddress
onready var address = $MultiplayerConfigure/CenterContainer/VBoxContainer/Address
onready var playerName = $MultiplayerConfigure/CenterContainer/VBoxContainer/PlayerName
onready var createServer = $MultiplayerConfigure/CenterContainer/VBoxContainer/CreateServerButton


func _ready():
	randomize()
	address.text = Network.ip_address
	SaverAndLoader.load_game()
	
	var savedPlayerName = SaverAndLoader.custom_data.player_name
	if savedPlayerName != "":
		playerName.text = savedPlayerName
	
	createServer.grab_focus()

func _on_CreateServerButton_pressed():
	SoundFx.play_menu("Menu Select", rand_range(0.8, 1.2), -30)
	to_join_world()
	# warning-ignore:return_value_discarded
	get_tree().change_scene("res://World/World.tscn")
	Network.call_deferred("create_server", true)
	queue_free()


func _on_JoinServerButton_pressed():
	SoundFx.play_menu("Menu Select", rand_range(0.8, 1.2), -30)
	to_join_world()
	
	if serverAddress.text != "":
		# warning-ignore:return_value_discarded
		get_tree().change_scene("res://World/World.tscn")
		Network.ip_address = serverAddress.text
		Network.call_deferred("join_server")
		queue_free()


func to_join_world():
	SaverAndLoader.custom_data.player_name = playerName.text
	SaverAndLoader.save_game()
	Music.list_stop()


func _on_CreateServerButton_focus_entered():
	play_menu_move()


func _on_JoinServerButton_focus_entered():
	play_menu_move()

func play_menu_move():
	SoundFx.play_menu("Menu Move", rand_range(0.8, 1.2), -30)

func _on_CreateServerButton_mouse_entered():
	play_menu_move()

func _on_JoinServerButton_mouse_entered():
	play_menu_move()
