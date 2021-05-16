extends KinematicBody2D

export var ACCELERATION = 500
export var MAX_SPEED = 100
export var ROLL_SPEED = 150
export var FRICTION = 1000

enum {
	MOVE,
	ROLL,
	ATTACK,
	DEAD,
	PAUSED
}

var state = MOVE
var velocity = Vector2.ZERO
var roll_vector = Vector2.LEFT
var stats = PlayerStats
var server = Network
var player_state = {}
var animation_vector = Vector2()
var paused = false

# Tilemap experiment
var grass_tilemap
var dirt_tilemap

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var hurtBox = $HurtBox
onready var swordHitBox = $HitBoxPivot/SwordHitBox
onready var tween = $Tween
onready var label = $Label

var puppetState = "Idle"

puppet var puppet_position = Vector2(0,0)
puppet var puppet_animation_vector = Vector2(0,0)
puppet var puppet_velocity = Vector2(0,0)

func _ready():
	animationTree.active = true
	label.text = server.players[int(name)]["Name"]
	if is_network_master():
		Globals.player = self
		stats._ready()
		stats.connect("no_health", self, "_on_no_health")
		var remoteTransform = RemoteTransform2D.new()
		var camera = get_node("../../../Camera2D")
		remoteTransform.set_remote_node(camera.get_path())
		add_child(remoteTransform)
		
		hurtBox.connect("area_entered", self, "_on_HurtBox_area_entered")
	
	# Tilemap Experiment
	grass_tilemap = get_node("../../../Background/GrassTileMap")
	dirt_tilemap = get_node("../../../Background/DirtTileMap")

func _on_no_health():
	rpc("player_died", int(name))

remotesync func player_died(player_id: int):
	state = DEAD
	get_node("../../../../World").KillPlayer(player_id)

func SetDamage(damage):
	swordHitBox.damage = damage

func _physics_process(delta):
	
	if paused:
		return
	
	if is_network_master():
		
		match(state):
			MOVE:
				move_state(delta)
			
			ROLL:
				roll_state()
				
			ATTACK:
				var attack_vector = global_position.direction_to(get_global_mouse_position())
				var controller_id_arr = Input.get_connected_joypads()
				if controller_id_arr.size() > 0 and Input.is_joy_button_pressed(controller_id_arr[0], JOY_BUTTON_2):
					attack_vector = Vector2(2, 2)
				rpc("attack_state", attack_vector)
		
		if server.players.size() > 1:  # Expensive?
			rset_unreliable("puppet_position", global_position)
			rset_unreliable("puppet_velocity", velocity)
			rset_unreliable("puppet_animation_vector", animation_vector)
	else:
		MovePuppetPlayer()
		# Extrapolate if needed
		if not tween.is_active():
			move()
	
	if state !=  DEAD and int(name) in server.players:
		server.players[int(name)]["Position"] = global_position

func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	animation_vector = input_vector
	
	if input_vector != Vector2.ZERO:
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationTree.set("parameters/Attack/blend_position", input_vector)  # For controller input
		animationTree.set("parameters/Roll/blend_position", input_vector)
		animationState.travel("Run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else:
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	if Input.is_action_just_pressed("attack"):
		state = ATTACK
		
	if Input.is_action_just_pressed("roll"):
		state = ROLL
	
	move()

func roll_state():
	velocity = animation_vector * ROLL_SPEED
	rpc("roll")
	move()

remotesync func roll():
	puppetState = "Roll"
	animationState.travel("Roll")

remotesync func attack_state(attack_vector):
	if puppetState != "Attack":
		puppetState = "Attack"
		velocity = Vector2.ZERO
		animationState.travel("Attack")
		if attack_vector != Vector2(2, 2):
			animationTree.set("parameters/Attack/blend_position", attack_vector)
			animationTree.set("parameters/Idle/blend_position", attack_vector)

func move():
	velocity = move_and_slide(velocity)

func attack_animation_finished():
	state = MOVE
	puppetState = "Idle"

func roll_animation_finished():
#	velocity = velocity * 0.8
	state = MOVE
	puppetState = "Idle"

func play_attack_sound():
	SoundFx.play("Swipe", global_position, rand_range(0.9, 1.1), -20)

func play_roll_sound():
	SoundFx.play("Evade", global_position, rand_range(0.9, 1.1), -20)

func run_step():
	var grass_cell = grass_tilemap.world_to_map(global_position)
	var grass_id = grass_tilemap.get_cellv(grass_cell)
	var step = "Step"
	if grass_id == TileMap.INVALID_CELL:
		step += "Dirt"
	SoundFx.play(step, global_position, rand_range(0.9, 1.3), -35)

func _on_HurtBox_area_entered(_area):
	stats.health -= 1
	hurtBox.start_invincibility(0.5)
	rpc("hurt")

remotesync func hurt():
	hurtBox.create_hit_effect()

func MovePuppetPlayer():
	if puppetState != "Attack":
		if puppet_animation_vector != Vector2.ZERO:
			var input_vector = puppet_animation_vector
			animationTree.set("parameters/Idle/blend_position", input_vector)
			animationTree.set("parameters/Run/blend_position", input_vector)
			animationTree.set("parameters/Attack/blend_position", input_vector)
			animationTree.set("parameters/Roll/blend_position", input_vector)
	
		if puppet_velocity == Vector2.ZERO:
			if puppetState != "Roll":
				puppetState = "Idle"
				animationState.travel("Idle")
		else:
			if puppetState != "Roll":
				puppetState = "Run"
				animationState.travel("Run")
			tween.interpolate_property(self, "global_position", global_position, puppet_position, 0.1)
			tween.start()
