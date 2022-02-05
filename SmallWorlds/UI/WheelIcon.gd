extends Position2D

var level = 0

onready var sprite = $Sprite
onready var animationPlayer = $AnimationPlayer

func _ready():
	sprite.material.set_shader_param("Shift_Hue", Globals.shader_dict[int(PlayerStats.level)])

func set_frame(item_id):
	sprite.frame = item_id

func set_rot(rot):
	rotation_degrees = rot
	sprite.rotation_degrees = -rot

func start_hover():
	animationPlayer.play("Hovered")

func stop_hover():
	animationPlayer.play("Idle")
