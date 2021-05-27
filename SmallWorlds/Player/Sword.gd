extends Node2D

var offset = 90

onready var tween = $Tween
onready var pos = $P
onready var swordEnd = $P/P
onready var sprite = $P/Sprite
onready var hitbox = $P/HitBox/CollisionShape2D
onready var smokeTrail = $SmokeTrail

puppet var p_rotation = 0
#puppet var p_flip = false

remotesync var id

func _process(delta):
	smokeTrail.add_point(swordEnd.global_position)
	
	if is_network_master():
		pos.look_at(get_global_mouse_position())
		pos.rotation_degrees += offset
		
		if Network.players.size() > 1:
			rset_unreliable("p_rotation", pos.rotation_degrees)
#			rset_unreliable("p_flip", sprite.flip_h)
	
	else:
		tween.interpolate_property(pos, "rotation_degrees", pos.rotation_degrees, p_rotation, 0.1)
		tween.start()
#		sprite.flip_h = p_flip

func attack():
	hitbox.disabled = false
	tween.interpolate_property(self, "offset", offset, offset*-1, 0.2, Tween.TRANS_CIRC)
	tween.start()
#	sprite.flip_h = !sprite.flip_h
	yield(get_tree().create_timer(0.2), "timeout") 
	hitbox.disabled = true

func select_item(item_id):
	rpc("changing_item", item_id)

remotesync func changing_item(item_id):
	sprite.frame = item_id
