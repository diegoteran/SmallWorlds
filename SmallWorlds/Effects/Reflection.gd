extends Node2D

onready var sprite = $Sprite

var copy_sprite : Sprite = null
var ignore_pos = false

func _process(delta):
	if copy_sprite == null:
		return
	
	if copy_sprite.texture != sprite.texture:
		sprite.texture = copy_sprite.texture
		sprite.vframes = copy_sprite.vframes
		sprite.hframes = copy_sprite.hframes
		
		if ignore_pos:
			sprite.position.y = copy_sprite.get_rect().size.y / 2
		else:
			sprite.position.y = - copy_sprite.position.y
#		sprite.offset.y = -copy_sprite.offset.y
	
	sprite.frame = copy_sprite.frame
	sprite.flip_h = copy_sprite.flip_h
	sprite.rotation = copy_sprite.rotation
