extends Node

var levels = {}

func save_level_data():
	var f = File.new()
	var err = f.open("user://levels.data",File.WRITE)
	f.store_var(levels)
	f.close()

func load_level_data():
	var f = File.new()
	if(f.file_exists("user://levels.data")):
		var err = f.open("user://levels.data",File.READ)
		levels = f.get_var()
		f.close()


func set_complete(n):
	for l in levels:
		if int(l) == n:
			levels[l][0] = 1
	save_level_data()

