class_name StickmanPlayer
extends StickmanCharacter

onready var weapon_ammo := $CanvasLayer/GUI/WeaponAmmo

func _ready() -> void:
	# warning-ignore:return_value_discarded
	connect("ammo_updated", self, "ui_weapon_ammo_update")
	
	ui_weapon_ammo_update(weapon_ammo_in_mag(current_weapon), weapon_ammo_total(current_weapon))
	enable_onfloor_manual_rotation = true

func process_input():
	self.input_move_direction = (Input.get_action_strength("move_right") - Input.get_action_strength("move_left"))
	self.input_look_direction = (Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))
	self.input_jump_just_pressed = Input.is_action_just_pressed("jump")
	self.input_look_angle = (Input.get_action_strength("look_down") - Input.get_action_strength("look_up")) * 0.5
	self.input_fire_pressed = Input.is_action_pressed("fire")
	self.input_next_weapon_just_pressed = Input.is_action_just_pressed("ui_home")
	self.input_reload_just_pressed = Input.is_action_just_pressed("reload")
	self.input_interact_just_pressed = Input.is_action_just_pressed("interact")
	
	var player_pos : Vector2 = get_global_mouse_position()
	var weapon_pos : Vector2 = global_position if current_weapon == null or CurrentWeaponType == WeaponTypes.None else weapon_wall_detector.global_position
	var dist = weapon_pos.x - player_pos.x
	
	# fix for convulsive turns when the mouse is close to the character
	if dist < 5.0 and dist > -5.0:
		weapon_pos.x = global_position.x + 1.0
	
	if player_pos.x > weapon_pos.x:
		self.input_look_angle = (player_pos - weapon_pos).angle() / 1.5708
		if is_can_manually_rotate():
			rotate_character(true)
	else:
		self.input_look_angle = ((weapon_pos - player_pos) * Vector2(1, -1)).angle() / 1.5708
		if is_can_manually_rotate():
			rotate_character(false)

func ui_weapon_ammo_update(mag : int, total : int):
	weapon_ammo.text = "%s / %s" % [str(mag) if mag != -1 else "inf", str(total) if total != -1 else "inf"]
