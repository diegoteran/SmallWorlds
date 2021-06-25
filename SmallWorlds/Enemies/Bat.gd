extends KinematicBody2D

export var EnemyDeathEffect:PackedScene # = preload("res://Effects/EnemyDeathEffect.tscn")

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
var type

puppet var puppet_velocity = Vector2.ZERO
puppet var puppet_position = Vector2.ZERO

onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var sprite = $Sprite
onready var hurtBox = $HurtBox
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController

func _ready():
	stats.connect("no_health", self, "_on_Stats_no_health")
	if stateServer == "Idle":
		state = IDLE
	else:
		OnDeath()
	
	# Reflection
	var remote_transform = Globals.create_reflection(sprite, "bat"+name)
	add_child(remote_transform)

func set_hp(new_value):
	if new_value != hp:
		hp = new_value
		if hp <= 0:
			OnDeath()

func _physics_process(delta):
	if get_tree().network_peer == null or get_tree().network_peer.get_connection_status() != get_tree().network_peer.CONNECTION_CONNECTED:
		return
	
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
		
		rpc_unreliable("sync_puppet_variables", global_position, velocity)
	
	else:
		MovePuppetBat()

func MovePuppetBat():
	global_position = puppet_position
	sprite.flip_h = puppet_velocity.x < 0

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
	SoundFx.play("BatFlap", global_position, rand_range(1.5, 2), -30)

func play_hurt():
	var num = (randi() % 2) + 1
	SoundFx.play("BatHurt" + str(num), global_position, rand_range(0.8, 1.2), -30)

func play_defeated():
	SoundFx.play("BatDefeated", global_position, rand_range(0.8, 1.2), -30)

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

remotesync func hurt(new_knockback: Vector2, new_hp: float) -> void:
	self.hp = new_hp
	knockback = new_knockback
	hurtBox.create_hit_effect()
	play_hurt()

puppet func sync_puppet_variables(pos: Vector2, vel: Vector2) -> void:
	puppet_position = pos
	puppet_velocity = vel

func _on_Stats_no_health():
	queue_free()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position

func OnDeath():
	if (get_tree().is_network_server()):
		server.NPCKilled(int(name))
	
	Globals.delete_reflection("bat"+name)
	queue_free()
#	SoundFx.play("EnemyDie", global_position, rand_range(0.9, 1.1), -30)
	play_defeated()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position
	
func Health(health):
	if health != hp:
		hp = health
		if hp <= 0:
			OnDeath()
