extends KinematicBody2D

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")

var attack_dict = {}
var stateServer = "Idle"

func _ready():
	animationTree.active = true

func _physics_process(delta):
	if not attack_dict == {}:
		Attack()

func MovePlayer(new_position, animation_vector):
	if stateServer != "Attack":
		if animation_vector != Vector2.ZERO:
			var input_vector = animation_vector
			animationTree.set("parameters/Idle/blend_position", input_vector)
			animationTree.set("parameters/Run/blend_position", input_vector)
	
		if new_position == position:
			stateServer = "Idle"
			animationState.travel("Idle")
		else:
			stateServer = "Run"
			animationState.travel("Run")
			set_position(new_position)


func Attack():
	for attack_time in attack_dict.keys():
		if attack_time <= Network.client_clock:
			stateServer = "Attack"
			set_position(attack_dict[attack_time]["P"])
			animationTree.set("parameters/Attack/blend_position", attack_dict[attack_time]["A"])
			animationState.travel("Attack")
			attack_dict.erase(attack_time)

func attack_animation_finished():
	stateServer = "Idle"
