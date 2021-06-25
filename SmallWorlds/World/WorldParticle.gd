extends Node2D

export(float) var lifetime = 7.0
export(float) var lifetime_variation = 5.0

onready var particle = $Particles2D
onready var timer = $Timer
# Called when the node enters the scene tree for the first time.
func _ready():
	timer.connect("timeout", self, "on_Timer_timeout")
	timer.start(randf() * 5)


func on_Timer_timeout():
	if Globals.dead == false and Globals.player != null:
		global_position = Globals.player.global_position
	var new_lifetime = lifetime + randf() * lifetime_variation
	particle.lifetime = new_lifetime
	particle.restart()
	timer.start(new_lifetime)
