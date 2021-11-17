extends StaticBody2D

onready var tween = $Tween
onready var light1 = $light1
onready var light2 = $light2

func _ready():
		# Light Handler
# warning-ignore:return_value_discarded
	get_node("/root/World/DayNightCycle").connect("light_changed", self, "set_lights")

func set_lights(value: bool):
	if value:
		tween.interpolate_property(light1, "energy", light1.energy, 0.8, 1.0)
		tween.interpolate_property(light2, "energy", light2.energy, 0.8, 1.0)
	else:
		tween.interpolate_property(light1, "energy", light1.energy, 0.0, 1.0)
		tween.interpolate_property(light2, "energy", light2.energy, 0.0, 1.0)
	
	tween.start()
