extends StaticBody2D

export var ParticleEffect: PackedScene

onready var hurtBox = $HurtBox
onready var tween = $Tween
onready var sprite = $Sprite

# Called when the node enters the scene tree for the first time.
func _ready():
	hurtBox.connect("area_entered", self, "_on_HurtBox_area_entered")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _on_HurtBox_area_entered(area):
	Shake.shake(1.5, 0.3, 2)
	hit_effect()
	SoundFx.play('RockHit', global_position, rand_range(0.5, 0.8), -20)
	

func hit_effect():
	var particleEffect = ParticleEffect.instance()
	particleEffect.set_particles_color(Color.gray)
	get_parent().add_child(particleEffect)
	particleEffect.global_position = global_position
	
	tween.interpolate_property(sprite, 'scale', Vector2(rand_range(0.8, 1.2), rand_range(0.8, 1.2)), Vector2.ONE, 0.2, Tween.TRANS_ELASTIC)
	tween.start()
