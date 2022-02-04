extends KinematicBody2D

export var SPEED = 400

var velocity = Vector2.ZERO

onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.start(3)

func _physics_process(delta):
	var _collision = move_and_slide(velocity * SPEED)
#	if collision != null:
#		_on_impact(collision)
#
#func _on_impact(collision):
#	pass

func _on_Timer_timeout():
	queue_free()

func delete():
	rpc("delete_all")

remotesync func delete_all():
	queue_free()
