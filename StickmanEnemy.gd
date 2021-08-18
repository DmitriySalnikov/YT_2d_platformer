class_name StickmanEnemy
extends StickmanCharacter

onready var enemy_detector := $EnemyDetector
onready var next_floor_platform_checker := $Rays/NextPlatformFloorChecker

var navmap : Navigation2D
var last_path : Array

# TODO add jump tries counter and limiter

func _ready() -> void:
	navmap = get_parent().get_node("Navigation2D")
	self.CurrentWeaponType = WeaponTypes.Gun

func process_input():
	_enemy_move()
	_enemy_jump()
	_enemy_weapon()

func _draw() -> void:
	for p in range(last_path.size()-1):
		var point : Vector2 = last_path[p]
		var point2 : Vector2 = last_path[p+1]
		draw_line(point - global_position, point2 - global_position, Color.red, 2)

func _on_UpdateNavTimer_timeout() -> void:
	if health_comp.is_alive():
		last_path = navmap.get_simple_path(global_position, get_parent().get_node("StickmanPlayer").global_position)
	else:
		last_path = []
	update()

func on_dead_virtual():
	set_collision_layer_bit(ENEMIES_LAYER_BIT, false)
	set_collision_mask_bit(ENEMIES_LAYER_BIT, false)

func on_resurrected_virtual():
	set_collision_layer_bit(ENEMIES_LAYER_BIT, true)
	set_collision_mask_bit(ENEMIES_LAYER_BIT, true)

func _enemy_move():
	self.input_look_direction = 0
	
	var dir = 0.0
	# if path not empty
	if last_path.size() > 1:
		var vec : Vector2 = global_position - get_parent().get_node("StickmanPlayer").global_position
		if vec.length() > 200:
			var vec_to_point = last_path[1] - global_position
			# if heights not equal and distance greater 200
			if abs(vec_to_point.x) > 5:
				vec_to_point.y = 0
				dir = vec_to_point.normalized().x
	
	self.input_move_direction = dir

func _enemy_jump():
	var need_to_jump = false
	#not empty
	if last_path.size() > 1:
		# if need to jump up. Check distance from center to second point
		if (last_path[1] - last_path[0]).y < -100 and (next_floor_platform_checker.is_colliding() and not enemy_detector.is_colliding()):
			need_to_jump = true
		else:
			var height_delta = 0
			# if need to jump down through platform. Check distance from capsule top to second point but only when he's far from player
			if last_path.size() != 2:
				height_delta = (last_path[1] - Vector2(global_position.x, global_position.y - capsule_collison.shape.height + capsule_collison.shape.radius)).y
			else:
				height_delta = (last_path[1] - last_path[0]).y
			
			if height_delta > 0 and two_way_platform_checker.is_colliding():
				self.input_look_direction = 1
				need_to_jump = true
	
	self.input_jump_just_pressed = need_to_jump

func _enemy_weapon():
	var player = get_parent().get_node("StickmanPlayer")
	var player_pos : Vector2 = player.global_position
	var weapon_pos : Vector2 = global_position
	
	if player_pos.x > weapon_pos.x:
		self.input_look_angle = (player_pos - weapon_pos).angle() / 1.5708
		rotate_character(true)
	else:
		rotate_character(false)
		self.input_look_angle = ((weapon_pos - player_pos) * Vector2(1, -1)).angle() / 1.5708
	
	_update_player_detector(player)
	self.input_fire_pressed = enemy_detector.is_colliding() and enemy_detector.get_collider() is StickmanPlayer and enemy_detector.get_collider().health_comp.is_alive()
	self.input_next_weapon_just_pressed = false
	self.input_reload_just_pressed = false

func _update_player_detector(player : Node2D):
	var player_pos : Vector2 = player.global_position
	enemy_detector.cast_to = player_pos - enemy_detector.global_position
	enemy_detector.force_raycast_update()
