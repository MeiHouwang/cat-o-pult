extends KinematicBody2D

var tilemap_ground = global.get_ground_tilemap()
var tilemap_things = global.get_things_tilemap()

var catstate = 0
var move_speed = Vector2(0,0)

var gravity = Vector2(0,2000)
var air_resist = 0.01

var bottom_object = null
var bottom_tile = null
var bottom_type = null
var bottom_line = null

var walk_object = null
var walk_tile = null
var walk_type = null
var walk_line = null

var spr
var anim
var ray_b
var ray_b_check
var ray_r
var ray_l
var ray_t
var ray_br
var ray_bl

const CAT_STATUS_AIRBORN = 0
const CAT_STATUS_LANDED_ON_GROUND = 1
const CAT_STATUS_LANDED_ON_WALL = 2
const CAT_STATUS_WALKING = 3
const CAT_STATUS_STOPPING = 4
const CAT_STATUS_STOP = 5
const CAT_STATUS_JUMPING = 6
const CAT_STATUS_CLIMBING = 7
const CAT_STATUS_CLIMBING_ON_TOP = 8
const CAT_STATUS_READY_TO_JUMP_DOWN = 9
const CAT_STATUS_JUMPING_DOWN = 10
const CAT_STATUS_SLIDING = 11

var cat_move_direction = Vector2(1.0,0)
var walk_speed = 250
var climb_speed = 100
var action_time = 0
var jump_target_type = 0
var climb_from_left = 0
var climb_finish = 0
var slide_finish = 0
var move_left = 0

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	catstate = CAT_STATUS_AIRBORN
	anim = get_node("AnimationPlayer")
	anim.play("spin")
	get_node("flight_trace").set_hidden(false)
	set_process(true)
	set_fixed_process(true)
	spr = get_node("sprite")
	ray_b = get_node("ray_bottom")
	ray_r = get_node("ray_right")
	ray_l = get_node("ray_left")
	ray_t = get_node("ray_top")
	ray_br = get_node("ray_br")
	ray_bl = get_node("ray_bl")
	ray_b_check = get_node("ray_bottom_check")

func _exit_tree():
	global.cat_finished()

func _process(delta):
	if catstate == CAT_STATUS_LANDED_ON_GROUND:
		# fall on the ground
		spr.set_frame(1)
		spr.set_rot(0)
		if bottom_object.get_name() == "ground":
			bottom_line = bottom_object.get_global_pos().y + bottom_tile.y * 64 - 60
			var pos = get_global_pos()
			pos.y = bottom_line
			set_global_pos(pos)
			catstate = CAT_STATUS_WALKING
			anim.play("walk")
		elif bottom_object.get_name() == "things":
			bottom_line = bottom_object.get_global_pos().y + bottom_tile.y * 64 - 64
			var pos = get_global_pos()
			pos.y = bottom_line
			set_global_pos(pos)
			catstate = CAT_STATUS_WALKING
			anim.play("walk")
		action_time = 0
	var pos = get_global_pos()
	if pos.x < global.get_left_limit():
		queue_free()
	if pos.x > global.get_right_limit():
		queue_free()


