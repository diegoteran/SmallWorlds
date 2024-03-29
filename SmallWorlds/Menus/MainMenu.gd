extends Control

signal start_pressed
signal multiplayer_pressed
signal settings_pressed
signal exit_pressed
signal how_pressed

onready var startButton = $VBoxContainer/StartButton
onready var multiplayerButton = $VBoxContainer/MultiplayerButton
onready var settingsButton = $VBoxContainer/SettingsButton
onready var exitButton = $VBoxContainer/ExitButton
onready var howButton = $VBoxContainer/HowButton
onready var twitterButton = $VBoxContainer/Twitter

func _ready():
	startButton.grab_focus()

func enable_keyboard():
	startButton.grab_focus()

func _on_StartButton_pressed():
	emit_signal("start_pressed")
	play_menu_select()

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
	startButton.grab_focus()


func _on_MultiplayerButton_mouse_entered():
	multiplayerButton.grab_focus()


func _on_SettingsButton_mouse_entered():
	settingsButton.grab_focus()


func _on_ExitButton_mouse_entered():
	exitButton.grab_focus()

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


func _on_HowButton_mouse_entered():
	howButton.grab_focus()


func _on_HowButton_focus_entered():
	play_menu_move()


func _on_HowButton_pressed():
	emit_signal("how_pressed")
	play_menu_select()


func _on_Twitter_pressed():
# warning-ignore:return_value_discarded
	OS.shell_open("https://twitter.com/diegoterandev")


func _on_Twitter_focus_entered():
	play_menu_move()


func _on_Twitter_mouse_entered():
	twitterButton.grab_focus()
