extends Node2D

onready var animationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func damaged():
	animationPlayer.play("RemoveHeart")

func regened():
	animationPlayer.play("RegainHeart")
