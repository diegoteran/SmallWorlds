extends Control

export var Soul : PackedScene

var max_soul = 10 setget set_max_soul
var soul = 0 setget set_soul

onready var progressBar = $ProgressBar
onready var tween = $Tween
onready var soulsUI = $Souls

func _ready():
	max_soul = PlayerStats.max_soul
	soul = PlayerStats.soul
	
	for i in max_soul:
		create_soul_with_id(i)
	for i in range(soul):
		soulsUI.get_node(str(i)+"/Soul").gain_soul()
		
	# warning-ignore:return_value_discarded
	PlayerStats.connect("soul_changed", self, "set_soul")
	# warning-ignore:return_value_discarded
	PlayerStats.connect("max_soul_changed", self, "set_max_soul")

func set_max_soul(value : float) -> void:
	value = max(5, value)
	tween.interpolate_property(progressBar, "max_value", progressBar.max_value, value, 0.2)
	tween.start()
	
	if value < max_soul:
		for i in range(max_soul, value, -1):
			soulsUI.get_node(str(i-1)+"/Soul").queue_free()
	if value > max_soul:
		for i in range(max_soul, value):
			create_soul_with_id(i)
	
	max_soul = value

func set_soul(value : float) -> void:
	value = clamp(value, 0, max_soul)
	tween.interpolate_property(progressBar, "value", progressBar.value, value, 0.2)
	tween.start()
	
	if value < soul:
		for i in range(soul, value, -1):
			soulsUI.get_node(str(i-1)+"/Soul").lose_soul()
	if value > soul:
		for i in range(soul, value):
			soulsUI.get_node(str(i)+"/Soul").gain_soul()
	
	soul = value

func create_soul_with_id(id):
	var container = CenterContainer.new()
	var soul_c = Soul.instance()
	soul_c.get_node("Sprite").scale = Vector2(0.5, 0.5)
	container.add_child(soul_c)
	container.rect_min_size = Vector2(16, 16)
	container.name = str(id)
	soulsUI.add_child(container)
