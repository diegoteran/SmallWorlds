extends Control

export var MainMenu: PackedScene # = preload("res://Menus/MainMenu.tscn")
export var SettingsMenu: PackedScene #  = preload("res://Menus/SettingsMenu.tscn")
export var MultiplayerMenu: PackedScene #  = preload("res://Menus/NetworkSetup.tscn")
export var WorldMenu : PackedScene
export var PlayerMenu : PackedScene

onready var panel = $PanelContainer
onready var tween = $Tween

var main_menu
var settings_menu
var multiplayer_menu
var world_menu
var player_menu

var panel_size = 0
var panel_size_large = 0

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
	panel_size_large = panel.rect_size + Vector2(150, 0)
	
	# Network
# warning-ignore:return_value_discarded
	Network.connect("connection_error", self, "_connection_error")

func _on_start_pressed():
	enter_world_menu(false)

func enter_world_menu(mp):
	world_menu = WorldMenu.instance()
	panel.call_deferred("add_child", world_menu)
	world_menu.connect("return_pressed", self, "_on_world_menu_exited")
	world_menu.connect("game_started", self, "_game_started_world")
	world_menu.mp = mp
	tween.interpolate_property(panel, "rect_size", panel.rect_size, panel_size_large, 1, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	main_menu.visible = false

func enter_player_menu(mp, ip):
	player_menu = PlayerMenu.instance()
	panel.call_deferred("add_child", player_menu)
	player_menu.connect("return_pressed", self, "_on_player_menu_exited")
	player_menu.connect("game_started", self, "_game_started_player")
	player_menu.mp = mp
	player_menu.ip = ip
	tween.interpolate_property(panel, "rect_size", panel.rect_size, panel_size_large, 1, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	main_menu.visible = false

func _on_multiplayer_pressed():
	multiplayer_menu = MultiplayerMenu.instance()
	panel.call_deferred("add_child", multiplayer_menu)
	multiplayer_menu.connect("return_pressed", self, "_on_multiplayer_exited")
	multiplayer_menu.connect("create_server_pressed", self, "_on_create_server_pressed")
	multiplayer_menu.connect("join_server_pressed", self, "_on_join_server_pressed")
	main_menu.visible = false

func _on_settings_pressed():
	settings_menu = SettingsMenu.instance()
	panel.call_deferred("add_child", settings_menu)
	tween.interpolate_property(panel, "rect_size", panel.rect_size, panel_size_large, 1, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	settings_menu.connect("return_pressed", self, "_On_Settings_exited")
	main_menu.visible = false

func _on_exit_pressed():
	get_tree().quit()

func _On_Settings_exited():
	settings_menu.save_settings()
	settings_menu.queue_free()
	tween.interpolate_property(panel, "rect_size", panel.rect_size, panel_size, 1, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	main_menu.visible = true
	main_menu.enable_keyboard()

func _on_multiplayer_exited():
	multiplayer_menu.queue_free()
	main_menu.visible = true
	main_menu.enable_keyboard()

func _on_world_menu_exited():
	world_menu.queue_free()
	tween.interpolate_property(panel, "rect_size", panel.rect_size, panel_size, 1, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	main_menu.visible = true
	main_menu.enable_keyboard()

func _on_player_menu_exited():
	player_menu.queue_free()
	tween.interpolate_property(panel, "rect_size", panel.rect_size, panel_size, 1, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	main_menu.visible = true
	main_menu.enable_keyboard()

func _on_create_server_pressed():
	multiplayer_menu.queue_free()
	enter_world_menu(true)

func _on_join_server_pressed(ip_address):
	multiplayer_menu.queue_free()
	enter_player_menu(false, ip_address)
	
func _game_started_world(mp : bool):
	world_menu.queue_free()
	enter_player_menu(mp, "")

func _game_started_player(mp : bool, ip : String):
	if ip == "":
		Network.call_deferred("create_server", mp)
		Music.stop_menu()
	else:
		Network.ip_address = ip
		Network.call_deferred("join_server")

func _connection_error():
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Error while connecting. Maybe try another IP."
	dialog.window_title = "Connection Error"
	dialog.connect('modal_closed', dialog, 'queue_free')
	add_child(dialog)
	dialog.popup_centered()
