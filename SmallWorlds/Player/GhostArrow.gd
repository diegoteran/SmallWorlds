extends Sprite


onready var tween = $Tween

func _ready():
	tween.interpolate_property(self, "modulate:a", 0.5, 0.0, 0.2, 3, 1)
	tween.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Tween_tween_all_completed():
	queue_free()
