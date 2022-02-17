extends Control

onready var seedLabel = $VBoxContainer/HBoxContainer/Seed
onready var worldLabel = $VBoxContainer/HBoxContainer/WorldName
onready var worldList = $VBoxContainer/ScrollContainer/VBoxContainer

signal return_pressed
signal game_started(mp)

var mp = false
# Called when the node enters the scene tree for the first time.
func _ready():
	var worlds_path = SaverAndLoader.WORLD_DIR 
	print(worlds_path)
	var worlds = list_files_in_directory(worlds_path)
	print(worlds)
	for world_path in worlds:
		generate_button(world_path)


func generate_button(world_path):
	var name_seed = world_path.split("_")
	var button = Button.new()
	button.name = world_path
	button.text = name_seed[0]
	worldList.add_child(button)
#	button.set_size(Vector2(80,20))
	button.show()
	button.connect("pressed", self, "_pressed", [button.name])

func _pressed(world_path):
	SaverAndLoader.current_world = world_path
	SaverAndLoader.load_world()
	emit_signal("game_started", mp)

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
	var seedText = seedLabel.text
	var worldText = worldLabel.text
	if seedText == "" or "_" in seedText or worldText == "" or "_" in worldText:
		return
	
	var world_seed = hash(seedText)
	SaverAndLoader.custom_data_world.world_seed = world_seed
	SaverAndLoader.custom_data_world.world_name = worldText
	SaverAndLoader.save_world()
	
	generate_button(worldText + "_" + str(world_seed))


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
