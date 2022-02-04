extends Control

var max_rock = 10 #setget set_max_rock
var rocks = [0, 0] #setget set_rock

onready var progressBar = [$VBoxContainer/ProgressBar, $VBoxContainer/ProgressBar2]
onready var tween = $Tween

func _ready():
	max_rock = PlayerStats.max_rock
	rocks = PlayerStats.rocks
	progressBar[0].max_value = max_rock
	progressBar[1].max_value = max_rock
		
	# warning-ignore:return_value_discarded
	PlayerStats.connect("rock_changed", self, "set_rock")
#	max_soul = value

func set_rock(value : float, type: int) -> void:
	value = clamp(value, 0, max_rock)
	tween.interpolate_property(progressBar[type], "value", progressBar[type].value, value, 0.2)
	tween.start()
	rocks[type] = value
