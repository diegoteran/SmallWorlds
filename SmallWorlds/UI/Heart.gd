extends Node2D

onready var animationPlayer = $AnimationPlayer
onready var sprite = $Sprite
onready var tween = $Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func damaged():
	animationPlayer.play("RemoveHeart")
	tween.interpolate_property(sprite, 'scale', Vector2(rand_range(0.4, 0.6), rand_range(0.4, 0.6)), Vector2.ONE / 2, 2, Tween.TRANS_ELASTIC)
	tween.start()

func regened():
	animationPlayer.play("RegainHeart")
	tween.interpolate_property(sprite, 'scale', Vector2(rand_range(0.4, 0.6), rand_range(0.4, 0.6)), Vector2.ONE / 2, 2, Tween.TRANS_ELASTIC)
	tween.start()
