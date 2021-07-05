extends Node2D

enum EGroundMove { idle, run }
const ground_move_name := "parameters/ground_move/current"
var GroundMove := 0 setget set_ground_move, get_ground_move

enum ESpaceStateWeapon { ground, air }
const space_state_weapon_name := "parameters/space_state_weapon/current"
var SpaceStateWeapon := 0 setget set_space_state_weapon, get_space_state_weapon

enum ESpaceState { weapon, wall }
const space_state_name := "parameters/space_state/current"
var SpaceState := 0 setget set_space_state, get_space_state

enum EInAirState { jump, fall }
const in_air_state_name := "parameters/in_air_state/current"
var InAirState := 0 setget set_in_air_state, get_in_air_state

const has_gun_name := "parameters/has_gun/add_amount"
const idle_blend_name := "parameters/idle_blend/blend_position"
const run_blend_name := "parameters/run_blend/blend_position"
const jump_blend_name := "parameters/jump_blend/blend_position"
const fall_blend_name := "parameters/fall_blend/blend_position"
var HasGun := false setget set_has_gun, get_has_gun

const aim_blend_name := "parameters/aim_blend/blend_position"
var AimBlend := 0.5 setget set_aim_blend, get_aim_blend

var MustHolsterWeapon := false setget set_must_holster_weapon

onready var has_gun_tween := $HasGunAnim
onready var anim_tree := $Root/AnimationTree
onready var weapon_pos_back := $Root/Spine1/Spine2/Spine3/WeaponBackPos
onready var weapon_pos := $Root/ArmRight/ARBottom/WeaponPos

func _ready() -> void:
	set_has_gun(false)
	anim_tree.active = true
	
	#force reset
	set_has_gun(false, true)

# ground_move
func set_ground_move(val : int):
	anim_tree.set(ground_move_name, val)

func get_ground_move() -> int:
	return anim_tree.get(ground_move_name)

# space_state
func set_space_state_weapon(val : int):
	anim_tree.set(space_state_weapon_name, val)

func get_space_state_weapon() -> int:
	return anim_tree.get(space_state_weapon_name)

# space_state
func set_space_state(val : int):
	anim_tree.set(space_state_name, val)

func get_space_state() -> int:
	return anim_tree.get(space_state_name)

# in_air_state
func set_in_air_state(val : int):
	anim_tree.set(in_air_state_name, val)

func get_in_air_state() -> int:
	return anim_tree.get(in_air_state_name)

# has_gun
func set_has_gun(val : bool, force := false):
	if HasGun != val or force:
		HasGun = val
		update_weapon_anims(val)

func update_weapon_anims(val : bool):
	remote_transform_update(weapon_pos, val)
	remote_transform_update(weapon_pos_back, !val)
	
	start_has_gun_anim(val)
	
	var b = int(val)
	anim_tree.set(idle_blend_name, b)
	anim_tree.set(run_blend_name, b)
	anim_tree.set(jump_blend_name, b)
	anim_tree.set(fall_blend_name, b)

func start_has_gun_anim(val : bool):
	has_gun_tween.interpolate_property(anim_tree, has_gun_name, anim_tree.get(has_gun_name), float(val), 0.08)
	has_gun_tween.start()

func remote_transform_update(rt : RemoteTransform2D, val : bool):
	rt.update_position = val
	rt.update_rotation = val
	rt.update_scale = val

func get_has_gun() -> bool:
	return anim_tree.get(has_gun_name)

# aim_blend
func set_aim_blend(val : float):
	anim_tree.set(aim_blend_name, val)

func get_aim_blend() -> float:
	return anim_tree.get(aim_blend_name)

func set_must_holster_weapon(val : bool):
	MustHolsterWeapon = val
	
	if MustHolsterWeapon:
		update_weapon_anims(false)
	else:
		update_weapon_anims(HasGun)
