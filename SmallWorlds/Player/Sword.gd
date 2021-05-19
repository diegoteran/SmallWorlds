extends Node2D

var offset = 90

onready var tween = $Tween
onready var sprite = $Sprite
onready var hitbox = $HitBox/CollisionShape2D

puppet var p_rotation = 0
puppet var p_flip = false


remotesync var id

func _process(delta):
	if is_network_master():
		look_at(get_global_mouse_position())
		rotation_degrees += offset
		
		if Network.players.size() > 1:
			rset_unreliable("p_rotation", rotation_degrees)
			rset_unreliable("p_flip", sprite.flip_v)
	
	else:
		tween.interpolate_property(self, "rotation_degrees", rotation_degrees, p_rotation, 0.1)
		tween.start()
		sprite.flip_v = p_flip

func attack():
	hitbox.disabled = false
	tween.interpolate_property(self, "offset", offset, offset*-1, 0.2, Tween.TRANS_CIRC)
	tween.start()
	sprite.flip_v = !sprite.flip_v
	yield(get_tree().create_timer(0.2), "timeout") 
	hitbox.disabled = true

func select_item(item_id):
	rpc("changing_item", item_id)

remotesync func changing_item(item_id):
	sprite.frame = item_id
