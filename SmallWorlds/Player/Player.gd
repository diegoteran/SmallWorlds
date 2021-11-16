extends KinematicBody2D

export var Wheel: PackedScene
export var StepDustEffect: PackedScene
export var ShockWaveEffect: PackedScene
export var ACCELERATION = 500
export var MAX_SPEED = 100
export var ROLL_SPEED = 150
export var FRICTION = 1000
export var ATTACK_SPEED = 15

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
var buffer_attack = false

# Tilemap experiment
var grass_tilemap
var dirt_tilemap
var water_tilemap

# Wheel experiment
var wheel = null
var selecting = false
var wheel_id = -1

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var hurtBox = $HurtBox
onready var swordHitBox = $HitBoxPivot/SwordHitBox
onready var tween = $Tween
onready var label = $Label
onready var sword = $YSort/Sword
onready var sprite = $YSort/Sprite
onready var light1 = $Light1
onready var light2 = $Light2
onready var collisionShape = $CollisionShape2D

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
	
	# Reflection
	var remote_transform = Globals.create_reflection(sprite, name)
	add_child(remote_transform)
	
	# Tilemap Experiment
	grass_tilemap = get_node("/root/World/Background/GrassTileMap")
	water_tilemap = get_node("/root/World/Background/WaterTileMap")
	dirt_tilemap = get_node("/root/World/Background/DirtTileMap")
	
	# Light Handler
# warning-ignore:return_value_discarded
	get_node("/root/World/DayNightCycle").connect("light_changed", self, "set_lights")
	
	Globals.dead = false

func _on_no_health():
	rpc("player_died")

remotesync func player_died():
	if is_network_master():
		Globals.dead = true
	kill_player()
#	get_node("/root/World").KillPlayer(player_id)

func kill_player():
	state = DEAD
	hurtBox.set_deferred('monitoring', false)
	collisionShape.set_deferred('disabled', true)
	global_position = Vector2(500, -500)
	yield(get_tree().create_timer(1.0), "timeout")
	revive_player()
	pass

func revive_player():
	state = MOVE
	stats.health = stats.max_health
	hurtBox.set_deferred('monitoring', true)
	collisionShape.set_deferred('disabled', false)
	pass

func SetDamage(damage):
	swordHitBox.damage = damage

func set_lights(value: bool):
	print("player light")
	if value:
		tween.interpolate_property(light1, "energy", light1.energy, 0.8, 1.0)
		tween.interpolate_property(light2, "energy", light2.energy, 0.8, 1.0)
	else:
		tween.interpolate_property(light1, "energy", light1.energy, 0.0, 1.0)
		tween.interpolate_property(light2, "energy", light2.energy, 0.0, 1.0)
	
	tween.start()

func add_soul(soul):
	stats.soul += soul

func _physics_process(delta):
	
	if paused or state == DEAD:
		return
	
	if is_network_master():
		# Wheel Experiment
		menu_wheel()
		
		match(state):
			MOVE:
				move_state(delta)
			
			ROLL:
				roll_state()
				
			ATTACK:
				if !selecting:
					if Input.is_action_just_pressed("attack") and !buffer_attack:
						rpc("sync_buffer_attack")
					
					var attack_vector = global_position.direction_to(get_global_mouse_position())
					var controller_id_arr = Input.get_connected_joypads()
					if controller_id_arr.size() > 0 and Input.is_joy_button_pressed(controller_id_arr[0], JOY_BUTTON_2):
						attack_vector = Vector2(2, 2)
					attack_state(attack_vector)
		
		move()
		
		if server.players.size() > 1:  # Expensive?
			rpc_unreliable("sync_puppet_variables", global_position, velocity, animation_vector)
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

func roll_state():
	velocity = animation_vector * ROLL_SPEED
	if puppetState != "Roll":
		rpc("roll")

func attack_state(attack_vector):
	velocity = attack_vector * ATTACK_SPEED
	if puppetState != "Attack":
		rpc("attack", attack_vector)

