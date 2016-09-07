extends Control

var label = null

var message = ""
var message_status = 0
var message_time = 0
var message_pos = null

func _ready():
	label = get_node("Label")
	label.set_text(message)
	set_process(true)

func _process(delta):
	message_time += delta
	if message_status == 1:
		if message_time > 2:
			message_time = 0
			message_status = 2
	elif message_status == 2:
		if message_time > 1:
			message_status = 0
		message_pos.y = 16 - message_time * 32
		label.set_pos(message_pos)

func add_message(t):
	label.set_text(t)
	message_pos = Vector2(0, 16)
	label.set_pos(message_pos)
	message_time = 0
	message_status = 1
