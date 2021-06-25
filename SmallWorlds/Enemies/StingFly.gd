extends KinematicBody2D

export var ACCELERATION = 300
export var MAX_SPEED = 50
export var MAX_ATTACK_SPEED = 200
export var FRICTION = 200
export var TELEGRAPHING = false
export var ATTACK_RANGE = 40
export var ATTACK_COOLDOWN = 0.8

enum {
	IDLE,
	WANDER,
	CHASE,
	TELEGRAPH,
	ATTACK,
	DEAD
}

var KNOCKBACK_FRICTION = 120

var server = Network

var state = IDLE
var velocity = Vector2.ZERO
var last_direction = Vector2.ZERO
var cd = 0
var can_attack = true

remotesync var hp = 3 setget set_hp
#var stateServer

puppet var puppet_velocity = Vector2.ZERO
puppet var puppet_position = Vector2.ZERO
puppet var puppet_rotation = 0
remotesync var knockback = Vector2.ZERO
var puppetState = "Idle"

onready var playerDetectionZone = $PlayerDetectionZone
onready var animationPlayer = $AnimationPlayer
onready var shadowSprite = $ShadowSprite
onready var sprite = $Sprite
onready var hurtBox = $HurtBox
onready var hitBox = $HitBox
#onready var softCollision = $SoftCollision
#onready var wanderController = $WanderController
onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	# Reflection
	var remote_transform = Globals.create_reflection_ignore_pos(sprite, "fly"+name)
	add_child(remote_transform)


func set_hp(new_value):
	if new_value != hp:
		hp = new_value
		if hp <= 0 and state != DEAD:
			_on_death()


func _physics_process(delta):
	if get_tree().network_peer == null or get_tree().network_peer.get_connection_status() != get_tree().network_peer.CONNECTION_CONNECTED:
		return
	
	if state == DEAD:
			return
	
	if is_network_master():
		
		# Apply knockback
		knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
		knockback = move_and_slide(knockback)

		# Attack cooldown
		if cd > 0:
			cd -= delta
		else:
			can_attack = true

		# Player detection
		var player = playerDetectionZone.player
		if player == null:
			state = IDLE
			puppetState = "Idle"
		
		match state:
			IDLE:
				animationPlayer.play("Fly")
				velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
				seek_player()
#				if wanderController.get_time_left() == 0:
#					update_wander_controller()
				
#			WANDER:
#				seek_player()
#				if wanderController.get_time_left() == 0:
#					update_wander_controller()
#
#				accelerate_towards_point(wanderController.target_position, delta)
#
#				if global_position.distance_to(wanderController.target_position) <= 4:
#					update_wander_controller()
				
			CHASE:
				seek_player()
				accelerate_towards_point(player.global_position, delta)
				if global_position.distance_to(player.global_position) < ATTACK_RANGE:
					state = TELEGRAPH
					TELEGRAPHING = true
			
			TELEGRAPH:
				if can_attack:
					telegraph_attack_state(player.global_position, delta)
					if !TELEGRAPHING:
						state = ATTACK
				else:
					state = IDLE
			
			ATTACK:
				attack(delta)
		
#		if softCollision.is_colliding():
#			velocity += softCollision.get_push_vector() * delta * 400
		
		velocity = move_and_slide(velocity)
		
		rpc_unreliable("sync_puppet_variables", global_position, velocity, sprite.rotation, sprite.flip_v, sprite.flip_h)

	else:
		move_puppet_fly()

puppet func sync_puppet_variables(pos: Vector2, vel: Vector2, rot: float, f_v :bool, f_h: bool) -> void:
	puppet_position = pos
	puppet_velocity = vel
	puppet_rotation = rot
	sprite.flip_v = f_v
	sprite.flip_h = f_h

puppet func move_puppet_fly():
	global_position = puppet_position
	sprite.rotation = puppet_rotation
#	sprite.flip_h = puppet_velocity.x > 0
	
	if puppetState == "Idle":
		animationPlayer.play("Fly")

func _on_HurtBox_area_entered(area):
#	stats.health -= area.damage
	if area.is_network_master() and state != DEAD:
		var new_knockback = (global_position - area.get_parent().global_position).normalized() * KNOCKBACK_FRICTION
#		rset("knockback", new_knockback)
		var new_hp = hp - area.damage
#		rset("hp", new_hp)
#		rpc("hurt")
		rpc("hurt", new_knockback, new_hp)

remotesync func hurt(new_knockback: Vector2, new_hp: float) -> void:
	self.hp = new_hp
	hurtBox.create_hit_effect()
	if puppetState != "Attack":
		knockback = new_knockback

func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE
	else:
		state = IDLE

func accelerate_towards_point(point: Vector2, delta: float):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
	sprite.flip_h = velocity.x > 0

func telegraph_attack_state(point: Vector2, delta: float) -> void:
	if puppetState != "Attack":
		rpc("telegraph_attack")
	last_direction = global_position.direction_to(point)
	sprite.look_at(point)
#	sprite.rotation += 135 if last_direction.x < 0 else 0
	velocity = velocity.move_toward(-last_direction * MAX_SPEED, ACCELERATION * delta)
#	sprite.flip_h = last_direction.y < 0
	sprite.flip_v = last_direction.x < 0

remotesync func telegraph_attack() -> void:
	puppetState = "Attack"
	animationPlayer.play("Attack")

func attack(delta: float) -> void:
	velocity = velocity.move_toward(last_direction * MAX_ATTACK_SPEED, 10 * ACCELERATION * delta)
#	sprite.flip_h = velocity.x > 0

func attack_finished() -> void:
	puppetState = "Idle"
	sprite.flip_v = false
	can_attack = false
	cd = 1
	sprite.rotation = 0
	state = IDLE
	sprite.modulate = Color(1, 1, 1, 1)

### Sound Effects
func play_flap():
	SoundFx.play("FlyFlap", global_position, rand_range(0.8, 1.2), -30)

func play_hurt():
	SoundFx.play("FlyHurt", global_position, rand_range(0.8, 1.2), -10)

func play_attack():
	SoundFx.play("FlyAttack", global_position, rand_range(0.8, 1.2), -20)

### Death

func _on_death():
	if (get_tree().is_network_server()):
		server.NPCKilled(int(name))
		server.NPCKilled(int(name))
	
	play_hurt()
	Globals.delete_reflection("fly"+name)
	attack_finished()
	state = DEAD
	shadowSprite.queue_free()
	hitBox.set_deferred("monitorable", false)
	animationPlayer.play("Death")

func dead():
	for node in get_children():
		if !(node is Sprite or node is Timer):
			node.queue_free()
	timer.start(20)


func _on_Timer_timeout():
	queue_free()
