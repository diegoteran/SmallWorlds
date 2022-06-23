extends StaticBody2D

export var BossScene: PackedScene

onready var interactionArea =  $InteractionArea

var players = {}
var players_sound = {}
var num_boss = 0


func _on_InteractionArea_body_entered(body):
	players[body.name] = body
	body.connect("healed", self, "spawn_boss")

func _on_InteractionArea_body_exited(body):
	players.erase(body.name)
	body.disconnect("healed", self, "spawn_boss")

func spawn_boss():
	rpc("all_spawn")

remotesync func all_spawn():
	SoundFx.play("MonolithActivation", global_position)
	var enemies = get_node("/root/World/YSort/Enemies")
	Globals.instance_scene_on_node_with_name(BossScene, enemies, global_position + Vector2(100, -100), "Boss" + str(num_boss))
	num_boss += 1


func _on_SoundArea_body_entered(body):
	SoundFx.play("Monolith", global_position)
	players_sound[body.name] = body


func _on_SoundArea_body_exited(body):
	players_sound.erase(body.name)