func _fixed_process(delta):
	action_time += delta
	if catstate == CAT_STATUS_AIRBORN:
		move_speed += gravity*delta - move_speed*air_resist
		var move_vector = move_speed * delta
		var ang = Vector2(0,0).angle_to_point(move_vector)
		if (ang < 0):
			ang += 2 * PI
		ang = 360 * ang / (2 * PI)
		#print (ang)
		get_node("flight_trace").set_param(10, ang)
		move(move_vector)
		if ray_r.is_colliding():
			# Strike wall
			walk_object = ray_r.get_collider()
			if walk_object.get_name() == "things":
				get_node("flight_trace").set_hidden(true)
				get_node("flight_trace").set_emitting(false)
				anim.stop(true)
				walk_tile = walk_object.world_to_map(ray_r.get_collision_point())
				walk_type = get_tile_at_position(walk_object, walk_tile)
				spr.set_rot(0)
				if walk_type == 0:
					# Wood wall
					catstate = CAT_STATUS_CLIMBING
					climb_from_left = 1
					var pos = get_global_pos()
					pos.x = walk_object.get_global_pos().x + walk_tile.x * 64
					set_global_pos(pos)
					cat_move_direction = Vector2(0, -1)
					anim.play("climb")
					add_dwarf_exceptions()
				else:
					# Stone wall
					catstate = CAT_STATUS_SLIDING
					spr.set_frame(6)
					climb_from_left = 1
					var pos = get_global_pos()
					pos.x = walk_object.get_global_pos().x + walk_tile.x * 64
					if walk_type == 4 or walk_type == 5 or walk_type == 6:
						pos.x += 16
					set_global_pos(pos)
					move_speed = Vector2(0, 0)
					slide_finish = 0
			else:
				# Direct hit
				if walk_object.has_method("catifize"):
					if walk_object.catifized == 0:
						walk_object.catifize()
						queue_free()
		if ray_b.is_colliding():
			# Landing
			bottom_object = ray_b.get_collider()
			anim.stop(true)
			get_node("flight_trace").set_hidden(true)
			get_node("flight_trace").set_emitting(false)
			catstate = CAT_STATUS_LANDED_ON_GROUND
			if bottom_object.get_type() == "TileMap":
				bottom_tile = bottom_object.world_to_map(ray_b.get_collision_point())
				bottom_type = get_tile_at_position(bottom_object, bottom_tile)
				#print(bottom_type)
			elif bottom_object.has_method("catifize"):
				if bottom_object.catifized == 0:
					bottom_object.catifize()
					queue_free()
	elif catstate == CAT_STATUS_STOPPING:
		if action_time < 0.1:
			move(cat_move_direction * walk_speed * delta)
		else:
			catstate = CAT_STATUS_STOP
			anim.play("sit_down")
			global.cat_finished()
	elif catstate == CAT_STATUS_WALKING:
		if action_time > 0.1:
			move(cat_move_direction * walk_speed * delta)
			var ray_check = null
			if cat_move_direction.x > 0:
				ray_check = ray_r
			else:
				ray_check = ray_l
			# Obstacles
			if ray_check.is_colliding():
				walk_object = ray_check.get_collider()
				if walk_object.get_name() == "things":
					walk_tile = walk_object.world_to_map(ray_check.get_collision_point())
					walk_type = get_tile_at_position(walk_object, walk_tile)
					if walk_type == 0:
						# wood
						catstate = CAT_STATUS_JUMPING
						jump_target_type = 0
						if cat_move_direction.x > 0:
							walk_line = walk_object.get_global_pos().x + walk_tile.x * 64 - 20
						else:
							walk_line = walk_object.get_global_pos().x + walk_tile.x * 64 + 64
						anim.play("jump")
					if walk_type == 1 or walk_type == 4:
						# walls
						catstate = CAT_STATUS_STOPPING
						action_time = 0
						anim.play("sit_down")
				elif walk_object.has_method("catifize"):
					if walk_object.catifized == 0:
						catstate = CAT_STATUS_JUMPING
						jump_target_type = 1
						if cat_move_direction.x > 0:
							walk_line = walk_object.get_global_pos().x - 40
						else:
							walk_line = walk_object.get_global_pos().x + 40
						anim.play("jump")
			# Edges
			if cat_move_direction.x > 0:
				ray_check = ray_br
			else:
				ray_check = ray_bl
			if not ray_check.is_colliding():
				# Edge is ahead
				catstate = CAT_STATUS_READY_TO_JUMP_DOWN
				bottom_object = ray_b.get_collider()
				bottom_tile = bottom_object.world_to_map(ray_b.get_collision_point())
				if cat_move_direction.x > 0:
					walk_line = bottom_object.get_global_pos().x + bottom_tile.x * 64 + 128
				else:
					walk_line = bottom_object.get_global_pos().x + bottom_tile.x * 64
	elif catstate == CAT_STATUS_JUMPING:
		move(cat_move_direction * walk_speed * delta)
		var pos = get_global_pos()
		if move_left:
			if pos.x < walk_line:
				if jump_target_type == 0:
					# Climbing
					catstate = CAT_STATUS_CLIMBING
					climb_from_left = 0
					pos.x = walk_object.get_global_pos().x + walk_tile.x * 64 + 64
					pos.y += spr.get_pos().y
					set_global_pos(pos)
					cat_move_direction = Vector2(0, -1)
					anim.play("climb")
					add_dwarf_exceptions()
				elif jump_target_type == 1:
					walk_object.catifize()
					queue_free()
		else:
			if pos.x > walk_line:
				if jump_target_type == 0:
					# Climbing
					catstate = CAT_STATUS_CLIMBING
					climb_from_left = 1
					pos.x = walk_object.get_global_pos().x + walk_tile.x * 64
					pos.y += spr.get_pos().y
					set_global_pos(pos)
					cat_move_direction = Vector2(0, -1)
					anim.play("climb")
					add_dwarf_exceptions()
				elif jump_target_type == 1:
					walk_object.catifize()
					queue_free()
	elif catstate == CAT_STATUS_CLIMBING:
		move(cat_move_direction * climb_speed * delta)
		var up_free = false
		if ray_t.is_colliding():
			var top_object = ray_t.get_collider()
			if top_object.get_name() != "things":
				up_free = true
		else:
			up_free = true
		if up_free:
			# Climb on top
			if climb_from_left:
				bottom_object = ray_r.get_collider()
				bottom_tile = bottom_object.world_to_map(ray_r.get_collision_point())
			else:
				bottom_object = ray_l.get_collider()
				bottom_tile = bottom_object.world_to_map(ray_l.get_collision_point())
			bottom_type = get_tile_at_position(bottom_object, bottom_tile)
			bottom_line = bottom_object.get_global_pos().y + bottom_tile.y * 64 - 64
			climb_finish = 0
			spr.set_pos(Vector2(0,0))
			catstate = CAT_STATUS_CLIMBING_ON_TOP
	elif catstate == CAT_STATUS_CLIMBING_ON_TOP:
		if climb_finish:
			if action_time > 0.3:
				spr.set_pos(Vector2(0,0))
				action_time = 0
				var pos = get_global_pos()
				pos.y = bottom_line
				set_global_pos(pos)
				catstate = CAT_STATUS_WALKING
				if (climb_from_left):
					cat_move_direction = Vector2(1, 0)
				else:
					cat_move_direction = Vector2(-1, 0)
				anim.play("walk")
				remove_dwarf_exceptions()
		else:
			move(cat_move_direction * climb_speed * delta)
			var pos = get_global_pos()
			if pos.y <= (bottom_line + 80):
				pos.y = bottom_line + 80
				set_global_pos(pos)
				anim.play("climb_on_top")
				action_time = 0
				climb_finish = 1
	elif catstate == CAT_STATUS_READY_TO_JUMP_DOWN:
		move(cat_move_direction * walk_speed * delta)
		var pos = get_global_pos()
		if move_left:
			if pos.x < walk_line:
				catstate = CAT_STATUS_JUMPING_DOWN
				pos.y += 64
				set_global_pos(pos)
				move_speed = Vector2(-300, 300)
				action_time = 0
				anim.play("jump_down")
		else:
			if pos.x > walk_line:
				catstate = CAT_STATUS_JUMPING_DOWN
				pos.y += 64
				set_global_pos(pos)
				move_speed = Vector2(300, 300)
				action_time = 0
				anim.play("jump_down")
	elif catstate == CAT_STATUS_JUMPING_DOWN:
		if action_time > 0.2:
			move_speed += gravity*delta - move_speed*air_resist
			var move_vector = move_speed * delta
			move(move_vector)
			if action_time > 0.3 and ray_b_check.is_colliding():
				bottom_object = ray_b_check.get_collider()
				anim.stop(true)
				if bottom_object.get_type() == "TileMap":
					catstate = CAT_STATUS_LANDED_ON_GROUND
					bottom_tile = bottom_object.world_to_map(ray_b_check.get_collision_point())
					bottom_type = get_tile_at_position(bottom_object, bottom_tile)
					#bottom_type = bottom_object.get_cellv(bottom_tile)
					#print(bottom_type)
				elif bottom_object.has_method("catifize"):
					if bottom_object.catifized == 0:
						bottom_object.catifize()
						queue_free()
			var ray_check = null
			if cat_move_direction.x > 0:
				ray_check = ray_r
			else:
				ray_check = ray_l
			if action_time > 0.4 and ray_check.is_colliding():
				# Strike wall
				walk_object = ray_check.get_collider()
				if walk_object.get_name() == "things":
					walk_tile = walk_object.world_to_map(ray_r.get_collision_point())
					walk_type = get_tile_at_position(walk_object, walk_tile)
					if walk_type == 0:
						# Wood wall
						catstate = CAT_STATUS_CLIMBING
						climb_from_left = 1
						var pos = get_global_pos()
						pos.x = walk_object.get_global_pos().x + walk_tile.x * 64
						set_global_pos(pos)
						cat_move_direction = Vector2(0, -1)
						anim.play("climb")
						add_dwarf_exceptions()
					else:
						# Stone wall
						catstate = CAT_STATUS_SLIDING
						spr.set_frame(6)
						climb_from_left = 1
						var pos = get_global_pos()
						pos.x = walk_object.get_global_pos().x + walk_tile.x * 64
						if walk_type == 4 or walk_type == 5 or walk_type == 6:
							pos.x += 16
						set_global_pos(pos)
						move_speed = Vector2(0, 0)
						slide_finish = 0
				else:
					# Direct hit
					if walk_object.has_method("catifize"):
						if walk_object.catifized == 0:
							walk_object.catifize()
							queue_free()
	elif catstate == CAT_STATUS_SLIDING:
		move_speed += gravity*delta*0.2
		var move_vector = move_speed * delta
		move(move_vector)
		if slide_finish:
			var pos = get_global_pos()
			if pos.y > bottom_line:
				pos.y = bottom_line
				pos.x -= 32
				set_global_pos(pos)
				#catstate = CAT_STATUS_STOPPING
				catstate = CAT_STATUS_WALKING
				anim.play("walk")
				cat_move_direction = Vector2(-1,0)
				move_left = 1
				spr.set_scale(Vector2(-1,1))
		else:
			if ray_bl.is_colliding():
				bottom_object = ray_bl.get_collider()
				if bottom_object.get_type() == "TileMap":
					bottom_tile = bottom_object.world_to_map(ray_bl.get_collision_point())
					bottom_type = get_tile_at_position(bottom_object, bottom_tile)
					slide_finish = 1
					if bottom_object.get_name() == "ground":
						bottom_line = bottom_object.get_global_pos().y + bottom_tile.y * 64 - 60
					else:
						bottom_line = bottom_object.get_global_pos().y + bottom_tile.y * 64 - 64
					#print("global pos", get_global_pos())
					#print("bottom line", bottom_line)
					#print(bottom_object.get_name())
					#print (bottom_tile)
					#print("tilemap pos: ", bottom_object.get_global_pos())
					#print("tile offset: ", bottom_tile*64)

