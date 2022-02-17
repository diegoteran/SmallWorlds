extends Control

onready var hueSlider = $VBoxContainer/HBoxContainer/HueSlider
onready var playerLabel = $VBoxContainer/HBoxContainer/PlayerName
onready var playerList = $VBoxContainer/ScrollContainer/VBoxContainer

signal return_pressed
signal game_started(mp, client)

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
	var name_id = player_path.split("_")
	var button = Button.new()
	button.name = player_path
	button.text = name_id[0]
	next_id = max(next_id, int(name_id[1])) + 1
	playerList.add_child(button)
#	button.set_size(Vector2(80,20))
	button.show()
	button.connect("pressed", self, "_pressed", [button.name])

func _pressed(player_path):
	SaverAndLoader.current_player = player_path
	SaverAndLoader.load_player()
	emit_signal("game_started", mp, ip)

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
	if playerName == "" or "_" in playerName:
		return
	
#	var world_seed = hash(seedText)
#	SaverAndLoader.custom_data_world.world_seed = world_seed
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
