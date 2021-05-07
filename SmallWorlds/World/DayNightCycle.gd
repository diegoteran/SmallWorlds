extends CanvasModulate

var time = 0
var seconds = 0
var seconds_check = 0

func _physics_process(delta):
	time += 1
	seconds += delta
	
	if time >= 60:
		time = 0
		seconds_check += 1
		seconds = seconds_check

	var currentFrame = range_lerp(seconds, 0, 48, 0, 24)
	$AnimationPlayer.play("Cycle")
	$AnimationPlayer.seek(currentFrame)
