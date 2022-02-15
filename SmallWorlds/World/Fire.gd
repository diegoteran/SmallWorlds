extends StaticBody2D

export var FloatingText : PackedScene

onready var tween = $Tween
onready var light1 = $light1
onready var light2 = $light2
onready var sprite = $Sprite
onready var audio = $AudioStreamPlayer2D

export var mouse_in_fire = false

func _ready():
	Globals.create_reflection_static(sprite, "fire" + name, global_position)
	# Light Handler
	var cycle = get_node("/root/World/DayNightCycle")
	cycle.connect("light_changed", self, "set_lights")
	if cycle.is_night:
		set_lights(true)

func _input(_event):
	if Input.is_action_just_pressed("ranged") and mouse_in_fire:
		print("clicked fire")
		SoundFx.play_menu("Menu Move", rand_range(0.8, 1.2), - 20)
		Shake.shake(1, 0.5, 0)
		SaverAndLoader.custom_data_player.spawn_enabled = true
		SaverAndLoader.custom_data_player.spawn = global_position
		SaverAndLoader.save_player()
		
		var text = Globals.instance_scene_on_node(FloatingText, get_parent(), global_position + Vector2(0, -20))
		text.type = text.INFO
		text.message = "New spawn point set."

func set_lights(value: bool):
	if value:
		tween.interpolate_property(light1, "energy", light1.energy, 0.8, 5.0)
		tween.interpolate_property(light2, "energy", light2.energy, 0.8, 5.0)
	else:
		tween.interpolate_property(light1, "energy", light1.energy, 0.0, 5.0)
		tween.interpolate_property(light2, "energy", light2.energy, 0.0, 5.0)
	
	tween.start()


func _on_Fire_mouse_entered():
	sprite.material.set_shader_param('color', Color.white)
	mouse_in_fire = true


func _on_Fire_mouse_exited():
	sprite.material.set_shader_param('color', Color.transparent)
	mouse_in_fire = false


func _on_AudioStreamPlayer2D_finished():
	audio.play()

func queue_free():
	Globals.delete_reflection("fire" + name)
