extends Control

export var SettingsMenu: PackedScene # = preload("res://Menus/SettingsMenu.tscn")
export var HowMenu: PackedScene

onready var panel = $PanelContainer
onready var pause_menu = $PanelContainer/VBoxContainer
onready var resume_button = $PanelContainer/VBoxContainer/ResumeButton
onready var tween = $Tween

var settings_menu
var how_menu

var paused = false setget set_paused
var controller_used = false

var panel_size = 0
var panel_size_large = 0
var panel_size_xlarge = 0

func _ready():
	# Weird bugs
	panel_size = panel.rect_size
	panel_size_large = panel.rect_size + Vector2(150, 0)
	panel_size_xlarge = panel.rect_size + Vector2(250, 0)

func set_paused(value):
	paused = value
#	get_tree().paused = paused
	visible = paused

func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		play_menu_select()
		self.paused = !paused
		if Globals.player != null:
			Globals.player.paused = self.paused
		if not self.paused and settings_menu != null:
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
	tween.interpolate_property(panel, "rect_size", panel.rect_size, panel_size_large, 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	settings_menu.connect("return_pressed", self, "_On_Settings_exited")
	pause_menu.visible = false

func _On_Settings_exited():
	settings_menu.save_settings()
	settings_menu.queue_free()
	tween.interpolate_property(panel, "rect_size", panel.rect_size, panel_size, 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	pause_menu.visible = true
	if controller_used:
		resume_button.grab_focus()
	settings_menu = null
	
func _on_how_pressed():
	how_menu = HowMenu.instance()
	panel.call_deferred("add_child", how_menu)
	tween.interpolate_property(panel, "rect_size", panel.rect_size, panel_size_xlarge, 1, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	how_menu.connect("return_pressed", self, "_On_How_exited")
	pause_menu.visible = false

func _On_How_exited():
	how_menu.queue_free()
	tween.interpolate_property(panel, "rect_size", panel.rect_size, panel_size, 1, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	pause_menu.visible = true

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


func _on_HowButton_mouse_entered():
	play_menu_move()


func _on_HowButton_focus_entered():
	play_menu_move()


func _on_HowButton_pressed():
	_on_how_pressed()
