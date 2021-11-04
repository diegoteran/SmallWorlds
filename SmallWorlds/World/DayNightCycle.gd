extends CanvasModulate

var time = 0
var seconds = 30
var seconds_check = 30
var current_light

signal light_changed(value)

func _physics_process(delta):
	time += 1
	seconds += delta

	 # bug for time
	if time >= 60 and get_tree().is_network_server():
		time = 0
		seconds_check += 1
		rpc("sync_time", seconds_check)
		return
	
	set_time(seconds)

func set_time(set_seconds):
	var currentFrame = range_lerp(set_seconds, 0, 60, 0, 24)
	$AnimationPlayer.play("Cycle")
	$AnimationPlayer.seek(currentFrame)

func set_light(value: bool):
	print(" set light")
	if get_tree().is_network_server():
		rpc("change_light", value)

remotesync func sync_time(seconds_check_rpc):
	seconds = seconds_check_rpc
	set_time(seconds)

remotesync func change_light(value: bool):
	print("change light")
	emit_signal("light_changed", value)
