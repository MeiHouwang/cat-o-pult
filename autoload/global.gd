extends Node

var MAX_LEVELS = 10
var current_level_num = 1
var current_level = null
var game = null
var active_cat = null
var level_to_load = null
var catopult_armed = 0
var pause = 0
var dwarfs_to_catifize = 0

var options = {full_screen = TYPE_BOOL}
var menu_levels_showing = 0

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	options.full_screen = false
	randomize()


#SCENE MANAGEMENT
func new_game():
	mod_scener.fastload("res://game/game.tscn")


func load_level(lname):
	level_to_load = str("res://levels/", lname, ".tscn")
	if game == null:
		mod_scener.fastload("res://game/game.tscn")
	else:
		game.load_new_level_from(level_to_load)


func load_menu():
	mod_scener.fastload("res://menu/menu.tscn")
	
func quit():
	get_tree().quit()


func get_ground_tilemap():
	if current_level != null:
		return current_level.get_node("ground")

func get_things_tilemap():
	if current_level != null:
		return current_level.get_node("things")

func arm_catopult():
	if game != null:
		if game.cats > 0:
			game.catopult.arm_catopult()

func cat_launched(new_cat):
	active_cat = new_cat
	if game != null:
		game.cat_launched(new_cat)

func cat_finished():
	if game != null:
		game.cat_finish_job()


func get_left_limit():
	if game != null:
		return game.left_limit
	else:
		return 0

func get_right_limit():
	if game != null:
		return game.right_limit
	else:
		return 1920

func catifize_dwarf():
	var rndname1 = names.dwarf_names[randi() % names.dwarf_names.size()]
	var rndname2 = names.dwarf_names2[randi() % names.dwarf_names2.size()]
	var msg = str("Urist McCat, stray cat (tame) has adopted ",rndname1, " ", rndname2, ", macedwarf.")
	game.messaging.add_message(msg)
	dwarfs_to_catifize -= 1
	if dwarfs_to_catifize <= 0:
		game.win_level()

