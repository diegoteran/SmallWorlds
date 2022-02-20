extends Node2D

onready var animationPlayer = $AnimationPlayer
onready var sprite = $Sprite
onready var tween = $Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func lose_soul():
	animationPlayer.play("RemoveSoul")
	tween.interpolate_property(sprite, 'scale', Vector2(rand_range(0.4, 0.6), rand_range(0.4, 0.6)), Vector2.ONE / 2, 0.5, Tween.TRANS_ELASTIC)
	tween.start()

func gain_soul():
	animationPlayer.play("RegainSoul")
	tween.interpolate_property(sprite, 'scale', Vector2(rand_range(0.4, 0.6), rand_range(0.4, 0.6)), Vector2.ONE / 2, 1, Tween.TRANS_ELASTIC)
	tween.start()
