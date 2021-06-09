extends StaticBody2D

onready var sprite = $Sprite
onready var shadowSprite = $Sprite/ShadowSprite
onready var col = $CollisionShape2D

func _ready():
	# Shader
#	sprite.get_material().set_shader_param("offset", randf() * 100)
	if (randf() < 0.5):
		sprite.material = null
	
	# Scaling
	var scale_factor = rand_range(1, 1.2) 
	var scale_vec = Vector2(scale_factor, scale_factor)
	sprite.scale = scale_vec
	shadowSprite.scale *= scale_vec
	col.scale = scale_vec
	
	# Facing
	var switch_facing = true if randi() % 2 == 0 else false
	sprite.flip_h = switch_facing
	shadowSprite.flip_h = switch_facing

