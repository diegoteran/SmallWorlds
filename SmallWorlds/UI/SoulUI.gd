extends Control

var max_soul = 10 setget set_max_soul
var soul = 0 setget set_soul

onready var progressBar = $ProgressBar
onready var tween = $Tween

func _ready():
	max_soul = PlayerStats.max_soul
	soul = PlayerStats.soul
		
	# warning-ignore:return_value_discarded
	PlayerStats.connect("soul_changed", self, "set_soul")
	# warning-ignore:return_value_discarded
	PlayerStats.connect("max_soul_changed", self, "set_max_soul")

func set_max_soul(value : float) -> void:
	value = max(5, value)
	tween.interpolate_property(progressBar, "max_value", progressBar.max_value, value, 0.2)
	tween.start()
	max_soul = value

func set_soul(value : float) -> void:
	value = clamp(value, 0, max_soul)
	tween.interpolate_property(progressBar, "value", progressBar.value, value, 0.2)
	tween.start()
	soul = value
