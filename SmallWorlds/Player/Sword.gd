extends Node2D

var offset = 90
var smoketrail : Object = null
var trail_name
var smokeTrail
#var sword_dict = {"Starting": {}}
var damage_dict = {0:1, 1: 0.5, 2:0.3}

export var SmokeTrail : PackedScene

onready var tween = $Tween
onready var pos = $P
onready var swordEnd = $P/P
onready var sprite = $P/Sprite
onready var hitboxCollision = $P/HitBox/CollisionShape2D
onready var hitbox = $P/HitBox

puppet var p_rotation = 0
#puppet var p_flip = false

remotesync var id

func _ready():
	trail_name = get_parent().get_parent().name + "_trail"
	smokeTrail = Globals.instance_scene_on_world_with_name(SmokeTrail, Vector2.ZERO, trail_name)

func _process(_delta):
	smokeTrail.global_position = global_position
	smokeTrail.add_point(swordEnd.global_position)
	
	if is_network_master():
		pos.look_at(get_global_mouse_position())
		pos.rotation_degrees += offset
		
		if Network.players.size() > 1:
			rpc_unreliable("sync_puppet_variables", pos.rotation_degrees)
#			rset_unreliable("p_flip", sprite.flip_h)
	
	else:
		tween.interpolate_property(pos, "rotation_degrees", pos.rotation_degrees, p_rotation, 0.1)
		tween.start()
#		sprite.flip_h = p_flip

func attack():
	hitboxCollision.disabled = false
	tween.interpolate_property(self, "offset", offset, offset*-1, 0.2, Tween.TRANS_CIRC)
	tween.start()
#	sprite.flip_h = !sprite.flip_h
	yield(get_tree().create_timer(0.2), "timeout") 
	hitboxCollision.disabled = true

func select_item(item_id):
	rpc("changing_item", Globals.icon_dict[item_id])
	hitbox.damage = damage_dict[item_id]

remotesync func changing_item(item_id):
	sprite.frame = item_id

remotesync func sync_puppet_variables(rot_degrees):
	p_rotation = rot_degrees

func queue_free():
	smokeTrail.queue_free()
	.queue_free()
