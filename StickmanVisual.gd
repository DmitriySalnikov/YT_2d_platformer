tool
extends Node2D

# warning-ignore-all:unused_signal
signal weapon_drop_mag
signal weapon_create_mag
signal weapon_attach_mag
signal weapon_reload_started
signal weapon_reload_finished

export var TintColor := Color.white setget set_stickman_tint
export var TintGrayCurve : Curve

export var WeaponSlotPath : NodePath
onready var WeaponSlot : Node2D = null

export var WeaponWallDetectorPath : NodePath
onready var WeaponWallDetector : Node2D = null

enum EIsAliveState { alive, dead }
const is_alive_name := "parameters/is_alive/current"
var IsAlive := 0 setget set_is_alive, get_is_alive

enum EGroundMove { idle, run }
const ground_move_name := "parameters/ground_move/blend_amount"
var GroundMove := 0.0 setget set_ground_move, get_ground_move

const run_timescale_name := "parameters/run_timescale/scale"
var RunTimescale := 0.0 setget set_run_timescale, get_run_timescale

enum ESpaceStateWeapon { ground, air }
const space_state_weapon_name := "parameters/space_state_weapon/current"
var SpaceStateWeapon := 0 setget set_space_state_weapon, get_space_state_weapon

enum ESpaceState { weapon, wall }
const space_state_name := "parameters/space_state/current"
var SpaceState := 0 setget set_space_state, get_space_state

enum EInAirState { jump, fall }
const in_air_state_name := "parameters/in_air_state/current"
var InAirState := 0 setget set_in_air_state, get_in_air_state

const weapon_reload_name := "parameters/weapon_reload/active"
var WeaponReload := false setget set_weapon_reload, get_weapon_reload

const has_gun_name := "parameters/has_gun/add_amount"
const idle_blend_name := "parameters/idle_blend/blend_position"
const run_blend_name := "parameters/run_blend/blend_position"
const jump_blend_name := "parameters/jump_blend/blend_position"
const fall_blend_name := "parameters/fall_blend/blend_position"
var HasGun := false setget set_has_gun, get_has_gun
var has_gun_anim_state := HasGun

const aim_blend_name := "parameters/aim_blend/blend_position"
var AimBlend := 0.5 setget set_aim_blend, get_aim_blend

var MustHolsterWeapon := false setget set_must_holster_weapon

onready var anim_smoother := $AnimSmoother
onready var has_gun_tween := $HasGunAnim
onready var root_obj := $Root
onready var anim_tree := $Root/AnimationTree
onready var weapon_wall_detector_pos := $Root/Spine1/Spine2/Spine3/ArmsWeaponWallDetectorPos
onready var weapon_pos_back := $Root/Spine1/Spine2/Spine3/WeaponBackPos
onready var weapon_pos := $Root/ArmRight/ARBottom/WeaponPos
onready var weapon_trans_pos := $Root/WeaponTransitionPos
onready var ammo_pos := $Root/ArmLeft/ALBottom/AmmoPos
var weapon_transition_start_transform : Transform2D
var weapon_transition_end_rt : RemoteTransform2D

func _ready() -> void:
	if not get_parent() is Viewport:
		anim_tree.active = true
		
		WeaponSlot = get_node(WeaponSlotPath)
		WeaponWallDetector = get_node(WeaponWallDetectorPath)
		
		weapon_wall_detector_pos.remote_path = weapon_wall_detector_pos.get_path_to(WeaponWallDetector)
		weapon_pos.remote_path = weapon_pos.get_path_to(WeaponSlot)
		weapon_pos_back.remote_path = weapon_pos_back.get_path_to(WeaponSlot)
		weapon_trans_pos.remote_path = weapon_trans_pos.get_path_to(WeaponSlot)
		
		update_stickman_color()
		#force reset
		set_has_gun(false, true)

# is_alive
func set_is_alive(val : int):
	anim_tree.set(is_alive_name, val)

func get_is_alive() -> int:
	return anim_tree.get(is_alive_name)

