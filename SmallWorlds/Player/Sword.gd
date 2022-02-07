extends Node2D

var offset = 90
var smoketrail : Object = null
var trail_name
var smokeTrail
#var sword_dict = {"Starting": {}}
var damage_dict = [{0:1, 1: 0.5, 2:0.3}, {0:1.5, 1: 1, 2:0.5}, {0:3, 1: 2, 2:1}]
var level = 0

export var SmokeTrail : PackedScene

onready var tween = $Tween
onready var pos = $P
onready var swordEnd = $P/P
onready var sprite = $P/Sprite
onready var hitboxCollision = $P/HitBox/CollisionShape2D
onready var hitbox = $P/HitBox

puppet var p_rotation = 0
#puppet var p_flip = false

remotesync var id = 0

func _ready():
	trail_name = get_parent().get_parent().name + "_trail"
	smokeTrail = Globals.instance_scene_on_world_with_name(SmokeTrail, Vector2.ZERO, trail_name)
	
# warning-ignore:return_value_discarded
	PlayerStats.connect("research_completed", self, "_on_level_up")

func _process(_delta):
	smokeTrail.global_position = global_position
	smokeTrail.add_point(swordEnd.global_position)
	
	if is_network_master():
		pos.look_at(get_global_mouse_position())
		
		if id != 2:
			pos.rotation_degrees += offset
			sprite.rotation_degrees = -pos.rotation_degrees
		
		if Network.players.size() > 1:
			rpc_unreliable("sync_puppet_variables", pos.rotation_degrees)
#			rset_unreliable("p_flip", sprite.flip_h)
	
	else:
		tween.interpolate_property(pos, "rotation_degrees", pos.rotation_degrees, p_rotation, 0.1)
		tween.start()
		
		if id != 2:
			tween.interpolate_property(sprite, "rotation_degrees", sprite.rotation_degrees, -p_rotation, 0.1)
			tween.start()
#		sprite.flip_h = p_flip

func attack():
	hitboxCollision.disabled = false
	tween.interpolate_property(self, "offset", offset, offset*-1, 0.2, Tween.TRANS_CIRC)
	tween.start()
#	sprite.flip_h = !sprite.flip_h
	yield(get_tree().create_timer(0.2), "timeout") 
	hitboxCollision.disabled = true

func ranged():
	Shake.shake(2.0, 0.1)

func select_item(item_id):
	rpc("changing_item", item_id)
	hitbox.damage = damage_dict[level][item_id]

func _on_level_up(type):
	level = type + 1
	sprite.material.set_shader_param("Shift_Hue", Globals.shader_dict[int(level)])
	hitbox.damage = damage_dict[level][id]

remotesync func changing_item(item_id):
	id = item_id
	sprite.frame = Globals.icon_dict[item_id]
	if sprite.frame == 2:
		sprite.rotation_degrees = 0

remotesync func sync_puppet_variables(rot_degrees):
	p_rotation = rot_degrees

func queue_free():
	smokeTrail.queue_free()
	.queue_free()
