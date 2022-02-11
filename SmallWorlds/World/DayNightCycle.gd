extends CanvasModulate

var time = 0
var seconds = 30
var seconds_check = 30
var is_night = false

signal light_changed(value)

#func _ready():
#	if !get_tree().is_network_server():
#		rpc_id(1, "ask_if_night", get_tree().get_network_unique_id())
#
#remote func ask_if_night():
	

func _physics_process(delta):
	time += 1
	seconds += delta

	 # bug for time
	if time >= 60 and get_tree().is_network_server():
		time = 0
		seconds_check += 1
		rpc("sync_time", seconds_check, is_night)
		return
	
	set_time(seconds)

func set_time(set_seconds):
	var currentFrame = range_lerp(set_seconds, 0, 60, 0, 24)
	$AnimationPlayer.play("Cycle")
	$AnimationPlayer.seek(currentFrame)

func set_light(value: bool):
	if get_tree().is_network_server() and value != is_night:
		rpc("change_light", value)

remotesync func sync_time(seconds_check_rpc, new_is_night):
	seconds = seconds_check_rpc
	set_time(seconds)
	
	if is_night != new_is_night:
		is_night = new_is_night
		change_light(is_night)

remotesync func change_light(value: bool):
	is_night = value
	emit_signal("light_changed", value)
	
	if !is_night:
		Music.stop_ambiance_2()
		Music.play_ambiance()
	else:
		Music.stop_ambiance()
		Music.play_ambiance_2()
