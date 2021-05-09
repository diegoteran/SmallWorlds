extends Control

signal return_pressed

onready var musicSlider = $ScrollContainer/VBoxContainer/Music/Music
onready var sfxSlider = $ScrollContainer/VBoxContainer/Sfx/Sfx

func _ready():
	musicSlider.value = Globals.get_music_volume()
	sfxSlider.value = Globals.get_sfx_volume()
	$ScrollContainer/VBoxContainer/ReturnButton.grab_focus()

func save_settings():
	Settings.save_settings()

func _on_FullScreen_toggled(_button_pressed):
	OS.window_fullscreen = !OS.window_fullscreen
	play_menu_select()

func _on_ReturnButton_pressed():
	emit_signal("return_pressed")
	play_menu_select()

func _on_Music_value_changed(value):
	Settings._settings["audio"]["music"] = value
	Music.set_music_volume()
	save_settings()
	play_menu_select()

func _on_Sfx_value_changed(value):
	Settings._settings["audio"]["sfx"] = value
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
