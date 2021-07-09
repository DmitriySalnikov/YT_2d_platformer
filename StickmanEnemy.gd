class_name StickmanEnemy
extends StickmanCharacter

onready var enemy_detector := $EnemyDetector

var navmap : Navigation2D
var last_path : Array

func _ready() -> void:
	navmap = get_parent().get_node("Navigation2D")
	self.CurrentWeaponType = WeaponTypes.Gun

func process_input():
	_enemy_move()
	_enemy_weapon()
	
func _draw() -> void:
	for p in range(last_path.size()-1):
		var point : Vector2 = last_path[p]
		var point2 : Vector2 = last_path[p+1]
		draw_line(point - global_position, point2 - global_position, Color.red, 2)

func _on_UpdateNavTimer_timeout() -> void:
	last_path = navmap.get_simple_path(global_position, get_parent().get_node("StickmanHero").global_position)
	update()
	

func _enemy_move():
	var dir = 0.0
	if last_path.size() > 1:
		var vec : Vector2 = global_position - get_parent().get_node("StickmanHero").global_position
		if vec.length() > 200:
			var vec_to_point = last_path[1] - global_position
			if abs(vec_to_point.x) > 5:
				vec_to_point.y = 0
				dir = vec_to_point.normalized().x
	
	self.input_move_vector = dir
	self.input_jump_just_pressed = false

func _enemy_weapon():
	var hero = get_parent().get_node("StickmanHero")
	self.input_look_angle = (global_position - hero.global_position).angle() / 1.5708 - 0.785398
	#print((global_position - hero.global_position).angle())
	#print(self.input_look_angle)
	
	self.input_fire_pressed = false
	self.input_next_weapon_just_pressed = false
	self.input_reload_just_pressed = false
