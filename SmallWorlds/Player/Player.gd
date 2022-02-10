extends KinematicBody2D

export var Wheel: PackedScene
export var StepDustEffect: PackedScene
export var ShockWaveEffect: PackedScene
export var ParticleEffect: PackedScene
export var Arrow: PackedScene
export var ACCELERATION = 400
export var MAX_SPEED = 75
export var ROLL_SPEED = 130
export var FRICTION = 1000
export var ATTACK_SPEED = 15

enum {
	MOVE,
	ROLL,
	ATTACK,
	RANGED,
	HEAL,
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
onready var timer = $Timer

var puppetState = "Idle"

puppet var puppet_position = Vector2(0,0)
puppet var puppet_animation_vector = Vector2(0,0)
puppet var puppet_velocity = Vector2(0,0)

signal healed

func _ready():
	SaverAndLoader.load_game()
	PlayerStats.update()
	
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
		stats.connect("soul_charged", self, "_on_soul_charged")
	
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
	var new_spawn = Vector2(173, -71)
	if SaverAndLoader.custom_data.spawn_enabled:
		new_spawn = Vector2(SaverAndLoader.custom_data.spawn_x, SaverAndLoader.custom_data.spawn_y)
	rpc("player_died", new_spawn)
	stats.soul = 0
	for i in range(2):
		if stats.level <= i:
			stats.set_rock(stats.rocks[i] - 10, i)
	stats.health = stats.max_health

remotesync func player_died(new_spawn):
	if is_network_master():
		Globals.dead = true
	kill_player(new_spawn)
#	get_node("/root/World").KillPlayer(player_id)

func kill_player(new_spawn):
	state = DEAD
	puppetState = "Idle"
	hurtBox.set_deferred('monitoring', false)
	collisionShape.set_deferred('disabled', true)
	global_position = new_spawn
	yield(get_tree().create_timer(2.0), "timeout")
	revive_player()

func revive_player():
	state = MOVE
	hurtBox.set_deferred('monitoring', true)
	collisionShape.set_deferred('disabled', false)

func SetDamage(damage):
	swordHitBox.damage = damage

func set_lights(value: bool):
	print("player light")
	if value:
		tween.interpolate_property(light1, "energy", light1.energy, 0.5, 1.0)
		tween.interpolate_property(light2, "energy", light2.energy, 0.5, 1.0)
	else:
		tween.interpolate_property(light1, "energy", light1.energy, 0.0, 1.0)
		tween.interpolate_property(light2, "energy", light2.energy, 0.0, 1.0)
	
	tween.start()

func add_soul(soul):
	stats.soul += soul
	
func add_rock(value, type):
	stats.set_rock(stats.rocks[type] + value, type)

func _physics_process(delta):
	
	$Debug.text = str(state)
	
	if paused or state == DEAD:
		return
	
	if is_network_master():
		
		if Input.is_action_just_pressed("regen"):
			stats.set_rock(stats.rocks[0] + 10, 0)
			stats.set_rock(stats.rocks[1] + 9, 1)
			stats.set_soul(10)
			stats.health = stats.max_health
		
		
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
			
			RANGED:
				var ranged_vector = sword.swordEnd.global_position.direction_to(get_global_mouse_position())
				ranged_state(ranged_vector)
			
			HEAL:
				heal_state(delta)
		
		move()
		
		if server.players.size() > 1:  # Expensive?
			rpc_unreliable("sync_puppet_variables", global_position, velocity, animation_vector)
	else:
		MovePuppetPlayer(delta)
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
		
	if Input.is_action_just_pressed("roll"):
		state = ROLL
	
	if Input.is_action_pressed("heal") and stats.soul >= 1:
		state = HEAL
	
	if Input.is_action_just_pressed("fire") and stats.soul == stats.max_soul:
		spawning_fire()
	
	if selecting:
		return
	
	if Input.is_action_just_pressed("attack"):
		if wheel_id != 2:
			state = ATTACK
		else:
			state = RANGED

func spawning_fire():
	stats.soul = 0
	rpc("spawn_fire", global_position)

remotesync func spawn_fire(new_position):
	Network.fires.append(new_position)
	SaverAndLoader.custom_data.fires_x.append(new_position.x)
	SaverAndLoader.custom_data.fires_y.append(new_position.y)
	SaverAndLoader.save_game()
	var bg = get_node("/root/World/Background")
	bg.spawn_fire(new_position)

func roll_state():
	velocity = animation_vector * ROLL_SPEED
	if puppetState != "Roll":
		rpc("roll")

remotesync func roll():
	puppetState = "Roll"
	animationState.travel("Roll")

func heal_state(delta):
	if Input.is_action_just_released("heal"):
		timer.stop()
		rpc("end_heal", false)
		return
	
