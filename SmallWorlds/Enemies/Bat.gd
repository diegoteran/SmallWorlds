extends "res://Enemies/Enemy.gd"

export var EnemyDeathEffect:PackedScene # = preload("res://Effects/EnemyDeathEffect.tscn")

func _ready():
	# Reflection
	var remote_transform = Globals.create_reflection(sprite, "bat"+name)
	add_child(remote_transform)

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
		
		for new_id in subscribed:
			if new_id in Network.players.keys() and tick:
				rpc_unreliable_id(new_id, "sync_puppet_variables", global_position, velocity)
		tick = !tick
	
	else:
		MovePuppetBat()

func MovePuppetBat():
	global_position = puppet_position
	sprite.flip_h = puppet_velocity.x < 0

func update_wander_controller():
	state = pick_random_state([IDLE, WANDER])
	wanderController.start_wander_timer(rand_range(1, 3))

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE

func play_flap():
	SoundFx.play("BatFlap", global_position, rand_range(1.5, 2), -35)

func play_hurt():
	var num = (randi() % 2) + 1
	SoundFx.play("BatHurt" + str(num), global_position, rand_range(0.8, 1.2), -30)

func play_defeated():
	SoundFx.play("BatDefeated", global_position, rand_range(0.8, 1.2), -30)

remotesync func hurt(new_knockback: Vector2, new_hp: float) -> void:
	self.hp = new_hp
	hurtBox.create_hit_effect()
	.play_hit_sound()
	knockback = new_knockback
	play_hurt()

puppet func sync_puppet_variables(pos: Vector2, vel: Vector2) -> void:
	puppet_position = pos
	puppet_velocity = vel

func _on_Stats_no_health():
	queue_free()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position

func _on_death():
	if (get_tree().is_network_server()):
		server.NPCKilled(int(name))
	
	delete_reflection()
	queue_free()
#	SoundFx.play("EnemyDie", global_position, rand_range(0.9, 1.1), -30)
	play_defeated()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position

func delete_reflection():
	Globals.delete_reflection("bat"+name)

func Health(health):
	if health != hp:
		hp = health
		if hp <= 0:
			_on_death()
