extends Control

export var MainMenu: PackedScene # = preload("res://Menus/MainMenu.tscn")
export var SettingsMenu: PackedScene #  = preload("res://Menus/SettingsMenu.tscn")
export var MultiplayerMenu: PackedScene #  = preload("res://Menus/NetworkSetup.tscn")
export var WorldMenu : PackedScene

onready var panel = $PanelContainer
onready var tween = $Tween

var main_menu
var settings_menu
var multiplayer_menu
var world_menu

var panel_size = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	main_menu = MainMenu.instance()
	panel.call_deferred("add_child", main_menu)
	main_menu.connect("start_pressed", self, "_on_start_pressed")
	main_menu.connect("multiplayer_pressed", self, "_on_multiplayer_pressed")
	main_menu.connect("settings_pressed", self, "_on_settings_pressed")
	main_menu.connect("exit_pressed", self, "_on_exit_pressed")
	Music.play_menu()
	
	# Weird bugs
	panel_size = panel.rect_size

func _on_start_pressed():
	enter_world_menu(false)

func enter_world_menu(mp):
	world_menu = WorldMenu.instance()
	panel.call_deferred("add_child", world_menu)
	world_menu.connect("return_pressed", self, "_on_world_menu_exited")
	world_menu.connect("game_started", self, "_game_started")
	world_menu.mp = mp
	tween.interpolate_property(panel, "rect_size", panel.rect_size, panel.rect_size + Vector2(150, 0), 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	main_menu.visible = false

func _on_multiplayer_pressed():
	multiplayer_menu = MultiplayerMenu.instance()
	panel.call_deferred("add_child", multiplayer_menu)
	multiplayer_menu.connect("return_pressed", self, "_on_multiplayer_exited")
	multiplayer_menu.connect("create_server_pressed", self, "_on_create_server_pressed")
	main_menu.visible = false

func _on_settings_pressed():
	settings_menu = SettingsMenu.instance()
	panel.call_deferred("add_child", settings_menu)
	tween.interpolate_property(panel, "rect_size", panel.rect_size, panel.rect_size + Vector2(150, 0), 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	settings_menu.connect("return_pressed", self, "_On_Settings_exited")
	main_menu.visible = false

func _on_exit_pressed():
	get_tree().quit()

func _On_Settings_exited():
	settings_menu.save_settings()
	settings_menu.queue_free()
	tween.interpolate_property(panel, "rect_size", panel.rect_size, panel_size, 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	main_menu.visible = true
	main_menu.enable_keyboard()

func _on_multiplayer_exited():
	multiplayer_menu.queue_free()
	main_menu.visible = true
	main_menu.enable_keyboard()

func _on_world_menu_exited():
	world_menu.queue_free()
	tween.interpolate_property(panel, "rect_size", panel.rect_size, panel_size, 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	main_menu.visible = true
	main_menu.enable_keyboard()

func _on_create_server_pressed():
	multiplayer_menu.queue_free()
	enter_world_menu(true)
	

func _game_started():
	Music.stop_menu()
