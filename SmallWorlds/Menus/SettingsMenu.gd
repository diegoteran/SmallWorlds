extends Control

signal return_pressed

onready var musicSlider = $ScrollContainer/VBoxContainer/Music/Music
onready var sfxSlider = $ScrollContainer/VBoxContainer/Sfx/Sfx
onready var fullscreenCheckbox = $ScrollContainer/VBoxContainer/FullScreen/FullScreen

func _ready():
	musicSlider.value = Globals.get_music_volume()
	sfxSlider.value = Globals.get_sfx_volume()
	fullscreenCheckbox.pressed = OS.window_fullscreen
	$ScrollContainer/VBoxContainer/ReturnButton.grab_focus()

func save_settings():
	Settings.save_settings()

func _on_FullScreen_toggled(_button_pressed):
	OS.window_fullscreen = fullscreenCheckbox.pressed
	play_menu_select()

func _on_ReturnButton_pressed():
	emit_signal("return_pressed")
	play_menu_select()

func _on_Music_value_changed(value):
	Settings._settings["audio"]["music"] = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)
	save_settings()
	play_menu_select()

func _on_Sfx_value_changed(value):
	Settings._settings["audio"]["sfx"] = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value)
	save_settings()
	play_menu_select()

func play_menu_move():
	SoundFx.play_menu("Menu Move", rand_range(0.8, 1.2), -30)

func play_menu_select():
	SoundFx.play_menu("Menu Select", rand_range(0.8, 1.2), -30)


func _on_ReturnButton_focus_entered():
	play_menu_move()


func _on_ReturnButton_mouse_entered():
	play_menu_move()


func _on_Music_focus_entered():
	play_menu_move()


func _on_Sfx_focus_entered():
	play_menu_move()


func _on_Music_mouse_entered():
	play_menu_move()


func _on_Sfx_mouse_entered():
	play_menu_move()


func _on_FullScreen_focus_entered():
	play_menu_move()


func _on_FullScreen_mouse_entered():
	play_menu_move()
