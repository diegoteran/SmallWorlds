extends KinematicBody2D

export var ACCELERATION = 300
export var MAX_SPEED = 50
export var NIGHT_SPEED = 80
export var FRICTION = 200
export var KNOCKBACK_FRICTION = 150
export var hp = 5 setget set_hp
var soul_given = 1

enum {
	IDLE,
	WANDER,
	CHASE,
	TELEGRAPH,
	ATTACK,
	DEAD
}

export var ParticleEffect: PackedScene

var server = Network

var state = IDLE
var velocity = Vector2.ZERO
var knockback = Vector2.ZERO
var stateServer = "Idle"
var high_damage = 0
var damage = 0
var is_night = false
var is_enraged = false
var safe_areas = []
var subscribed = []
var tick = false

puppet var puppet_velocity = Vector2.ZERO
puppet var puppet_position = Vector2.ZERO

onready var animationPlayer = $AnimationPlayer
onready var shadowSprite = $ShadowSprite
onready var sprite = $Sprite
onready var hurtBox = $HurtBox
onready var hitBox = $HitBox
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController
onready var playerDetectionZone = $PlayerDetectionZone
onready var timer = $Timer
onready var proximityTimer = $ProximityTimer
onready var particles = $Particles2D
onready var rpcTimer = $RPCTimer

func _ready():
	if stateServer == "Idle":
		state = IDLE
	else:
		_on_death()
	
	damage = hitBox.damage
	high_damage = damage + 1
	
	hurtBox.connect("area_entered", self, "_on_HurtBox_area_entered")
	
	if is_network_master():
		proximityTimer.start(5)
	else:
		rpcTimer.start(1)
	
	# Light Handler
	var cycle = get_node("/root/World/DayNightCycle")
	cycle.connect("light_changed", self, "set_lights")
	if cycle.is_night:
		set_lights(true)

remote func subscribe(new_id):
	subscribed.append(new_id)

func _physics_process(_delta):
	if state == DEAD:
		return

	if is_night and safe_areas.size() == 0:
		if !is_enraged:
			set_enraged_stats(true)
	elif is_enraged:
		set_enraged_stats(false)

func set_hp(new_value):
	if new_value != hp:
		hp = new_value
		if hp <= 0:
			_on_death()

func set_lights(value: bool):
	if state != DEAD:
		is_night = value

func set_enraged_stats(value: bool):
	is_enraged = value
	particles.emitting = is_enraged
	if is_enraged:
		hitBox.damage = high_damage
	else:
		hitBox.damage = damage

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
	velocity = velocity.move_toward(direction * (NIGHT_SPEED if is_enraged else MAX_SPEED), ACCELERATION * delta)
	sprite.flip_h = velocity.x < 0

func _on_HurtBox_area_entered(area) -> void:
#	stats.health -= area.damage
	if area.is_network_master() and state != DEAD:
		if "Arrow" in area.get_parent().name:
			area.get_parent().delete()
		else:
			area.get_parent().get_parent().get_parent().get_parent().add_soul(soul_given)
		var new_knockback = (global_position - area.get_parent().global_position).normalized() * KNOCKBACK_FRICTION
		var new_hp = hp - area.damage
		Shake.shake(0.8, 0.3, 2)
		rpc("hurt", new_knockback, new_hp)
		rpc("hurt_effect", (global_position - area.get_parent().global_position).normalized())

remotesync func hurt_effect(direction: Vector2):
	var particleEffect = ParticleEffect.instance()
	particleEffect.set_particles_color(Color.mediumpurple)
	get_parent().add_child(particleEffect)
	particleEffect.global_position = global_position + direction * 5
	particleEffect.look_at(particleEffect.global_position + Vector2(-direction.y, direction.x))

func _on_death():
	pass

func play_hit_sound():
	SoundFx.play("SwordHit", global_position, rand_range(0.9, 1.1), -20)
	
func Health(health):
	if health != hp:
		hp = health
		if hp <= 0:
			_on_death()

func _on_ProximityTimer_timeout():
	var player_positions = Globals.get_player_positions()
	
	for pos in player_positions:
		if global_position.distance_to(pos) < Globals.ENEMY_DISTANCE_TO_PLAYERS[0] * 2:
			proximityTimer.start(5)
			return
	
	state = DEAD
	Network.NPCKilled(int(name))
	rpc("despawn")

remotesync func despawn():
	delete_reflection()
	print("despawning enemy " + str(name))
	queue_free()

func delete_reflection():
	pass


func _on_RPCTimer_timeout():
	rpc_id(1, "subscribe", get_tree().get_network_unique_id())
