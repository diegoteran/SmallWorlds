extends Control

var hearts = 4 setget set_hearts
var max_hearts = 4 setget set_max_hearts

export var Heart: PackedScene # = preload("res://UI/Heart.tscn")

onready var heartsUI = $Hearts
onready var label = $Hearts/CenterContainer/Label

func _process(_delta):
	label.text = str(Engine.get_frames_per_second())

func set_hearts(value):
	value = clamp(value, 0, max_hearts)
	if value < hearts:
		for i in range(hearts, value, -1):
			heartsUI.get_node(str(i-1)+"/Heart").damaged()
	if value > hearts:
		for i in range(hearts, value):
			heartsUI.get_node(str(i)+"/Heart").regened()
	hearts = value
#	if heartUIFull != null:
#		heartUIFull.rect_size.x = hearts * 15

func set_max_hearts(value):
	value = max(value, 1)
	if value < max_hearts:
		for i in range(max_hearts, value, -1):
			heartsUI.get_node(str(i-1)+"/Heart").queue_free()
	if value > max_hearts:
		for i in range(max_hearts, value):
			create_heart_with_id(i)
	max_hearts = value
	self.hearts = min(hearts, max_hearts)
#	if heartUIEmpty != null:
#		heartUIEmpty.rect_size.x = max_hearts * 15

func _ready():
	for i in PlayerStats.max_health:
		create_heart_with_id(i)
	
	max_hearts = PlayerStats.max_health
	hearts = PlayerStats.health
	for i in range(hearts):
		heartsUI.get_node(str(i)+"/Heart").regened()
	
		
	# warning-ignore:return_value_discarded
	PlayerStats.connect("health_changed", self, "set_hearts")
	# warning-ignore:return_value_discarded
	PlayerStats.connect("max_health_changed", self, "set_max_hearts")

func create_heart_with_id(id):
	var container = CenterContainer.new()
	var heart = Heart.instance()
	heart.get_node("Sprite").scale = Vector2(0.5, 0.5)
	container.add_child(heart)
	container.rect_min_size = Vector2(16, 16)
	container.name = str(id)
	heartsUI.add_child(container)
