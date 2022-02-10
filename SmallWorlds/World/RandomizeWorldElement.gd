extends StaticBody2D

onready var sprite = $Sprite
onready var shadowSprite = $ShadowSprite
onready var col = $CollisionShape2D
onready var visibilityArea = $VisibilityArea
onready var tween = $Tween

func _ready():
	# Connections
	visibilityArea.connect("body_entered", self, "_on_VisibilityArea_body_entered")
	visibilityArea.connect("body_exited", self, "_on_VisibilityArea_body_exited")
	
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

func _on_VisibilityArea_body_entered(_body):
	tween.interpolate_property(sprite, "modulate:a", sprite.modulate.a, 0.4, 0.4, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()

func _on_VisibilityArea_body_exited(_body):
	tween.interpolate_property(sprite, "modulate:a", sprite.modulate.a, 1, 0.4, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
