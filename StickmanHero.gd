class_name StickmanHero
extends StickmanCharacter

func _ready() -> void:
	pass

func process_input():
	self.input_move_vector = (Input.get_action_strength("move_right") - Input.get_action_strength("move_left"))
	self.input_jump_just_pressed = Input.is_action_just_pressed("jump")
	self.input_look_angle = (Input.get_action_strength("look_down") - Input.get_action_strength("look_up")) * 0.5
	self.input_fire_pressed = Input.is_action_pressed("fire")
	self.input_next_weapon_just_pressed = Input.is_action_just_pressed("ui_home")
	self.input_reload_just_pressed = Input.is_action_just_pressed("reload")
