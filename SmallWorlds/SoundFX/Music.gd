extends Node

export (Array, AudioStream) var music_list = []
export var boss_music : AudioStream

var music_list_index = 0

onready var musicPlayer = $AudioStreamPlayer
onready var musicBoss = $AudioStreamPlayerBoss
onready var environment = $Environment

var boss_stopped = false

func list_play():
	assert(music_list.size() > 0)
	musicPlayer.stream = music_list[music_list_index]
	musicPlayer.play()
	set_music_volume()
	music_list_index += 1
	if music_list_index == music_list.size():
		music_list_index = 0

func play_boss():
	boss_stopped = false
	list_stop()
	set_music_volume()
	musicBoss.stream = boss_music
	musicBoss.play()

func end_boss():
	boss_stopped = true
	musicBoss.stop()

func list_stop():
	musicPlayer.stop()

func _on_AudioStreamPlayer_finished():
	music_list.shuffle()
	list_play()

func set_music_volume():
	musicPlayer.volume_db = -15 +  linear2db(Globals.get_music_volume())
	musicBoss.volume_db = -15 +  linear2db(Globals.get_music_volume())
#	environment.volume_db = -15 +  linear2db(Globals.get_music_volume())


func _on_AudioStreamPlayerBoss_finished():
	if !boss_stopped:
		play_boss()
