extends KinematicBody2D

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

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

remotesync var hp = 5 setget set_hp
var stateServer
var type

puppet var puppet_velocity = Vector2.ZERO
puppet var puppet_position = Vector2.ZERO
remotesync var knockback = Vector2.ZERO

onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var sprite = $AnimatedSprite
onready var hurtBox = $HurtBox
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController

func _ready():
	stats.connect("no_health", self, "_on_Stats_no_health")
	if stateServer == "Idle":
		state = IDLE
	else:
		OnDeath()

func set_hp(new_value):
	if new_value != hp:
		hp = new_value
		if hp <= 0:
			OnDeath()

func _physics_process(delta):
	if is_network_master():
		knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
		knockback = move_and_slide(knockback)
		
		match state:
			IDLE:
				velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
				seek_player()
				if wanderController.get_time_left() == 0:
					update_wander_controller()
				
			WANDER:
				seek_player()
				if wanderController.get_time_left() == 0:
					update_wander_controller()
				
				accelerate_towards_point(wanderController.target_position, delta)
				
				if global_position.distance_to(wanderController.target_position) <= 4:
					update_wander_controller()
				
			CHASE:
				var player = playerDetectionZone.player
				if player != null:
					accelerate_towards_point(player.global_position, delta)
				else:
					state = IDLE
		
		if softCollision.is_colliding():
			velocity += softCollision.get_push_vector() * delta * 400
		velocity = move_and_slide(velocity)
		
		rset("puppet_position", global_position)
		rset("puppet_velocity", velocity)
	
	else:
		MovePuppetBat()

func MovePuppetBat():
	global_position = puppet_position
	sprite.flip_h = puppet_velocity.x > 0

func update_wander_controller():
	state = pick_random_state([IDLE, WANDER])
	wanderController.start_wander_timer(rand_range(1, 3))

func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func play_flap():
	SoundFx.play("BatFlap", global_position, rand_range(1.5, 2), -35)

func play_hurt():
	SoundFx.play("BatHurt", global_position, rand_range(0.8, 1.2), -30)

func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
	sprite.flip_h = velocity.x < 0

func _on_HurtBox_area_entered(area):
#	stats.health -= area.damage
	if area.is_network_master():
		var new_knockback = (global_position - area.get_parent().global_position).normalized() * KNOCKBACK_FRICTION
		rset("knockback", new_knockback)
		var new_hp = hp - area.damage
		rset("hp", new_hp)
		rpc("hurt")

remotesync func hurt():
	hurtBox.create_hit_effect()
	play_hurt()

func _on_Stats_no_health():
	queue_free()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position

func OnDeath():
	if (get_tree().is_network_server()):
		server.NPCKilled(int(name))
	
	queue_free()
	SoundFx.play("EnemyDie", global_position, rand_range(0.9, 1.1), -30)
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position
	
func Health(health):
	if health != hp:
		hp = health
		if hp <= 0:
			OnDeath()



func _on_AnimatedSprite_frame_changed():
	if sprite.frame == 2:
		play_flap()
