extends TextureButton

export var level = ""
export var num_display = "01"

func _ready():
	get_node("num").set_text(num_display)

func set_num(n):
	get_node("num").set_text(str(n))



func _on_level_button_pressed():
	global.current_level_num = int(num_display)
	global.load_level(level)