	if is_network_master():
		Shake.shake(0.5, delta, 0)
		
	if puppetState != "Heal" and timer.is_stopped():
		timer.start(1)
		rpc("heal")

remotesync func heal():
	velocity = Vector2.ZERO
	puppet_velocity = Vector2.ZERO
	puppetState = "Heal"

remotesync func end_heal(success: bool):
	puppetState = "Idle"
	state = MOVE
	if success:
		play_heal_sound()
		var particleEffect = ParticleEffect.instance()
		particleEffect.set_particles_color(Color.green)
		self.add_child(particleEffect)
		particleEffect.scale = Vector2(2, 2)
		particleEffect.global_position = global_position

func attack_state(attack_vector):
	velocity = attack_vector * ATTACK_SPEED
	if puppetState != "Attack":
		rpc("attack", attack_vector)

remotesync func attack(attack_vector):
	puppet_velocity = attack_vector * ATTACK_SPEED
	puppetState = "Attack"
	animationState.travel("Attack")
	sword.attack()
	if attack_vector != Vector2(2, 2):
		animationTree.set("parameters/Attack/blend_position", attack_vector)
		animationTree.set("parameters/Idle/blend_position", attack_vector)

func ranged_state(ranged_vector):
	if stats.soul < 1:
		state = MOVE
		return
	stats.soul -= 1
	if puppetState != "Ranged":
		rpc("ranged", ranged_vector, PlayerStats.level)

remotesync func ranged(ranged_vector, level):
	sword.ranged()
	var arrow = Globals.instance_scene_on_world(Arrow, sword.swordEnd.global_position)
	arrow.velocity = ranged_vector
	arrow.level = level
	play_ranged_sound()
	ranged_animation_finished()

func ranged_animation_finished():
	state = MOVE
	puppetState = "Idle"

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
		if wheel != null:
			wheel.call_deferred("queue_free")
			wheel = null

func play_attack_sound():
	SoundFx.play("Swipe", global_position, rand_range(0.5, 1.7), -30)

func play_ranged_sound():
	SoundFx.play("Swipe", global_position, rand_range(3.0, 5.0), -30)

func play_roll_sound():
	SoundFx.play("Evade", global_position, rand_range(0.9, 1.1), -20)
	
func play_heal_sound():
	SoundFx.play("Heal", global_position, rand_range(1.2, 1.8), -20)

func play_hurt_sound():
	SoundFx.play("Hurt", global_position, rand_range(1.2, 1.5), -10)

func play_soul_sound():
	SoundFx.play("Soul", global_position, rand_range(0.7, 1), -20)

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
	SoundFx.play(step, global_position, rand_range(0.9, 1.3), -30)
	
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
	if hurtBox.monitorable == false:
		return
	if stats.health > 0:
		stats.health -= area.damage
	hurtBox.start_invincibility(3)
	rpc("hurt")

remotesync func hurt():
	hurtBox.create_hit_effect()
	play_hurt_sound()
	var particleEffect = ParticleEffect.instance()
	particleEffect.set_particles_color(Color.red)
	self.add_child(particleEffect)
	particleEffect.scale = Vector2(1.5, 1.5)
	particleEffect.global_position = global_position

func _on_soul_charged():
	rpc("soul")

remotesync func soul():
	play_soul_sound()
	var particleEffect = ParticleEffect.instance()
	particleEffect.set_particles_color(Color.white)
	self.add_child(particleEffect)
	particleEffect.scale = Vector2(2, 2)
	particleEffect.particles.process_material.hue_variation = 0
	particleEffect.global_position = global_position

func MovePuppetPlayer(delta):
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
			if global_position == puppet_position:
				puppet_position = puppet_position + puppet_velocity * delta
			tween.interpolate_property(self, "global_position", global_position, puppet_position, delta/2)
			tween.start()
	else:
		tween.interpolate_property(self, "global_position", global_position, global_position + puppet_velocity * delta, delta/2)
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

func _on_Timer_timeout():
	if state != MOVE:
		stats.soul -= 1
		stats.health += 1
		state = MOVE
		if sword.level >= 2:
			emit_signal("healed")
		rpc("end_heal", true)
