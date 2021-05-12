extends Control

const SettingsMenu = preload("res://Menus/SettingsMenu.tscn")

onready var panel = $PanelContainer
onready var pause_menu = $PanelContainer/VBoxContainer
onready var resume_button = $PanelContainer/VBoxContainer/ResumeButton
onready var tween = $Tween

var settings_menu

var paused = false setget set_paused
var controller_used = false

func set_paused(value):
	paused = value
#	get_tree().paused = paused
	visible = paused

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		play_menu_select()
		self.paused = !paused
		Globals.player.paused = self.paused
		if not self.paused:
			_On_Settings_exited()
			
		
		var controller_id_arr = Input.get_connected_joypads()
		if controller_id_arr.size() > 0 and Input.is_joy_button_pressed(controller_id_arr[0], JOY_BUTTON_11):
			resume_button.grab_focus()
			controller_used = true
		else:
			controller_used = false

func _on_ResumeButton_pressed():
	play_menu_select()
	self.paused = !paused
	Globals.player.paused = self.paused


func _on_SettingsButton_pressed():
	play_menu_select()
	settings_menu = SettingsMenu.instance()
	panel.call_deferred("add_child", settings_menu)
	tween.interpolate_property(panel, "rect_size", panel.rect_size, panel.rect_size + Vector2(150, 0), 0.1)
	tween.start()
	settings_menu.connect("return_pressed", self, "_On_Settings_exited")
	pause_menu.visible = false

func _On_Settings_exited():
	settings_menu.save_settings()
	settings_menu.queue_free()
	tween.interpolate_property(panel, "rect_size", panel.rect_size, panel.rect_size - Vector2(150, 0), 0.1)
	tween.start()
	pause_menu.visible = true
	if controller_used:
		resume_button.grab_focus()
	settings_menu = null
	

func _on_ExitButton_pressed():
	Network.quit_game()


func _on_ResumeButton_focus_entered():
	play_menu_move()


func _on_SettingsButton_focus_entered():
	play_menu_move()


func _on_ExitButton_focus_entered():
	play_menu_move()


func _on_ResumeButton_mouse_entered():
	play_menu_move()


func _on_SettingsButton_mouse_entered():
	play_menu_move()


func _on_ExitButton_mouse_entered():
	play_menu_move()

func play_menu_move():
	SoundFx.play_menu("Menu Move", rand_range(0.8, 1.2), -30)

func play_menu_select():
	SoundFx.play_menu("Menu Select", rand_range(0.8, 1.2), -30)
