extends Sprite

export var WheelIcon: PackedScene
var time_start = 0	# The time since the application was started
var elapsed_time = 0	# The time since time start was set

var outer_r = 0.45	# The outer radius of the wheel
var inner_r = 0.2	# The inner radius of the wheel

# The colours of each segment starting from the bottom right and going clockwise
var colours = [Color(0.403, 0.215, 0.270), Color(0.403, 0.215, 0.270), Color(0.403, 0.215, 0.270), Color(0.403, 0.215, 0.270)]

var no_of_colours = len(colours)	# Number of colours in the colours array
var selected_colour = -1	# The index of the selected colour within the colours array
var old_selected_colour = 0		# Used to track if the selected colour was changed so the animation can be restarted

var size = Vector2()
var mouse_pos = Vector2()
var rel_mouse_pos = Vector2()	# Mouse position relative to the position of the wheel
var angle = 0	# The angle, in radians, starting from the right, going clockwise
var norm_angle = 0	# The angle, but normalized (from 0 to 1)

var mouse_entered = false	# If the mouse has entered the wheel

var mat		# The shader material

signal colour_change	# The signal corresponding to if the selection has changed
signal mouse_exited		# The signal corresponding to if the mouse has exited the wheel area. Used to make sure that the colour doesn't change

var icons = []

func _ready():
	# These signals are connected to another script that spawns this wheel
	if get_parent():
		connect("colour_change", get_parent(), "_on_SelectionWheel_colour_change")
		connect("mouse_exited", get_parent(), "_on_SelectionWheel_mouse_exited")
	size = get_texture().get_size()
	mat = self.get_material()
	mat.set_shader_param("no_of_colours", no_of_colours)
	mat.set_shader_param("initial_outer_r", outer_r)
	mat.set_shader_param("inner_r", inner_r)
	
	# Sets the colours of the colour variables in the shader according to the colours array within this script
	for i in range(no_of_colours):
		mat.set_shader_param("colour"+str(i), Vector3(colours[i].r, colours[i].g, colours[i].b))
	
	place_items()

func _process(delta):
	mouse_pos = get_global_mouse_position()
	
	rel_mouse_pos = mouse_pos - global_position
	angle = atan2(rel_mouse_pos.y, rel_mouse_pos.x)		# Calculates the angle in radians
	norm_angle = angle/(2*PI)
	
	# Without this if statement, the angle goes from 0 to 0.5 on the bottom half and -0.5 to 0 on the top half, clockwise.
	# The if statement is used to make sure it goes from 0 to 1 clockwise all the way around the wheel
	if norm_angle < 0:
		norm_angle += 1
	
	# The radii are multiplied by the size of the sprite and the scale to make it work for any texture and scale.
	# This assumes that the texture used is a SQUARE.
	if (rel_mouse_pos.length() < outer_r*size.x*scale.x) and (rel_mouse_pos.length() > inner_r*size.x*scale.x):
		
		# Selects the appropriate colour according to where the mouse is
		for i in range(no_of_colours):
			if ((norm_angle > float(i)/float(no_of_colours)) and (norm_angle < float(i+1)/float(no_of_colours))):
				if selected_colour >= 0 and selected_colour != i:
					icons[selected_colour].stop_hover()
				selected_colour = i
		
		# This condition is met either when the mouse enters the wheel's bounding area or a new colour is hovered over. 
		# This is to make sure that the animation starts from the initial position of the segment
		if (not mouse_entered) or (selected_colour != old_selected_colour):
			time_start = OS.get_ticks_msec()
			old_selected_colour = selected_colour
		mouse_entered = true
		
		elapsed_time = OS.get_ticks_msec() - time_start
		mat.set_shader_param("selected_colour", selected_colour)
		mat.set_shader_param("elapsed_time", elapsed_time/1000.0)	# 1000.0 was chosen as it made the animation an appropriate speed
		
		emit_signal("colour_change", selected_colour)	# Emits a signal with the selected colour
		icons[selected_colour].start_hover()
	else:
		emit_signal("mouse_exited")
		icons[selected_colour].stop_hover()
		mouse_entered = false
		mat.set_shader_param("selected_colour", -1)		# Sets the selected colour to be nothing as the mouse isn't hovering over the wheel anymore

func place_items():
	var rot = 360.0 / no_of_colours
	for i in no_of_colours:
		var wheelIcon = WheelIcon.instance()
		add_child(wheelIcon)
		wheelIcon.set_frame(i)
		wheelIcon.set_rot(rot/2 + rot*i)
		icons.append(wheelIcon)
