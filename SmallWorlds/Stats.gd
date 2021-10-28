extends Node

export(int) var max_health = 1 setget set_max_health
var max_soul = 10 setget set_max_soul
var health = max_health setget set_health
var soul = 0 setget set_soul

signal no_health
signal soul_charged
signal health_changed(value)
signal max_health_changed(value)
signal soul_changed(value)
signal max_soul_changed(value)

func set_health(value):
	health = min(value, max_health)
	emit_signal("health_changed", health)
	if health <= 0:
		emit_signal("no_health")

func set_max_health(value):
	max_health = value
	self.health = min(health, max_health)
	emit_signal("max_health_changed", max_health)

func set_soul(value):
	soul = min(value, max_soul)
	emit_signal("soul_changed", soul)
	if soul ==  max_soul:
		emit_signal("soul_charged")

func set_max_soul(value):
	max_soul = value
	self.soul = min(soul, max_soul)
	emit_signal("max_soul_changed", max_soul)

func _ready():
	self.health = max_health
