extends KinematicBody2D

export var SPEED = 300
export var GhostArrow: PackedScene

var velocity = Vector2.ZERO
var level = 0

onready var timer = $Timer
onready var sprite = $Sprite
onready var tween = $Tween
onready var ghostTimer = $GhostTimer

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.start(3)
	sprite.rotation += velocity.angle()
	sprite.material.set_shader_param("Shift_Hue", Globals.shader_dict[int(level)])
	
	tween.interpolate_property(sprite, "modulate", Color(1, 1, 1, 0.0), Color(1, 1, 1, 1), 0.1, Tween.TRANS_LINEAR)
	tween.start()
	
	ghostTimer.wait_time = 0.05
	ghostTimer.start()

func _physics_process(_delta):
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


func _on_GhostTimer_timeout():
	var ghostArrow = Globals.instance_scene_on_world(GhostArrow, global_position)
	ghostArrow.rotation = sprite.rotation
