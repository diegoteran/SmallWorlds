extends Area2D

var id

func _ready():
	set_process(false)

# has to be called before adding the node to the scenetree
func init(id):
	$AnimatedSprite.set_animation(str(id))
	self.id = id

func _process(delta):
	self.queue_free()

func _on_Item_body_entered(body):
	if body.is_network_master() and body.has_method("on_item_collected"):
		body.on_item_collected(id)
		set_process(true)
