extends Area2D

var id = 0

onready var sprite = $Sprite
onready var shadowSprite = $Sprite2
onready var animationPlayer = $AnimationPlayer
onready var tween = $Tween

const MIN_X =  40.0
const MAX_X = 80.0
const MIN_Y = -60.0
const MAX_Y =  60.0

func _ready():
	var remote_transform = Globals.create_reflection(sprite, name)
	$Position2D.add_child(remote_transform)
	animationPlayer.play("anim")
	
	var starting_y = sprite.position.y
	
	var direction = 1 if randi() % 2 == 0 else -1
	var goal = global_position + Vector2(rand_range(MIN_X, MAX_X), rand_range(MIN_Y, MAX_Y)) * direction

	tween.interpolate_property(self, "global_position:x", null, goal.x, 1.6, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.interpolate_property(self, "global_position:y", null, goal.y, 1.6, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.interpolate_property(sprite, "position:y", null, starting_y - 20, 0.4, Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.interpolate_property(sprite, "position:y", starting_y - 20, starting_y, 0.4, Tween.TRANS_QUAD, Tween.EASE_IN, 0.4)
	tween.interpolate_property(sprite, "position:y", starting_y, starting_y - 15, 0.3, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.8)
	tween.interpolate_property(sprite, "position:y", starting_y - 15, starting_y, 0.3, Tween.TRANS_QUAD, Tween.EASE_IN, 1.1)
	tween.interpolate_property(sprite, "position:y", starting_y, starting_y - 5, 0.1, Tween.TRANS_QUAD, Tween.EASE_OUT, 1.4)
	tween.interpolate_property(sprite, "position:y", starting_y - 5, starting_y, 0.1, Tween.TRANS_QUAD, Tween.EASE_IN, 1.5)

	tween.start()

## has to be called before adding the node to the scenetree
func init(id, unique_name):
	self.id = id
	name = "itemFrom" + unique_name

#func _process(_delta):
#	self.queue_free()

func _on_Item_body_entered(body):
	print("touched")
	if body.is_network_master() and body.has_method("on_item_collected"):
		body.on_item_collected(id)
		queue_free()

func queue_free():
	Globals.delete_reflection(name)