# tint
func set_stickman_tint(val : Color):
	TintColor = val
	update_stickman_color()

func update_stickman_color():
	if $Root/ArmRight:
		var full_tint = [$Root/ArmRight, $Root/LegRight, $Root/Spine1]
		var grayed_tint = [$Root/ArmLeft, $Root/LegLeft]
		
		for l in full_tint:
			l.modulate = TintColor
		
		var grayed = TintColor
		grayed.v = TintGrayCurve.interpolate(grayed.v)
		
		for l in grayed_tint:
			l.modulate = grayed

# ground_move
func set_ground_move(val : float):
	#anim_tree.set(ground_move_name, val)
	anim_smoother.interpolate_property(anim_tree, ground_move_name, get_ground_move(), val, 0.15)
	anim_smoother.start()

func get_ground_move() -> float:
	return anim_tree.get(ground_move_name)

# run_timescale
func set_run_timescale(val : float):
	anim_tree.set(run_timescale_name, val)

func get_run_timescale() -> float:
	return anim_tree.get(run_timescale_name)

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

# in_air_state
func set_weapon_reload(val : bool):
	anim_tree.set(weapon_reload_name, val)

func get_weapon_reload() -> bool:
	return anim_tree.get(weapon_reload_name)

# has_gun
func set_has_gun(val : bool, force := false):
	if HasGun != val or force:
		if force:
			has_gun_anim_state = !val
		HasGun = val
		update_weapon_anims(false if MustHolsterWeapon else val)

func update_weapon_anims(val : bool):
	if has_gun_anim_state != val:
		has_gun_anim_state = val
		
		start_has_gun_anim(val)
		
		var b = int(val)
		anim_tree.set(idle_blend_name, b)
		anim_tree.set(run_blend_name, b)
		anim_tree.set(jump_blend_name, b)
		anim_tree.set(fall_blend_name, b)

func start_has_gun_anim(val : bool):
	var anim_time = 0.08
	var half_anim_time = anim_time / 2.0
	has_gun_tween.remove_all()
	# disable and correctly enable remote transforms
	has_gun_tween.interpolate_callback(self, half_anim_time, "remote_transform_update", weapon_pos, false)
	has_gun_tween.interpolate_callback(self, half_anim_time, "remote_transform_update", weapon_pos_back, false)
	has_gun_tween.interpolate_callback(self, half_anim_time, "remote_transform_update", weapon_trans_pos, true)
	has_gun_tween.interpolate_callback(self, anim_time, "remote_transform_update", weapon_pos, val)
	has_gun_tween.interpolate_callback(self, anim_time, "remote_transform_update", weapon_pos_back, !val)
	has_gun_tween.interpolate_callback(self, anim_time, "remote_transform_update", weapon_trans_pos, false)
	# smooth weapon transition
	has_gun_tween.interpolate_callback(self, half_anim_time, "weapon_save_transform")
	has_gun_tween.interpolate_method(self, "weapon_transition", 0.0, 1.0, half_anim_time, 0, 2, half_anim_time)
	# smooth blend of animations
	has_gun_tween.interpolate_property(anim_tree, has_gun_name, anim_tree.get(has_gun_name), float(val), anim_time)
	has_gun_tween.start()

func weapon_save_transform():
	if WeaponSlot:
		weapon_transition_end_rt = (weapon_pos if HasGun else weapon_pos_back)
		weapon_trans_pos.global_transform = WeaponSlot.global_transform
		weapon_transition_start_transform = weapon_trans_pos.transform

func weapon_transition(lerp_power : float):
	if not weapon_transition_end_rt:
		return
	weapon_trans_pos.transform = weapon_transition_start_transform.interpolate_with(weapon_transition_end_rt.get_relative_transform_to_parent(root_obj), lerp_power)

func remote_transform_update(rt : RemoteTransform2D, val : bool):
	rt.update_position = val
	rt.update_rotation = val
	rt.update_scale = val

func attach_ammo_to_hand(ammo):
	ammo_pos.remote_path = ammo_pos.get_path_to(ammo)

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
