extends Control

var max_rock = 10 #setget set_max_rock
var rock = 0 setget set_rock

onready var progressBar = $ProgressBar
onready var tween = $Tween

func _ready():
	max_rock = PlayerStats.max_rock
	rock = PlayerStats.rock
	progressBar.max_value = max_rock
		
	# warning-ignore:return_value_discarded
	PlayerStats.connect("rock_changed", self, "set_rock")
	# warning-ignore:return_value_discarded
#	PlayerStats.connect("max_soul_changed", self, "set_max_soul")

#func set_max_soul(value : float) -> void:
#	value = max(5, value)
#	tween.interpolate_property(progressBar, "max_value", progressBar.max_value, value, 0.2)
#	tween.start()
#	max_soul = value

func set_rock(value : float) -> void:
	value = clamp(value, 0, max_rock)
	tween.interpolate_property(progressBar, "value", progressBar.value, value, 0.2)
	tween.start()
	rock = value
