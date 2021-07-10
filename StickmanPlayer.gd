class_name StickmanPlayer
extends StickmanCharacter

onready var weapon_ammo := $CanvasLayer/GUI/WeaponAmmo

func _ready() -> void:
	# warning-ignore:return_value_discarded
	connect("ammo_updated", self, "ui_weapon_ammo_update")
	
	ui_weapon_ammo_update(weapon_ammo_in_mag(current_weapon), weapon_ammo_total(current_weapon))

func process_input():
	self.input_move_vector = (Input.get_action_strength("move_right") - Input.get_action_strength("move_left"))
	self.input_jump_just_pressed = Input.is_action_just_pressed("jump")
	self.input_look_angle = (Input.get_action_strength("look_down") - Input.get_action_strength("look_up")) * 0.5
	self.input_fire_pressed = Input.is_action_pressed("fire")
	self.input_next_weapon_just_pressed = Input.is_action_just_pressed("ui_home")
	self.input_reload_just_pressed = Input.is_action_just_pressed("reload")

func ui_weapon_ammo_update(mag : int, total : int):
	weapon_ammo.text = "%s / %s" % [str(mag) if mag != -1 else "inf", str(total) if total != -1 else "inf"]
