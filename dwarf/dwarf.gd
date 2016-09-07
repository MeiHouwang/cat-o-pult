extends KinematicBody2D

var gravity = Vector2(0,200)
var catifized = 0
var ttime = 0
var moved = 0

func _ready():
	add_to_group("dwarves")
	get_node("AnimatedSprite").set_frame(0)
	catifized = 0
	set_fixed_process(true)


func _fixed_process(delta):
	if catifized:
		ttime += delta
		if ttime > 0.5 and not moved:
			get_node("AnimatedSprite").set_frame(1)
			get_node("AnimatedSprite").translate(Vector2(0, 8))
			get_node("love").set_hidden(false)
			moved = 1
		var a = sin(ttime*2) * 0.1
		get_node("AnimatedSprite").set_rot(a)
	else:
		move(gravity * delta)


func catifize():
	#print("Catifize!")
	get_node("puff").set_emitting(true)
	remove_child(get_node("collider"))
	remove_from_group("dwarves")
	catifized = 1
	ttime = 0
	global.catifize_dwarf()