remotesync func roll():
	puppetState = "Roll"
	animationState.travel("Roll")

remotesync func attack(attack_vector):
	puppetState = "Attack"
	animationState.travel("Attack")
	sword.attack()
	if attack_vector != Vector2(2, 2):
		animationTree.set("parameters/Attack/blend_position", attack_vector)
		animationTree.set("parameters/Idle/blend_position", attack_vector)

remotesync func sync_puppet_variables(pos, vel, a_vector):
	puppet_position = pos
	puppet_velocity = vel
	puppet_animation_vector = a_vector

remotesync func sync_buffer_attack():
	buffer_attack = true

func move():
	velocity = move_and_slide(velocity)

func check_buffered_attack():
	if buffer_attack:
		sword.attack()
		play_attack_sound()
	else:
		attack_animation_finished()

func attack_animation_finished():
	state = MOVE
	buffer_attack = false
	puppetState = "Idle"

func roll_animation_finished():
#	velocity = velocity * 0.8
	state = MOVE
	puppetState = "Idle"

func menu_wheel():
	if Input.is_action_pressed("wheel"):
		if wheel == null:
			wheel = Wheel.instance()
			wheel.position.y -= 20
			add_child(wheel)
			tween.interpolate_property(wheel, "scale", Vector2.ZERO, Vector2.ONE, 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
			tween.start()
	
	if Input.is_action_just_released("wheel"):
		SoundFx.play_menu("Menu Select", rand_range(0.9, 1.1), -20)
		tween.interpolate_property(wheel, "scale", Vector2.ONE, Vector2.ZERO, 0.1, Tween.TRANS_ELASTIC, Tween.EASE_IN)
		tween.start()
		yield(get_tree().create_timer(0.1), "timeout") 
		wheel.call_deferred("queue_free")
		wheel = null

func play_attack_sound():
	SoundFx.play("Swipe", global_position, rand_range(0.5, 1.7), -30)

func play_roll_sound():
	SoundFx.play("Evade", global_position, rand_range(0.9, 1.1), -20)

func run_step():
	# Step sound
	var grass_cell = grass_tilemap.world_to_map(global_position)
	var water_cell = water_tilemap.world_to_map(global_position)
	var grass_id = grass_tilemap.get_cellv(grass_cell)
	var water_id = water_tilemap.get_cellv(water_cell)
	var step = "Step"
	if grass_id == TileMap.INVALID_CELL:
		if water_id == TileMap.INVALID_CELL:
			step += "Dirt"
		else:
			step += "Water"
	SoundFx.play(step, global_position, rand_range(0.9, 1.3), -25)
	
	# Dust Particle
	
	var effect = StepDustEffect.instance()  #Globals.instance_scene_on_node(StepDustEffect, get_parent(), global_position - velocity.normalized())
	effect.modulate = Color("ffe486")
	if grass_id == TileMap.INVALID_CELL:
		if water_id == TileMap.INVALID_CELL:
			effect.modulate = Color("919191")
		else:
			Globals.instance_scene_on_node(ShockWaveEffect, water_tilemap, global_position)
#			effect.modulate = Color.aqua
	if water_id == TileMap.INVALID_CELL or grass_id != TileMap.INVALID_CELL: # No dust on water
		get_parent().call_deferred("add_child", effect)
	effect.global_position = global_position - velocity.normalized()*2

func _on_HurtBox_area_entered(area):
	if stats.health > 0:
		stats.health -= area.damage
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

# Wheel experiment
func _on_SelectionWheel_colour_change(id):
	if !selecting or id != wheel_id:
		wheel_id = id
		selecting = true
		SoundFx.play_menu("Menu Move", rand_range(0.9, 1.1), -20)
		sword.select_item(wheel_id)
		print("color changed: ", wheel_id)

func _on_SelectionWheel_mouse_exited():
	if selecting:
		selecting = false
		print("exit wheel")

func queue_free():
	sword.queue_free()
	Globals.delete_reflection(name)
	.queue_free()
