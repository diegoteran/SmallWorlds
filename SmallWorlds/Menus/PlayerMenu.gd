extends Control

export var PlayerButton : PackedScene

onready var hueSlider = $VBoxContainer/HBoxContainer/HueSlider
onready var playerLabel = $VBoxContainer/HBoxContainer/PlayerName
onready var playerList = $VBoxContainer/ScrollContainer/VBoxContainer
onready var sprite = $VBoxContainer/HBoxContainer/CenterContainer/Sprite

signal return_pressed
signal game_started(mp, client)

var font_data = preload("res://Menus/white-rabbit.regular.ttf")

var mp = false
var ip = ""
var client = false
var next_id = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	var players_path = SaverAndLoader.PLAYER_DIR 
	print(players_path)
	var players = list_files_in_directory(players_path)
	print(players)
	for player_path in players:
		generate_button(player_path)


func generate_button(player_path):
	var player_data = SaverAndLoader.open_player_file(player_path)
	
	var name_id = player_path.split("_")
	var button = PlayerButton.instance()
	button.player_name = name_id[0]
	button.name = player_path
	button.shader = player_data.player_shader
	next_id = max(next_id, int(name_id[1])) + 1
	playerList.add_child(button)
#	button.set_size(Vector2(80,20))
	button.show()
	button.connect("player_selected", self, "_pressed", [button.name])
	button.connect("player_deleted", self, "_deleted", [button.name])

func _pressed(player_path):
	SaverAndLoader.current_player = player_path
	SaverAndLoader.load_player()
	emit_signal("game_started", mp, ip)

func _deleted(player_path):
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Are you sure you want to delete this character?"
	dialog.window_title = player_path
	dialog.connect("confirmed", self, "_delete_player", [player_path])
	dialog.connect("custom_action", dialog, "queue_free")
	add_child(dialog)
	dialog.popup_centered()

func _delete_player(player_path):
	var success = SaverAndLoader.delete_player_file(player_path)
	
	if success:
		var deleted_button = playerList.get_node(player_path)
		deleted_button.queue_free()

func list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	var error = dir.open(path)
	if error != OK:
		print(error)
		return
		
	dir.list_dir_begin(true, true)
	while true:
		var file = dir.get_next()
		if file == "":
			break
		files.append(file)

	dir.list_dir_end()

	return files


func _on_ReturnButton_pressed():
	play_menu_select()
	emit_signal("return_pressed")


func _on_CreateButton_pressed():
	play_menu_select()
#	var seedText = seedLabel.text
	var playerName = playerLabel.text
	if playerName == "" or "_" in playerName or len(playerName) > 16:
		return
	
#	var world_seed = hash(seedText)
	SaverAndLoader.custom_data_player = SaverAndLoader.empty_player
	SaverAndLoader.custom_data_player.player_shader = hueSlider.value
	SaverAndLoader.custom_data_player.player_name = playerName
	SaverAndLoader.custom_data_player.player_id = next_id
	SaverAndLoader.save_player()
	
	generate_button(playerName + "_" + str(next_id))


func _on_ReturnButton_mouse_entered():
	play_menu_move()


func _on_ReturnButton_focus_entered():
	play_menu_move()


func _on_CreateButton_mouse_entered():
	play_menu_move()


func _on_CreateButton_focus_entered():
	play_menu_move()


func play_menu_move():
	SoundFx.play_menu("Menu Move", rand_range(0.8, 1.2), -30)

func play_menu_select():
	SoundFx.play_menu("Menu Select", rand_range(0.8, 1.2), -30)


func _on_HueSlider_value_changed(value):
	sprite.material.set_shader_param("Shift_Hue", value)
