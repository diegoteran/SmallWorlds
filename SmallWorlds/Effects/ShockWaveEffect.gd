extends AnimatedSprite

export var shockwave_duration := 1.0

onready var timer := $Timer

func _ready():
	play("default")
	timer.start(1.0)


func _on_Timer_timeout():
	queue_free()
