extends Node

var cam_speed = 1000
var cam_mouse_scroll_speed = 1.3
var last_mouse_pos = null

var cat_button = preload("res://game/cat_button.tscn")
var testlevel = preload("res://levels/leveltest.tscn")

var cat_buttons = []
var level = null
var camera = null
var catopult = null
var messaging = null

var cats = 0
var waiting_for_cat = 0

var cam_zoom = 1
var max_camera_zoom = 1
var min_camera_zoom = 0.5
var cam_offset = Vector2(0,0)
var cam_pos = Vector2(960,540)
var default_cam_dim = Vector2(1920, 1080)
var current_cam_dim = Vector2(1920, 1080)

var left_limit = 0
var right_limit = 1920
var bottom_limit = 1080

func _ready():
	global.game = self
	catopult = get_node("game_field/ctp")
	messaging = get_node("ui/msg")
	camera = get_node("game_field/cam")
	cam_pos = camera.get_pos()
	camera.make_current()
	if global.level_to_load == null:
		load_new_level(testlevel)
	else:
		var newlevel = load(global.level_to_load)
		load_new_level(newlevel)
	set_process(true)
	set_process_input(true)

func _exit_tree():
	global.game = null

func _process(delta):
	# cam movement
	if Input.is_action_pressed("ui_right"):
		#cam_offset.x += cam_speed*delta
		cam_pos.x += cam_speed*delta
	if Input.is_action_pressed("ui_left"):
		#cam_offset.x -= cam_speed*delta
		cam_pos.x -= cam_speed*delta
	
	if Input.is_action_pressed("ui_up"):
		#cam_offset.y -= cam_speed*delta
		cam_pos.y -= cam_speed*delta
	if Input.is_action_pressed("ui_down"):
		#cam_offset.y += cam_speed*delta
		cam_pos.y += cam_speed*delta
	normalize_cam_pos()
	
	if Input.is_action_pressed("ui_cancel"):
		if global.pause == 0:
			global.pause = 1
			get_node("cm").set_hidden(false)
			get_node("pause_ui/cont").set_hidden(false)
			get_tree().set_pause(true)
	
	# meta logic
	if waiting_for_cat == 0:
		if cats > 0:
			# arm new cat
			if not global.catopult_armed:
				global.arm_catopult()
		else:
			# Finish game!
			if global.dwarfs_to_catifize > 0:
				lose_level()
			else:
				win_level()

func _input(event):
	if (event.type == InputEvent.MOUSE_BUTTON):
		if (event.button_index == BUTTON_WHEEL_UP):
			cam_zoom -= 0.05
			if cam_zoom < min_camera_zoom:
				cam_zoom = min_camera_zoom
			camera.set_zoom(Vector2(cam_zoom, cam_zoom))
			normalize_cam_pos()
		if (event.button_index == BUTTON_WHEEL_DOWN):
			cam_zoom += 0.05
			if cam_zoom > max_camera_zoom:
				cam_zoom = max_camera_zoom
			camera.set_zoom(Vector2(cam_zoom, cam_zoom))
			normalize_cam_pos()
		if event.button_index == BUTTON_RIGHT:
			if not event.is_pressed():
				last_mouse_pos = null
	if (event.type == InputEvent.MOUSE_MOTION):
		if Input.is_mouse_button_pressed(BUTTON_RIGHT):
			if last_mouse_pos == null:
				last_mouse_pos = event.pos
			else:
				var new_mouse_pos = event.pos
				cam_pos += (last_mouse_pos - new_mouse_pos) * cam_mouse_scroll_speed
				last_mouse_pos = new_mouse_pos
				normalize_cam_pos()
	if (event.type==InputEvent.KEY):
		if event.scancode == KEY_ESCAPE:
			if event.pressed == false:
				if global.pause == 3:
					global.pause = 0

func normalize_cam_pos():
	current_cam_dim = default_cam_dim * cam_zoom
	#if (cam_pos.y + cam_offset.y + current_cam_dim.y/2) > (bottom_limit * cam_zoom):
	#	cam_offset.y = bottom_limit * cam_zoom - current_cam_dim.y/2 - cam_pos.y
	#if cam_offset.x < (left_limit + (cam_pos.x - current_cam_dim.x/2)):
	#	cam_offset.x = left_limit + (cam_pos.x - current_cam_dim.x/2)
	#if cam_offset.x > (right_limit - current_cam_dim.x):
	#	cam_offset.x = right_limit - current_cam_dim.x
	#camera.set_offset(cam_offset)
	if (cam_pos.y + current_cam_dim.y/2) > bottom_limit:
		cam_pos.y = bottom_limit - current_cam_dim.y/2
	if (cam_pos.x  + current_cam_dim.x/2) > right_limit:
		cam_pos.x = right_limit - current_cam_dim.x/2
	if (cam_pos.x  - current_cam_dim.x/2) < left_limit:
		cam_pos.x = left_limit + current_cam_dim.x/2
	camera.set_pos(cam_pos)
	

