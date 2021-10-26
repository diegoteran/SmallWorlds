extends Node2D

export var WorldParticle: PackedScene

export(int) var particle_num = 15
var particles = []
# Called when the node enters the scene tree for the first time.
func _ready():
	for _i in range(particle_num):
		var new_particle = Globals.instance_scene_on_node(WorldParticle, self, global_position)
		particles.append(new_particle)


func queue_free():
	for particle in particles:
		particle.queue_free()
		.queue_free()
