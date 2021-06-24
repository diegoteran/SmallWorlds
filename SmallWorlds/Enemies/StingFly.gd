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

remotesync var hp = 3 setget set_hp
#var stateServer
#var type
#
#puppet var puppet_velocity = Vector2.ZERO
#puppet var puppet_position = Vector2.ZERO
#remotesync var knockback = Vector2.ZERO

onready var playerDetectionZone = $PlayerDetectionZone
onready var sprite = $Sprite
onready var hurtBox = $HurtBox
#onready var softCollision = $SoftCollision
#onready var wanderController = $WanderController

# Called when the node enters the scene tree for the first time.
func _ready():
	# Reflection
	var remote_transform = Globals.create_reflection(sprite, "fly"+name)
	add_child(remote_transform)


func set_hp(new_value):
	if new_value != hp:
		hp = new_value
		if hp <= 0:
			_on_death()


func _physics_process(delta):
	if get_tree().network_peer == null or get_tree().network_peer.get_connection_status() != get_tree().network_peer.CONNECTION_CONNECTED:
		return
	
	if is_network_master():
#		knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
#		knockback = move_and_slide(knockback)
		
		match state:
			IDLE:
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
				var player = playerDetectionZone.player
				if player != null:
					accelerate_towards_point(player.global_position, delta)
				else:
					state = IDLE
		
#		if softCollision.is_colliding():
#			velocity += softCollision.get_push_vector() * delta * 400
		
		velocity = move_and_slide(velocity)
		
#		rpc_unreliable("sync_puppet_variables", global_position, velocity)
#
#	else:
#		MovePuppetBat()

func _on_HurtBox_area_entered(area):
#	stats.health -= area.damage
	if area.is_network_master():
		var new_knockback = (global_position - area.get_parent().global_position).normalized() * KNOCKBACK_FRICTION
#		rset("knockback", new_knockback)
		var new_hp = hp - area.damage
#		rset("hp", new_hp)
#		rpc("hurt")
		self.hp = new_hp
		hurtBox.create_hit_effect()

func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE

func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
	sprite.flip_h = velocity.x > 0

func _on_death():
	if (get_tree().is_network_server()):
		server.NPCKilled(int(name))
	
	Globals.delete_reflection("fly"+name)
	queue_free()
#	SoundFx.play("EnemyDie", global_position, rand_range(0.9, 1.1), -30)
#	play_defeated()
#	var enemyDeathEffect = EnemyDeathEffect.instance()
#	get_parent().add_child(enemyDeathEffect)
#	enemyDeathEffect.global_position = global_position