func get_tile_at_position(tilemap_object, tile_position):
	if tilemap_object.get_type() == "TileMap":
		var tpos = tile_position
		var result = tilemap_object.get_cellv(tpos)
		if result == -1:
			tpos = tile_position
			tpos.x += -1
			result = tilemap_object.get_cellv(tpos)
		if result == -1:
			tpos = tile_position
			tpos.y += -1
			result = tilemap_object.get_cellv(tpos)
		if result == -1:
			tpos = tile_position
			tpos.x += -1
			tpos.y += -1
			result = tilemap_object.get_cellv(tpos)
		if result == -1:
			tpos = tile_position
			tpos.x -= 2
			tpos.y -= 1
			result = tilemap_object.get_cellv(tpos)
		if result == -1:
			tpos = tile_position
			tpos.y -= 2
			result = tilemap_object.get_cellv(tpos)
		if result == -1:
			tpos = tile_position
			tpos.x -= 1
			tpos.y -= 2
			result = tilemap_object.get_cellv(tpos)
		return result
	else:
		return null


func add_dwarf_exceptions():
	for dwarf in get_tree().get_nodes_in_group("dwarves"):
		ray_t.add_exception(dwarf)
		ray_r.add_exception(dwarf)
		ray_l.add_exception(dwarf)

func remove_dwarf_exceptions():
	ray_t.clear_exceptions()
	ray_r.clear_exceptions()
	ray_l.clear_exceptions()
