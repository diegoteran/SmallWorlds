extends KinematicBody2D

export var ACCELERATION = 300
export var MAX_SPEED = 50
export var FRICTION = 200

enum {
	IDLE,
	WANDER,
	CHASE
}

var KNOCKBACK_FRICTION = 120

var server = Network

var state = IDLE
var velocity = Vector2.ZERO

var hp = 5 setget set_hp
var knockback = Vector2.ZERO
var stateServer = "Idle"

puppet var puppet_velocity = Vector2.ZERO
puppet var puppet_position = Vector2.ZERO

onready var playerDetectionZone = $PlayerDetectionZone
onready var sprite = $Sprite
onready var hurtBox = $HurtBox
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController

func _ready():
	if stateServer == "Idle":
		state = IDLE
	else:
		_on_death()
	
	hurtBox.connect("area_entered", self, "_on_HurtBox_area_entered")

func set_hp(new_value):
	if new_value != hp:
		hp = new_value
		if hp <= 0:
			_on_death()

func update_wander_controller():
	state = pick_random_state([IDLE, WANDER])
	wanderController.start_wander_timer(rand_range(1, 3))

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE

func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
	sprite.flip_h = velocity.x < 0

func _on_HurtBox_area_entered(area) -> void:
#	stats.health -= area.damage
	if area.is_network_master():
		var new_knockback = (global_position - area.get_parent().global_position).normalized() * KNOCKBACK_FRICTION
		var new_hp = hp - area.damage
		rpc("hurt", new_knockback, new_hp)

func _on_death():
	pass
	
func Health(health):
	if health != hp:
		hp = health
		if hp <= 0:
			_on_death()
