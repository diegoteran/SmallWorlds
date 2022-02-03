extends StaticBody2D

export var ParticleEffect: PackedScene
export var hp = 10 setget set_hp
export var max_hp = 10
var type = GREEN
export var days_to_recover = 2
var empty_sprite_green = preload("res://PixelArt/Mining/rock 2 broken.png")
var full_sprite_green = preload("res://PixelArt/Mining/rock 2.png")
var empty_sprite_red = preload("res://PixelArt/Mining/rock 3 broken.png")
var full_sprite_red = preload("res://PixelArt/Mining/rock 3.png")

var state = WITH
var days_timer = 0

enum {
	GREEN,
	RED
}

enum {
	EMPTY,
	WITH
}

onready var hurtBox = $HurtBox
onready var tween = $Tween
onready var sprite = $Sprite


# Called when the node enters the scene tree for the first time.
func _ready():
	hurtBox.connect("area_entered", self, "_on_HurtBox_area_entered")
	connect("mouse_entered", self, "_on_Rock_mouse_entered")
	connect("mouse_exited", self, "_on_Rock_mouse_exited")
	
	match type:
		GREEN:
			sprite.texture = full_sprite_green
		RED:
			sprite.texture = full_sprite_red
	
	# Light Handler
	if is_network_master():
		var cycle = get_node("/root/World/DayNightCycle")
		cycle.connect("light_changed", self, "set_lights")
#	if cycle.is_night:
#		set_lights(true)

func set_hp(new_value):
	if new_value != hp:
		hp = new_value
		if hp <= 0:
			_on_empty()

func set_lights(value):
	if days_timer > 0 and !value:
		days_timer = days_timer - 1
		if days_timer == 1:
			rpc('one_day')
		if days_timer == 0:
			rpc('replenish')

remotesync func one_day():
	sprite.frame = 0

remotesync func replenish():
	if state == EMPTY:
		match type:
			GREEN:
				sprite.texture = full_sprite_green
			RED:
				sprite.texture = full_sprite_red
		sprite.hframes = 4
		sprite.frame = 3
		state = WITH
		hp = max_hp

func _on_HurtBox_area_entered(area):
	if area.is_network_master():
		Shake.shake(1.5, 0.3, 2)
		var new_hp = hp - area.damage
		if hp > 0:
			area.get_parent().get_parent().get_parent().get_parent().add_rock(rand_range(0.5, 1))
		rpc('hit_effect', new_hp)

remotesync func hit_effect(new_hp: float):
	self.hp = max(0, new_hp)
	SoundFx.play('RockHit', global_position, rand_range(0.5, 0.8), -20)
	tween.interpolate_property(sprite, 'scale', Vector2(rand_range(0.8, 1.2), rand_range(0.8, 1.2)), Vector2.ONE, 0.2, Tween.TRANS_ELASTIC)
	tween.start()
	if state == WITH:
		var particleEffect = ParticleEffect.instance()
		particleEffect.set_particles_color(Color.gray)
		get_parent().add_child(particleEffect)
		particleEffect.global_position = global_position

func _on_empty():
	if state == WITH:
		state = EMPTY
		SoundFx.play('RockBreak', global_position, rand_range(0.5, 0.8), -20)
		match type:
			GREEN:
				sprite.texture = empty_sprite_green
			RED:
				sprite.texture = empty_sprite_red
		sprite.hframes = 2
		sprite.frame = 1
		if is_network_master():
			days_timer = days_to_recover


func _on_Rock_mouse_entered():
	sprite.material.set_shader_param('color', Color.white)

func _on_Rock_mouse_exited():
	sprite.material.set_shader_param('color', Color.transparent)
