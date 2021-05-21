extends Node2D

var frames = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

onready var sprite = $Sprite
onready var shadowSprite = $ShadowSprite
onready var animationPlayer = $AnimationPlayer

export var ParticleEffect: PackedScene

func _ready():
	sprite.flip_h = true if randi() % 2 == 0 else false
	sprite.get_material().set_shader_param("offset", randf() * 100)
	sprite.frame = frames[randi() % frames.size()]
	if not sprite.frame in [0, 1, 2, 9]:
		shadowSprite.scale = Vector2(0.7, 0.7)
		
	# Glow
#	var canvasItem = sprite.get_canvas_item()
#	canvasItem.set_modulate(Color(2, 2, 2, 1))

func shake():
	SoundFx.play("Evade", global_position, rand_range(0.5, 0.6), -40)
	animationPlayer.play("shake")
#	sprite.get_material().set_shader_param("speed", 10)
#	yield(get_tree().create_timer(1.0), "timeout")
#	sprite.get_material().set_shader_param("speed", 1)

func create_grass_effect():
	var particleEffect = ParticleEffect.instance()
	var image = sprite.texture.get_data()
	image.lock()
	var grass_color = image.get_pixel((sprite.frame % 3) * 16 + 10, 10)
	particleEffect.set_particles_color(grass_color)
	get_parent().add_child(particleEffect)
	particleEffect.global_position = global_position

func _on_Area2D_body_entered(_body):
	shake()
	create_grass_effect()


func _on_Area2D_area_entered(_area):
	shake()
	create_grass_effect()
