extends Node2D

var cat = preload("res://cat/cat.tscn")
var launched = 0
var cat_gone = 0
var launch_angle = 0

var launch_direction = Vector2(1500, -1500)
var launch_speed = 2000

var armed = 0
var start_launch = 0
var launch_power = 10
var max_launch_power = 4000
var launch_power_inc = 4000

func _ready():
	armed = 0
	global.catopult_armed = 0
	set_process(true)
	set_process_input(true)



func _process(delta):
	
	# Arrow dir
	var a_angle = get_node("launch_point").get_angle_to(get_global_mouse_pos())
	if a_angle > 0:
		a_angle -= PI/2.0
		if a_angle > 0:
			launch_angle = a_angle
	get_node("launch_point/arrow").set_rot(launch_angle - PI/2)
	
	if armed:
		get_node("launch_point/arrow").set_hidden(false)
		get_node("launch_point/arrow").get_material().set_shader_param("color2", Color(1,1,1,0.5))
		get_node("launch_point/arrow").get_material().set_shader_param("border", 1.0)
		# Cat launch
		if launched == 0:
			if Input.is_action_pressed("lmb"):
				start_launch = 1
				#get_node("AnimationPlayer").play("hassha")
				#launched = 2
			if start_launch:
				launch_power += launch_power_inc * delta
				if launch_power > max_launch_power:
					launch_power = max_launch_power
				get_node("launch_point/arrow").get_material().set_shader_param("border", (max_launch_power - launch_power)/max_launch_power)
	if launched:
		launched -= delta
		if cat_gone == 0:
			if launched < 1.9:
				var c = cat.instance()
				c.set_global_pos(get_node("launch_point").get_global_pos())
				launch_direction = Vector2(cos(launch_angle) * launch_speed, -sin(launch_angle) * launch_speed)
				c.move_speed = launch_direction
				get_parent().get_parent().add_cat(c)
				global.cat_launched(c)
				cat_gone = 1
				mewwww()
		if launched < 0:
			launched = 0
			cat_gone = 0
			#armed = 1


func _input(event):
	if (event.type==InputEvent.MOUSE_BUTTON): 
		if (event.button_index == BUTTON_LEFT): 
			if not event.is_pressed():
				if start_launch:
					get_node("AnimationPlayer").play("hassha")
					launched = 2
					launch_speed = launch_power
					launch_power = 10
					start_launch = 0
					armed = 0
					global.catopult_armed = 0
					get_node("launch_point/arrow").set_hidden(true)

func arm_catopult():
	if launched == 0:
		armed = 1
		global.catopult_armed = 1


func mewwww():
	var r = randf()
	if r < 0.3:
		get_node("SamplePlayer").play("Myaaaav2")
	elif r < 0.6:
		get_node("SamplePlayer").play("Myaaaav6")
	else:
		get_node("SamplePlayer").play("Myaaaav7")

