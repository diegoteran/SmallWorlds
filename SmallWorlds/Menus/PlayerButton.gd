extends Control


var shader = 0
var player_name = ""

signal player_selected
signal player_deleted

onready var sprite = $Panel/VBoxContainer/HBoxContainer/CenterContainer/MarginContainer/AnimatedSprite
onready var nameLabel = $Panel/VBoxContainer/HBoxContainer/VBoxContainer/MarginContainer/PlayerName
# Called when the node enters the scene tree for the first time.
func _ready():
	sprite.material.set_shader_param("Shift_Hue", shader)
	nameLabel.text = player_name
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_SelectButton_pressed():
	emit_signal("player_selected")


func _on_DeleteButton_pressed():
	emit_signal("player_deleted")


func _on_SelectButton_mouse_entered():
	sprite.play()


func _on_SelectButton_mouse_exited():
	sprite.stop()
	sprite.frame = 0
