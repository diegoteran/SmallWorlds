extends Node

var world_state = {}
var clock = 0

func _physics_process(_delta):
	
	if clock % 2 == 0:
			world_state["T"] = OS.get_system_time_msecs()
			world_state["Enemies"] = get_parent().get_node("ServerWorld").enemy_list
			get_parent().SendWorldState(world_state)
	
	clock += 1
