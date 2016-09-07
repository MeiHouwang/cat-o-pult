extends Control

func _ready():
	set_process_input(true)


func _input(event):
	if (event.type==InputEvent.KEY):
		if event.scancode == KEY_ESCAPE:
			if event.pressed == true:
				if global.pause == 2:
					global.pause = 3
					get_parent().get_node("cm").set_hidden(true)
					get_parent().get_node("pause_ui/cont").set_hidden(true)
					get_tree().set_pause(false)
			else:
				if global.pause == 1:
					global.pause = 2
