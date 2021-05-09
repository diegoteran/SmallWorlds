extends Node

var music = 100
var sfx = 100

func get_music_volume():
	return Settings._settings["audio"]["music"]

func get_sfx_volume():
	return Settings._settings["audio"]["sfx"]

func instance_scene_on_main(scene, position):
	var main = get_tree().current_scene
	var instance = scene.instance()
	main.call_deferred("add_child", instance)
	instance.global_position = position
	return instance
