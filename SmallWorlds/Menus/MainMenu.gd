extends Control

signal start_pressed
signal multiplayer_pressed
signal settings_pressed
signal exit_pressed

onready var startButton = $VBoxContainer/StartButton

func _ready():
	startButton.grab_focus()
	SaverAndLoader.load_player()
	SaverAndLoader.load_world()

func enable_keyboard():
	startButton.grab_focus()

func _on_StartButton_pressed():
	emit_signal("start_pressed")
	play_menu_select()
	Network.call_deferred("create_server", false)
	queue_free()


func _on_MultiplayerButton_pressed():
	emit_signal("multiplayer_pressed")
	play_menu_select()


func _on_SettingsButton_pressed():
	emit_signal("settings_pressed")
	play_menu_select()


func _on_ExitButton_pressed():
	emit_signal("exit_pressed")
	play_menu_select()


func _on_StartButton_mouse_entered():
	play_menu_move()


func _on_MultiplayerButton_mouse_entered():
	play_menu_move()


func _on_SettingsButton_mouse_entered():
	play_menu_move()


func _on_ExitButton_mouse_entered():
	play_menu_move()

func play_menu_move():
	SoundFx.play_menu("Menu Move", rand_range(0.8, 1.2), -30)

func play_menu_select():
	SoundFx.play_menu("Menu Select", rand_range(0.8, 1.2), -30)


func _on_StartButton_focus_entered():
	play_menu_move()


func _on_MultiplayerButton_focus_entered():
	play_menu_move()


func _on_SettingsButton_focus_entered():
	play_menu_move()


func _on_ExitButton_focus_entered():
	play_menu_move()
