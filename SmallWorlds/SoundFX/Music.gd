extends Node

export (Array, AudioStream) var music_list = []

var music_list_index = 0

onready var musicPlayer = $AudioStreamPlayer
onready var environment = $Environment

func list_play():
	assert(music_list.size() > 0)
	musicPlayer.stream = music_list[music_list_index]
	musicPlayer.play()
	musicPlayer.volume_db = -15
	music_list_index += 1
	if music_list_index == music_list.size():
		music_list_index = 0

func list_stop():
	musicPlayer.stop()

func _on_AudioStreamPlayer_finished():
	music_list.shuffle()
	list_play()
