extends Position2D

onready var label = $Label
onready var tween = $Tween

var amount = 0
var message = "Info text loading failed."
var type = DAMAGE
var velocity = Vector2(0, 25)
var duration = 0.2

enum {
	HEAL,
	DAMAGE,
	INFO
}


# Called when the node enters the scene tree for the first time.
func _ready():
	var side_movement = rand_range(-30, 30)
	match type:
		HEAL:
			label.text = str(amount)
			label.set("custom_colors/font_color", Color.blue)
		DAMAGE:
			label.text = str(amount)
			label.set("custom_colors/font_color", Color.red)
		INFO:
			label.text = message
			label.set("custom_colors/font_color", Color.white)
			side_movement = 0
			duration = 2
			velocity.y = 0
	velocity.x = side_movement
	tween.interpolate_property(self, 'scale', Vector2(0.7, 0.7), Vector2.ONE, duration, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.interpolate_property(self, 'scale', Vector2.ONE, Vector2.ZERO, 0.7, Tween.TRANS_LINEAR, Tween.EASE_OUT, duration + 0.1)
	tween.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position -= velocity * delta


func _on_Tween_tween_all_completed():
	queue_free()
