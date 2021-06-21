extends Line2D

export var limited_lifetime = false
export var wildness = 3.0
export var min_spawn_distance = 5.0
export var gravity = Vector2.ZERO
export var gradient_col : Gradient = Gradient.new()

var lifetime = [1.0, 2.0]
var tick_speed = 0.05
var tick = 0.0
var wild_speed = 0.1
var point_age = [0.0]

onready var tween = $DecayTween

func _ready():
	gradient = gradient_col
	clear_points()
	if limited_lifetime:
		tween.interpolate_property(self, "modulate:a", 1.0, 0.0, rand_range(lifetime[0], lifetime[1]), Tween.TRANS_CIRC, Tween.EASE_OUT)

func _process(delta):
	if tick > tick_speed:
		for p in range(get_point_count()):
			point_age[p] += tick
			var rand_vector = Vector2(rand_range(-wild_speed, wild_speed), rand_range(-wild_speed, wild_speed))
			points[p] += gravity + (rand_vector * wildness * point_age[p])
		
		for p in range(get_point_count(), -1, -1):
			if point_age[p] > 1:
				remove_point(p)
				point_age.remove(p)
		
		tick = 0
	
	else:
		tick += delta

func add_point(point_pos:Vector2, at_pos := -1):
	point_pos = point_pos - global_position
	if get_point_count() > 0 and point_pos.distance_to(points[get_point_count() - 1]) < min_spawn_distance:
		return
	
	point_age.append(0.0)
	.add_point(point_pos, at_pos)

func _on_DecayTween_tween_all_completed():
	queue_free()
