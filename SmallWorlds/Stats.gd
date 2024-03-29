extends Node

var max_health = 1 setget set_max_health
var max_soul = 10 setget set_max_soul
var health = 0 setget set_health
var soul = 0 setget set_soul
var max_rock = 30
var rocks = [0, 0]
var level = 0

enum {
	GREEN,
	RED
}

signal no_health
signal soul_charged
signal research_completed(type)
signal health_changed(value)
signal max_health_changed(value)
signal soul_changed(value)
signal max_soul_changed(value)
signal rock_changed(value, type)

func _ready():
	print(self.get_path())

func set_health(value):
	health = min(value, max_health)
	SaverAndLoader.custom_data_player.player_health = health
	emit_signal("health_changed", health)
	if health <= 0:
		emit_signal("no_health")

func set_max_health(value):
	max_health = value
	print(self.get_path())
	SaverAndLoader.custom_data_player.player_max_health = max_health
	emit_signal("max_health_changed", max_health)

func set_soul(value):
	var prev_soul = soul
	soul = min(value, max_soul)
	emit_signal("soul_changed", soul)
	SaverAndLoader.custom_data_player.player_soul = soul
	if soul ==  max_soul and soul != prev_soul:
		emit_signal("soul_charged")

func set_max_soul(value):
	max_soul = value
	self.soul = min(soul, max_soul)
	SaverAndLoader.custom_data_player.player_max_soul = max_soul
	emit_signal("max_soul_changed", max_soul)

func set_rock(value, type):
	rocks[type] = min(value, max_rock)
	emit_signal("rock_changed", rocks[type], type)
	SaverAndLoader.custom_data_player.player_research[type] = rocks[type]
	if rocks[type] ==  max_rock:
		if level < type + 1:
			emit_signal("research_completed", type)
			level = type + 1
			SaverAndLoader.custom_data_player.player_level = level
			SaverAndLoader.save_player()

func update():
	for i in range(2):
		set_rock(SaverAndLoader.custom_data_player.player_research[i], i)
	set_max_soul(SaverAndLoader.custom_data_player.player_max_soul)
	set_soul(SaverAndLoader.custom_data_player.player_soul)
	set_max_health(SaverAndLoader.custom_data_player.player_max_health)
	set_health(SaverAndLoader.custom_data_player.player_health)
	level = SaverAndLoader.custom_data_player.player_level
	emit_signal("research_completed", level - 1)
