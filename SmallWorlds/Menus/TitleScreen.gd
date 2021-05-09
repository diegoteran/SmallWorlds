extends Control

const MainMenu = preload("res://Menus/MainMenu.tscn")
const SettingsMenu = preload("res://Menus/SettingsMenu.tscn")
const MultiplayerMenu = preload("res://Menus/NetworkSetup.tscn")

onready var panel = $PanelContainer

var main_menu
var settings_menu
var multiplayer_menu

# Called when the node enters the scene tree for the first time.
func _ready():
	main_menu = MainMenu.instance()
	panel.call_deferred("add_child", main_menu)
	main_menu.connect("start_pressed", self, "_on_start_pressed")
	main_menu.connect("multiplayer_pressed", self, "_on_multiplayer_pressed")
	main_menu.connect("settings_pressed", self, "_on_settings_pressed")
	main_menu.connect("exit_pressed", self, "_on_exit_pressed")
	
	Music.list_play()

func _on_start_pressed():
	pass

func _on_multiplayer_pressed():
	multiplayer_menu = MultiplayerMenu.instance()
	panel.call_deferred("add_child", multiplayer_menu)
	main_menu.visible = false

func _on_settings_pressed():
	settings_menu = SettingsMenu.instance()
	panel.call_deferred("add_child", settings_menu)
	panel.rect_size += Vector2(150, 0)
	settings_menu.connect("return_pressed", self, "_On_Settings_exited")
	main_menu.visible = false

func _on_exit_pressed():
	get_tree().quit()

func _On_Settings_exited():
	settings_menu.save_settings()
	settings_menu.queue_free()
	panel.rect_size -= Vector2(150, 0)
	main_menu.visible = true
	main_menu.enable_keyboard()
