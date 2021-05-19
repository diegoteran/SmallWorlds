extends Position2D

onready var sprite = $Sprite
onready var animationPlayer = $AnimationPlayer

func set_frame(item_id):
	sprite.frame = item_id

func set_rot(rot):
	rotation_degrees = rot
	sprite.rotation_degrees = -rot

func start_hover():
	animationPlayer.play("Hovered")

func stop_hover():
	animationPlayer.play("Idle")
