extends Node

var sounds_path = "res://SoundFX/Sounds/"

var sounds = {
	"BatDefeated" : load(sounds_path + "BatDefeated.wav"),
	"BatFlap" : load(sounds_path + "BatFlap.wav"),
	"BatHurt1" : load(sounds_path + "BatHurt1.wav"),
	"BatHurt2" : load(sounds_path + "BatHurt2.wav"),
	"Click" : load(sounds_path + "Click.wav"),
	"EnemyDie" : load(sounds_path + "EnemyDie.wav"),
	"Evade" : load(sounds_path + "Evade.wav"),
	"FlyAttack" : load(sounds_path + "FlyAttack.wav"),
	"FlyFlap" : load(sounds_path + "FlyFlap.wav"),
	"FlyHurt" : load(sounds_path + "FlyHurt.wav"),
	"Hit" : load(sounds_path + "Hit.wav"),
	"Hurt" : load(sounds_path + "Hurt.wav"),
	"Jump" : load(sounds_path + "Jump.wav"),
	"Menu Move" : load(sounds_path + "Menu Move.wav"),
	"Menu Select" : load(sounds_path + "Menu Select.wav"),
	"Pause" : load(sounds_path + "Pause.wav"),
	"Step" : load(sounds_path + "Step.wav"),
	"StepDirt" : load(sounds_path + "StepDirt.wav"),
	"StepWater" : load(sounds_path + "StepWater.wav"),
	"Swipe" : load(sounds_path + "Swipe.wav"),
	"SwordHit" : load(sounds_path + "SwordHit.wav"),
	"Unpause" : load(sounds_path + "Unpause.wav"),
}

onready var sound_players = get_node("2D").get_children()
onready var sound_players_menu = get_node("Menu").get_children()

func play(sound_string, from_location, pitch_scale = 1, volume_db = 0):
	for soundPlayer in sound_players:
		if not soundPlayer.playing:
			soundPlayer.attenuation = 10
			soundPlayer.pitch_scale = pitch_scale
			soundPlayer.volume_db = volume_db + linear2db(Globals.get_sfx_volume())
			soundPlayer.stream = sounds[sound_string]
			soundPlayer.global_position = from_location
			soundPlayer.play()
			return
	print("Too many sounds playing at once.")
#	var new_sp = AudioStreamPlayer2D.new()
#	get_node("2D").add_child(new_sp)
#	sound_players.append(new_sp)
#	new_sp.attenuation = 10
#	new_sp.pitch_scale = pitch_scale
#	new_sp.volume_db = volume_db + linear2db(Globals.get_sfx_volume())
#	new_sp.stream = sounds[sound_string]
#	new_sp.global_position = from_location
#	new_sp.play()

func play_menu(sound_string, pitch_scale = 1, volume_db = 0):
	for soundPlayer in sound_players_menu:
		if not soundPlayer.playing:
			soundPlayer.pitch_scale = pitch_scale
			soundPlayer.volume_db = volume_db + linear2db(Globals.get_sfx_volume())
			soundPlayer.stream = sounds[sound_string]
			soundPlayer.play()
			return
	print("Too many sounds playing for menu at once.")
