tool
extends ViewportContainer

export var shockwave_duration := 1.0

var torus_radius := -0.25 setget _set_torus_radius

onready var tween := $Tween

func _ready():
	tween.connect("tween_all_completed", self, "_on_tween_completed")
	blast()

func blast() -> void:
	tween.interpolate_property(
		self, "torus_radius", -0.25, 2.0, shockwave_duration, Tween.TRANS_LINEAR, Tween.EASE_OUT
	)
	tween.start()


func _set_torus_radius(value: float) -> void:
	torus_radius = value
	if not is_inside_tree():
		yield(self, "ready")

	synchronize_materials("torus_radius", torus_radius)


func synchronize_materials(parameter_name: String, parameter_value) -> void:
	material.set_shader_param(parameter_name, parameter_value)

func _on_tween_completed():
	queue_free()
