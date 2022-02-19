extends StaticBody2D

export var ParticleEffect: PackedScene
export var hp = 10 setget set_hp
export var max_hp = 10
var type = GREEN
export var days_to_recover = 2
var empty_sprite_green = preload("res://PixelArt/Mining/rock 2 broken.png")
var empty_sprite_green_n = preload("res://PixelArt/Mining/rock 2 broken_n.png")
var full_sprite_green = preload("res://PixelArt/Mining/rock 2.png")
var full_sprite_green_n = preload("res://PixelArt/Mining/rock 2_n.png")
var empty_sprite_red = preload("res://PixelArt/Mining/rock 3 broken.png")
var empty_sprite_red_n = preload("res://PixelArt/Mining/rock 3 broken_n.png")
var full_sprite_red = preload("res://PixelArt/Mining/rock 3.png")
var full_sprite_red_n = preload("res://PixelArt/Mining/rock 3_n.png")

var state = WITH
var days_timer = 0
var GRID_SIZE = float(Globals.world_size)

enum {
	GREEN = 0,
	RED = 1
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
# warning-ignore:return_value_discarded
	connect("mouse_entered", self, "_on_Rock_mouse_entered")
# warning-ignore:return_value_discarded
	connect("mouse_exited", self, "_on_Rock_mouse_exited")
	
	var prob = (float(global_position.x) / GRID_SIZE) * (float(global_position.y) / GRID_SIZE)
	type = RED if prob > randf() else GREEN
	
	match type:
		GREEN:
			sprite.texture = full_sprite_green
			sprite.normal_map = full_sprite_green_n
		RED:
			sprite.texture = full_sprite_red
			sprite.normal_map = full_sprite_red_n
	
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
	
	if days_timer == 0 and !value:
		rpc_id(0, "sync_types", type)

remotesync func sync_types(new_type):
	type = new_type
	match type:
		GREEN:
			sprite.texture = full_sprite_green
			sprite.normal_map = full_sprite_green_n
		RED:
			sprite.texture = full_sprite_red
			sprite.normal_map = full_sprite_red_n

remotesync func one_day():
	sprite.frame = 0

remotesync func replenish():
	if state == EMPTY:
		match type:
			GREEN:
				sprite.texture = full_sprite_green
				sprite.normal_map = full_sprite_green_n
			RED:
				sprite.texture = full_sprite_red
				sprite.normal_map = full_sprite_red_n
		sprite.hframes = 4
		sprite.frame = 3
		state = WITH
		hp = max_hp

func _on_HurtBox_area_entered(area):
	if area.is_network_master():
		Shake.shake(1.5, 0.3, 2)
		var new_hp = hp
		var player_node_path = ""
		if "Arrow" in area.get_parent().name:
			area.get_parent().delete()
		else:
			var player = area.get_parent().get_parent().get_parent().get_parent()
			if hp > 0 and player.wheel_id == 1 and area.get_parent().get_parent().level >= type:
				player.add_rock(rand_range(0.8, 1.3), type)
				new_hp -= 1
			player_node_path = player.get_path()
		rpc('hit_effect', new_hp, player_node_path)

remotesync func hit_effect(new_hp: float, player_node_path: String):
	self.hp = max(0, new_hp)
	SoundFx.play('RockHit', global_position, rand_range(0.5, 0.8), -20)
	tween.interpolate_property(sprite, 'scale', Vector2(rand_range(0.8, 1.2), rand_range(0.8, 1.2)), Vector2.ONE, 0.2, Tween.TRANS_ELASTIC)
	tween.start()
	
	if is_network_master():
		aggro_enemies(player_node_path)
	
	if state == WITH:
		var particleEffect = ParticleEffect.instance()
		particleEffect.set_particles_color(Color.gray)
		get_parent().add_child(particleEffect)
		particleEffect.global_position = global_position

func aggro_enemies(player_node_path: String):
	var enemies = get_node("/root/World/YSort/Enemies")
	var player = get_node(player_node_path)
	for enemy in enemies.get_children():
		if player != null and enemy.is_in_group("Enemy") and enemy.global_position.distance_to(player.global_position) < Globals.ENEMY_DISTANCE_TO_PLAYERS[0] * 1.3:
			enemy.aggroed(player)

func _on_empty():
	if state == WITH:
		state = EMPTY
		SoundFx.play('RockBreak', global_position, rand_range(0.5, 0.8), -20)
		match type:
			GREEN:
				sprite.texture = empty_sprite_green
				sprite.normal_map = empty_sprite_green_n
			RED:
				sprite.texture = empty_sprite_red
				sprite.normal_map = empty_sprite_red_n
		sprite.hframes = 2
		sprite.frame = 1
		if is_network_master():
			days_timer = days_to_recover


func _on_Rock_mouse_entered():
	sprite.material.set_shader_param('color', Color.white)

func _on_Rock_mouse_exited():
	sprite.material.set_shader_param('color', Color.transparent)
