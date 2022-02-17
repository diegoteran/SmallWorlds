extends Control

onready var multiplayerConfigure = $MultiplayerConfigure
onready var serverAddress = $MultiplayerConfigure/CenterContainer/VBoxContainer/VBoxContainer/ServerAddress
onready var address = $MultiplayerConfigure/CenterContainer/VBoxContainer/VBoxContainer/Address
onready var createServer = $MultiplayerConfigure/CenterContainer/VBoxContainer/VBoxContainer/CreateServerButton

signal return_pressed
signal create_server_pressed
signal join_server_pressed(ip)

func _ready():
	address.text = Network.ip_address
	SaverAndLoader.load_player()
	PlayerStats.update()
	
	createServer.grab_focus()
	
	# warning-ignore:return_value_discarded
	get_tree().connect("connected_to_server", self, "_connected_ok")
	# warning-ignore:return_value_discarded
	get_tree().connect("connection_failed", self, "_connection_failed")

func _on_CreateServerButton_pressed():
	play_menu_select()
	emit_signal("create_server_pressed")


func _on_JoinServerButton_pressed():
	play_menu_select()
	
	if serverAddress.text != "":
		emit_signal("join_server_pressed", "73.97.136.126")

func _connected_ok():
	Music.stop_menu()

func _on_CreateServerButton_focus_entered():
	play_menu_move()

func _on_JoinServerButton_focus_entered():
	play_menu_move()

func play_menu_move():
	SoundFx.play_menu("Menu Move", rand_range(0.8, 1.2), -30)

func play_menu_select():
	SoundFx.play_menu("Menu Select", rand_range(0.8, 1.2), -30)

func _on_CreateServerButton_mouse_entered():
	play_menu_move()

func _on_JoinServerButton_mouse_entered():
	play_menu_move()


func _on_ReturnButton_pressed():
	emit_signal("return_pressed")
	play_menu_select()


func _on_ReturnButton_focus_entered():
	play_menu_move()


func _on_ReturnButton_mouse_entered():
	play_menu_move()
