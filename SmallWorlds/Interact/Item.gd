extends Area2D

export var StepDustEffect: PackedScene
export var ShockWaveEffect: PackedScene

var id = 0
var sync_seed

enum {
	SOUL,
	HEART,
	ROCK_1,
	ROCK_2
}

onready var sprite = $Sprite
onready var shadowSprite = $Sprite2
onready var animationPlayer = $AnimationPlayer
onready var tween = $Tween

const MIN_X =  50.0
const MAX_X = 90.0
const MIN_Y = -70.0
const MAX_Y =  70.0
var BOUNCE_TIMES = [0.3, 0.25, 0.2, 0.1, 0.08]
var BOUNCE_HEIGHTS = [16, 12, 6, 4, 2]

# Tilemap experiment
var grass_tilemap
var dirt_tilemap
var water_tilemap

func _ready():
	seed(sync_seed)
	
	var remote_transform = Globals.create_reflection(sprite, name)
	add_child(remote_transform)
	animationPlayer.play("anim")
	
	# Tilemap Experiment
	grass_tilemap = get_node("/root/World/Background/GrassTileMap")
	water_tilemap = get_node("/root/World/Background/WaterTileMap")
	dirt_tilemap = get_node("/root/World/Background/DirtTileMap")
	
	
	# Bouncing
	var starting_y = sprite.position.y
	
	var direction = 1 if randi() % 2 == 0 else -1
	var goal = global_position + Vector2(rand_range(MIN_X, MAX_X), rand_range(MIN_Y, MAX_Y)) * direction

	var sum_time = 0.0
	for i in BOUNCE_HEIGHTS.size() - (randi() % 3):
		BOUNCE_TIMES[i] = BOUNCE_TIMES[i] + rand_range(-BOUNCE_TIMES[i]/4, BOUNCE_TIMES[i]/4)
		BOUNCE_HEIGHTS[i] = BOUNCE_HEIGHTS[i] + rand_range(-BOUNCE_HEIGHTS[i]/3, BOUNCE_HEIGHTS[i]/3)
		tween.interpolate_property(sprite, "position:y", starting_y, starting_y - BOUNCE_HEIGHTS[i], BOUNCE_TIMES[i], Tween.TRANS_QUAD, Tween.EASE_OUT, sum_time)
		sum_time += BOUNCE_TIMES[i]
		tween.interpolate_property(sprite, "position:y", starting_y - BOUNCE_HEIGHTS[i], starting_y, BOUNCE_TIMES[i], Tween.TRANS_QUAD, Tween.EASE_IN, sum_time)
		sum_time += BOUNCE_TIMES[i]
		bounce(sum_time)
	tween.interpolate_property(self, "global_position:x", null, goal.x, sum_time, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.interpolate_property(self, "global_position:y", null, goal.y, sum_time, Tween.TRANS_LINEAR, Tween.EASE_IN)

	tween.start()
	
	$Timer.wait_time = 5
	$Timer.start()

## has to be called before adding the node to the scenetree
func init(item_id, unique_name):
	self.id = item_id
	name = "itemFrom" + unique_name

#func _process(_delta):
#	self.queue_free()

func _on_Item_body_entered(body):
	if body.is_network_master() and body.has_method("on_item_collected"):
		body.on_item_collected(id)
		rpc("delete")

remotesync func delete():
	queue_free()

func bounce(delay: float):
	yield(get_tree().create_timer(delay), "timeout")
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
	SoundFx.play(step, global_position, rand_range(1.8, 2.3), -30)
	
	# Dust Particle

	var effect = StepDustEffect.instance()  #Globals.instance_scene_on_node(StepDustEffect, get_parent(), global_position - velocity.normalized())
	effect.color = Color("ffe486")
	if grass_id == TileMap.INVALID_CELL:
		if water_id == TileMap.INVALID_CELL:
			effect.color = Color("919191")
		else:
			Globals.instance_scene_on_node(ShockWaveEffect, water_tilemap, global_position)
#			effect.modulate = Color.aqua
	if water_id == TileMap.INVALID_CELL or grass_id != TileMap.INVALID_CELL: # No dust on water
		get_parent().call_deferred("add_child", effect)
	effect.global_position = global_position

func queue_free():
	Globals.delete_reflection(name)
	.queue_free()

func _on_Timer_timeout():
	queue_free()
