extends Node

var bg_xoffset = 0
var bg_yoffset = 0
var story_showing = 0

func _ready():
	if global.options.full_screen:
		get_node("CenterContainer/VBoxContainer/b_options").set_text("FULLSCREEN ON")
	if global.menu_levels_showing == 0:
		get_node("levels").set_hidden(true)
	else:
		get_node("levels").set_hidden(false)
	level_data.load_level_data()
	if level_data.levels.size() < global.MAX_LEVELS:
		populate_level_data()
	update_level_buttons()
	set_process_input(true)
	set_process(true)

func _process(delta):
	bg_xoffset += 100 * delta
	bg_yoffset += 100 * delta
	if bg_xoffset > 0:
		bg_xoffset -= 512.0
	if bg_yoffset > 0:
		bg_yoffset -= 512.0
	get_node("bg").set_pos(Vector2(bg_xoffset, bg_yoffset))
	get_node("levels/bg").set_pos(Vector2(bg_xoffset, bg_yoffset))
	get_node("story/bg").set_pos(Vector2(bg_xoffset, bg_yoffset))

func populate_level_data():
	for l in get_node("levels/level_container").get_children():
		level_data.levels[l.num_display] = [0, l.level]

func update_level_buttons():
	for l in get_node("levels/level_container").get_children():
		if l.num_display in level_data.levels:
			if level_data.levels[l.num_display][0] == 0:
				l.get_node("complete").set_hidden(true)
			else:
				l.get_node("complete").set_hidden(false)

func _on_b_newgame_pressed():
	global.menu_levels_showing = 1
	get_node("levels").set_hidden(false)

func _on_b_story_pressed():
	story_showing = 1
	get_node("story").set_hidden(false)

func _on_b_options_pressed():
	global.options.full_screen = not global.options.full_screen
	OS.set_window_fullscreen(global.options.full_screen)
	options_manager.write_options(global.options)
	if global.options.full_screen:
		get_node("CenterContainer/VBoxContainer/b_options").set_text("FULLSCREEN ON")
	else:
		get_node("CenterContainer/VBoxContainer/b_options").set_text("FULLSCREEN OFF")


func _on_b_quit_pressed():
	global.quit()


func _on_HomepageLink_pressed():
	OS.shell_open("http://noro.itch.io")


func _on_back_pressed():
	global.menu_levels_showing = 0
	story_showing = 0
	get_node("levels").set_hidden(true)
	get_node("story").set_hidden(true)


func _input(event):
	if (event.type==InputEvent.KEY):
		if event.scancode == KEY_ESCAPE:
			if event.pressed == true:
				if global.menu_levels_showing == 1 or story_showing == 1:
					_on_back_pressed()

