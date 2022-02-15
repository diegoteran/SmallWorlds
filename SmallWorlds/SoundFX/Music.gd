extends Node

export (Array, AudioStream) var music_list = []
export var boss_music : AudioStream
export var day_music : AudioStream
export var night_music : AudioStream
export var menu_music : AudioStream

var music_list_index = 0

onready var musicPlayer = $AudioStreamPlayer
onready var musicBoss = $AudioStreamPlayerBoss
onready var musicAmbiance = $AudioStreamPlayerAmbiance
onready var musicAmbiance2 = $AudioStreamPlayerAmbiance2
onready var musicMenu = $AudioStreamPlayerMenu
onready var tween = $Tween

var boss_stopped = true
var ambiance_stopped = true
var ambiance_2_stopped = true

func _on_ready():
	set_music_volume()

func fade_out(stream_player, duration):
	tween.interpolate_property(stream_player, "volume_db", stream_player.volume_db, -80, duration, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()

func list_play():
	assert(music_list.size() > 0)
	musicPlayer.stream = music_list[music_list_index]
	musicPlayer.play()
	music_list_index += 1
	if music_list_index == music_list.size():
		music_list_index = 0
	
func list_stop():
	musicPlayer.stop()

func play_menu():
	musicMenu.stream = menu_music
	if musicMenu.playing:
		musicMenu.volume_db = 0
		musicMenu.stop()
	musicMenu.play()

func stop_menu():
	fade_out(musicMenu, 3)

func play_boss():
	boss_stopped = false
	musicBoss.stream = boss_music
	musicBoss.play()

func end_boss():
	boss_stopped = true
	fade_out(musicBoss, 5.0)
	

func play_ambiance():
	ambiance_stopped = false
	musicAmbiance.stream = day_music
	musicAmbiance.play()

func stop_ambiance():
	ambiance_stopped = true
	fade_out(musicAmbiance, 5)

func play_ambiance_2():
	ambiance_2_stopped = false
	musicAmbiance2.stream = night_music
	musicAmbiance2.play()

func stop_ambiance_2():
	ambiance_2_stopped = true
	fade_out(musicAmbiance2, 5)

func _on_AudioStreamPlayer_finished():
	music_list.shuffle()
	list_play()

func set_music_volume():
	musicPlayer.volume_db = 0
	musicBoss.volume_db = 0
	musicAmbiance.volume_db = 0
	musicMenu.volume_db = 0


func _on_AudioStreamPlayerBoss_finished():
	if !boss_stopped:
		play_boss()


func _on_AudioStreamPlayerAmbiance_finished():
	if !ambiance_stopped:
		play_ambiance()


func _on_AudioStreamPlayerMenu_finished():
	pass # Replace with function body.


func _on_Tween_tween_completed(object, _key):
	object.stop()
	object.volume_db = 0


func _on_AudioStreamPlayerAmbiance2_finished():
	if !ambiance_2_stopped:
		play_ambiance_2()
