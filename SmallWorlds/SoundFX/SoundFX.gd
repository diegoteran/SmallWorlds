extends Node

var sounds_path = "res://SoundFX/Sounds/"

var sounds = {
	"BatFlap" : load(sounds_path + "BatFlap.wav"),
	"BatHurt" : load(sounds_path + "BatHurt.wav"),
	"Click" : load(sounds_path + "Click.wav"),
	"EnemyDie" : load(sounds_path + "EnemyDie.wav"),
	"Evade" : load(sounds_path + "Evade.wav"),
	"Hit" : load(sounds_path + "Hit.wav"),
	"Hurt" : load(sounds_path + "Hurt.wav"),
	"Jump" : load(sounds_path + "Jump.wav"),
	"Menu Move" : load(sounds_path + "Menu Move.wav"),
	"Menu Select" : load(sounds_path + "Menu Select.wav"),
	"Pause" : load(sounds_path + "Pause.wav"),
	"Step" : load(sounds_path + "Step.wav"),
	"Swipe" : load(sounds_path + "Swipe.wav"),
	"Unpause" : load(sounds_path + "Unpause.wav"),
}

onready var sound_players = get_node("2D").get_children()
onready var sound_players_menu = get_node("Menu").get_children()

func play(sound_string, from_location, pitch_scale = 1, volume_db = 0):
	for soundPlayer in sound_players:
		if not soundPlayer.playing:
			soundPlayer.attenuation = 10
			soundPlayer.pitch_scale = pitch_scale
			soundPlayer.volume_db = volume_db
			soundPlayer.stream = sounds[sound_string]
			soundPlayer.global_position = from_location
			soundPlayer.play()
			return
	print("Too many sounds playing at once.")

func play_menu(sound_string, pitch_scale = 1, volume_db = 0):
	for soundPlayer in sound_players_menu:
		if not soundPlayer.playing:
			soundPlayer.pitch_scale = pitch_scale
			soundPlayer.volume_db = volume_db
			soundPlayer.stream = sounds[sound_string]
			soundPlayer.play()
			return
	print("Too many sounds playing for menu at once.")