func set_limits():
	left_limit = level.get_node("left_limit").get_pos().x
	right_limit = level.get_node("right_limit").get_pos().x
	camera.set_limit(MARGIN_LEFT, left_limit)
	camera.set_limit(MARGIN_RIGHT, right_limit)
	camera.set_limit(MARGIN_BOTTOM, bottom_limit)
	max_camera_zoom = (right_limit - left_limit) / 1920.0

func load_new_level_from(lname):
	var newlevel = load(lname)
	load_new_level(newlevel)

func load_new_level(level_scene):
	if get_node("game_field").has_node("level"):
		get_node("game_field").remove_child(get_node("game_field/level"))
	level = level_scene.instance()
	get_node("game_field").add_child(level)
	global.current_level = level
	set_limits()
	cats = level.cats
	cam_pos = Vector2(960,540)
	cam_zoom = 1
	normalize_cam_pos()
	for c in range(cats):
		var b = cat_button.instance()
		cat_buttons.append(b)
		get_node("ui/ScrollContainer/VBoxContainer").add_child(b)
	var dwarfs = 0
	for n in level.get_children():
		if n.get_name().find("dwarf") != -1:
			dwarfs += 1
	global.dwarfs_to_catifize = dwarfs
	global.arm_catopult()
	set_process(true)

func reset_level():
	cats = 0
	waiting_for_cat = 0
	global.dwarfs_to_catifize = 0
	global.active_cat = 0
	catopult.armed = 0
	global.catopult_armed = 0
	catopult.set_process(true)
	cat_buttons.clear()
	for n in get_node("ui/ScrollContainer/VBoxContainer").get_children():
		n.queue_free()

func cat_launched(new_cat):
	if cats > 0:
		get_node("ui/ScrollContainer/VBoxContainer").remove_child(cat_buttons[cats-1])
		cat_buttons.remove(cats-1)
		cats -= 1
		waiting_for_cat = 1

func cat_finish_job():
	waiting_for_cat = 0


func win_level():
	#print("WIN")
	catopult.set_process(false)
	catopult.armed = 0
	get_node("cm").set_hidden(false)
	get_node("finish_ui/cont").set_hidden(false)
	get_node("finish_ui/cont/VBoxContainer/success").set_hidden(false)
	if global.current_level_num == global.MAX_LEVELS:
		get_node("finish_ui/cont/VBoxContainer/HBoxContainer/next level").set_hidden(true)
	level_data.set_complete(global.current_level_num)

func lose_level():
	#print("LOSE")
	catopult.set_process(false)
	catopult.armed = 0
	get_node("cm").set_hidden(false)
	get_node("finish_ui/cont").set_hidden(false)
	get_node("finish_ui/cont/VBoxContainer/lose").set_hidden(false)
	get_node("finish_ui/cont/VBoxContainer/HBoxContainer/next level").set_hidden(true)

func hide_finish_layer():
	get_node("cm").set_hidden(true)
	get_node("finish_ui/cont").set_hidden(true)
	get_node("finish_ui/cont/VBoxContainer/lose").set_hidden(true)
	get_node("finish_ui/cont/VBoxContainer/success").set_hidden(true)
	get_node("finish_ui/cont/VBoxContainer/HBoxContainer/next level").set_hidden(false)

func _on_pause_continue_pressed():
	global.pause = 0
	get_node("cm").set_hidden(true)
	get_node("pause_ui/cont").set_hidden(true)
	get_tree().set_pause(false)

func _on_pause_replay_pressed():
	global.pause = 0
	get_node("cm").set_hidden(true)
	get_node("pause_ui/cont").set_hidden(true)
	get_tree().set_pause(false)
	set_process(false)
	reset_level()
	var newlevel = load(global.level_to_load)
	load_new_level(newlevel)

func _on_pause_exit_pressed():
	get_tree().set_pause(false)
	global.load_menu()


func _on_exit_pressed():
	hide_finish_layer()
	global.load_menu()


func _on_replay_pressed():
	set_process(false)
	hide_finish_layer()
	reset_level()
	var newlevel = load(global.level_to_load)
	load_new_level(newlevel)


func _on_next_level_pressed():
	set_process(false)
	hide_finish_layer()
	reset_level()
	var next_level = global.current_level_num + 1
	global.current_level_num = next_level
	global.load_level(str("level", next_level))


func add_cat(cat):
	level.get_node("cat_place").add_child(cat)


