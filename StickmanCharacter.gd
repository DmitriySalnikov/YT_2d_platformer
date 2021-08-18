class_name StickmanCharacter
extends KinematicBody2D

signal ammo_updated(in_mag, total)

enum WeaponTypes{
	None,
	Gun
}

const ENEMIES_LAYER_BIT = 10
const TWOWAY_PlATFORMS_LAYER_BIT = 2

export var StickmanScale := Vector2(3, 3)
export var MoveAcceleration := 0.25
export var MoveAccelerationInAir := 0.100
export var MoveDeacceleration := 0.5
export var MoveDeaccelerationInAir := 0.05

export(float, 0, 9800) var GRAVITY := 100.0
export(float, 0, 9800) var MaxGravitySpeed := 1000.0
export(float, 0, 9800) var MaxGravitySpeedOnWallScale := 0.5
export(float, 0, 3000) var MaxGroundSpeed := 500.0
export(float, 0, 3000) var GroundSpeedNormalAnimScale := 400.0
export(float, 0, 1) var JumpCoyoteTime := 0.1
export(float, 0.001, 1) var JumpDefferedTime := 0.1
export(float, 0, 25000) var JumpStrength := 1300.0
export(float, 0, 10) var WallJumpManualRotationBlockTime := 0.25
export(Curve) var OnWallGravityCurve : Curve
export var OnWallStillHoldingTime := 1.8
export var CurrentWeaponType : int = WeaponTypes.Gun setget set_current_weapon

onready var health_comp := $HealthComp
onready var stickman_visual := $StickmanVisual
onready var capsule_collison := $CS2D
onready var slope_ray_collision := $CSSlopeRay
onready var rays := $Rays

onready var weapon_slot := $WeaponSlot
onready var weapon_wall_detector := $Rays/WeaponWallDetector
onready var current_weapon : Node2D = null
onready var weapons_map := {
	WeaponTypes.None : null,
	WeaponTypes.Gun : $WeaponSlot/Gun,
}

onready var wall_detectors_root := $Rays/WallDetectors
onready var two_way_platform_checker := $Rays/TwoWayPlatformChecker
onready var tween := $Tween

var input_move_direction : float
var input_look_direction : float
var input_jump_just_pressed : bool
var input_look_angle : float
var input_fire_pressed : bool
var input_next_weapon_just_pressed : bool
var input_reload_just_pressed : bool
var enable_onfloor_manual_rotation : bool = false

var prev_position := Vector2()
var total_covered_distance := 0.0

var snap_to_ground := false
var is_on_floor_coyote := false
var jump_coyote_timer := 0.0
var jump_deffered_timer := 0.0
var is_jumping_through_platforms := false
var jump_down_platform_distance_vertical := 0.0

var is_can_use_weapon := true
var velocity := Vector2()
var is_facing_right := true
var is_facing_right_sign := 1

var is_holding_on_wall := false
var wall_detectors := []
var wall_holding_timer := 0.0
var wall_jump_manual_rotation_timer := 0.0

func _ready() -> void:
	for c in wall_detectors_root.get_children():
		if c is RayCast2D:
			c.add_exception(self)
			wall_detectors.append(c)
	weapon_wall_detector.add_exception(self)
	
	for c in weapons_map.values():
		if c != null:
			c.setup(self, get_parent())
	
	_connect_to_signals()
	var tmp_type = CurrentWeaponType
	CurrentWeaponType = -1
	set_current_weapon(tmp_type)
	
	prev_position = global_position

func _connect_to_signals():
	# warning-ignore:return_value_discarded
	stickman_visual.connect("weapon_drop_mag", self, "drop_weapon_mag")
	# warning-ignore:return_value_discarded
	stickman_visual.connect("weapon_create_mag", self, "create_weapon_mag")
	# warning-ignore:return_value_discarded
	stickman_visual.connect("weapon_attach_mag", self, "attach_weapon_mag")
	# warning-ignore:return_value_discarded
	stickman_visual.connect("weapon_reload_finished", self, "weapon_reload_finished")
	# warning-ignore:return_value_discarded
	stickman_visual.connect("weapon_reload_started", self, "weapon_reload_started")
	# warning-ignore:return_value_discarded
	health_comp.connect("dead", self, "on_dead")
	# warning-ignore:return_value_discarded
	health_comp.connect("resurrected", self, "on_resurrected")

func _physics_process(_delta: float) -> void:
	if health_comp.is_alive():
		process_input()
		
		weapons()
		run()
		on_wall()
		jump()
	else:
		# stop dead body..
		velocity.x = lerp(velocity.x, 0, 0.2)
	
	gravity()
	
	velocity = move_and_slide_with_snap(velocity, (Vector2.DOWN * 12 if snap_to_ground else Vector2.ZERO), Vector2.UP, false)
	distance_counter()
	
	if health_comp.is_alive():
		animations()

func process_input():
	pass

func distance_counter():
	var dist = global_position.distance_to(prev_position)
	var _dist_h = abs(global_position.x - prev_position.x)
	var _dist_v = abs(global_position.y - prev_position.y)
	prev_position = global_position
	
	# count here all other vars
	distance_counter_virtual(dist, _dist_h, _dist_v)
	
	total_covered_distance += dist
	jump_down_platform_distance_vertical += _dist_v

func distance_counter_virtual(_dist : float, _dist_h : float, _dist_v : float):
	pass

# =================================
# Health Component

func on_dead():
	stickman_visual.IsAlive = stickman_visual.EIsAliveState.dead
	is_holding_on_wall = false
	velocity = Vector2.ZERO
	set_collision_layer_bit(9, false)
	
	on_dead_virtual()

func on_dead_virtual():
	pass

func on_resurrected():
	stickman_visual.IsAlive = stickman_visual.EIsAliveState.alive
	set_collision_layer_bit(9, true)
	
	on_resurrected_virtual()

func on_resurrected_virtual():
	pass


# =================================
# Weapons

func weapons():
	if input_fire_pressed and is_can_use_weapon:
		if current_weapon and CurrentWeaponType != WeaponTypes.None and not is_holding_on_wall:
			current_weapon.shoot()
	if input_next_weapon_just_pressed:
		self.CurrentWeaponType = wrapi(CurrentWeaponType + 1, 0, WeaponTypes.size())
	if current_weapon and ((input_reload_just_pressed and current_weapon.is_can_reload()) or current_weapon.is_need_reload()):
		stickman_visual.WeaponReload = true

func drop_weapon_mag():
	if current_weapon:
		current_weapon.drop_mag()

func create_weapon_mag():
	if current_weapon:
		stickman_visual.attach_ammo_to_hand(current_weapon.create_new_mag())

func attach_weapon_mag():
	if current_weapon:
		current_weapon.attach_mag()

func weapon_reload_finished():
	if current_weapon:
		current_weapon.roload_finished()

func weapon_reload_started():
	if current_weapon:
		current_weapon.roload_started()

func weapon_ammo_in_mag(weapon) -> int:
	if weapon:
		return weapon.ammo_in_mag
	return -1

func weapon_ammo_total(weapon) -> int:
	if weapon:
		return weapon.total_ammo
	return -1

func weapon_ammo_updated(mag, total):
	emit_signal("ammo_updated", mag, total)

func connect_weapon_signals(prev : Node2D, next : Node2D):
	if prev and prev.is_connected("ammo_updated", self, "weapon_ammo_updated"):
		prev.disconnect("ammo_updated", self, "weapon_ammo_updated")
	
	if next:
		if not next.is_connected("ammo_updated", self, "weapon_ammo_updated"):
			# warning-ignore:return_value_discarded
			next.connect("ammo_updated", self, "weapon_ammo_updated")
		
		weapon_ammo_updated(weapon_ammo_in_mag(next), weapon_ammo_total(next))
	else:
		weapon_ammo_updated(-1, -1)

# =================================
# Run

func run():
	# horizontal movement
	if is_on_floor():
		if input_move_direction != 0:
			velocity.x = lerp(velocity.x, input_move_direction * MaxGroundSpeed, MoveAcceleration)
		else:
			velocity.x = lerp(velocity.x, 0, MoveDeacceleration)
	else:
		if input_move_direction != 0:
			velocity.x = lerp(velocity.x, input_move_direction * MaxGroundSpeed, MoveAccelerationInAir)
		else:
			velocity.x = lerp(velocity.x, 0, MoveDeaccelerationInAir)
	rotate_character_dir(input_move_direction)

# =================================
# Jump

func jump():
	# deffered jump
	jump_deffered_timer -= get_physics_process_delta_time()
	wall_jump_manual_rotation_timer -= get_physics_process_delta_time()
	
	if input_jump_just_pressed:
		jump_deffered_timer = JumpDefferedTime
	
	if is_holding_on_wall:
		#calculate_coyote_jump(true)
		wall_holding_timer -= get_physics_process_delta_time()
		
		if jump_deffered_timer > 0:# and is_on_floor_coyote:
			is_on_floor_coyote = false
			stickman_visual.InAirState = stickman_visual.EInAirState.jump
			
			wall_jump_manual_rotation_timer = WallJumpManualRotationBlockTime
			
			var dir = Vector2(is_facing_right_sign * -1, -1.2).normalized()
			rotate_character_dir(dir.x)
			
			velocity.x = dir.x * JumpStrength
			velocity.y = dir.y * JumpStrength
			is_holding_on_wall = false
		
		if (is_facing_right and velocity.x < 0) or (not is_facing_right and velocity.x > 0):
			is_holding_on_wall = false
	else:
		calculate_coyote_jump(is_on_floor())
		test_distance_covered_after_platforms_disabled()
		
		# is want to jump
		if jump_deffered_timer > 0:
			# jump through oneway platform
			# on "twoway" platform and looking down
			if two_way_platform_checker.is_colliding() and input_look_direction > 0:
				print("wtf" + str(OS.get_ticks_msec()))
				_do_jump_through_platform()
			else:
				_do_regular_jump()

func test_distance_covered_after_platforms_disabled():
	if is_jumping_through_platforms and jump_down_platform_distance_vertical > 8:
		_stop_ignoring_platforms()

func _stop_ignoring_platforms():
	is_jumping_through_platforms = false
	set_collision_mask_bit(TWOWAY_PlATFORMS_LAYER_BIT, true)
	tween.remove(self, "_stop_ignoring_platforms")

func _do_jump_through_platform():
	set_collision_mask_bit(TWOWAY_PlATFORMS_LAYER_BIT, false)
	
	is_jumping_through_platforms = true
	jump_down_platform_distance_vertical = 0
	jump_coyote_timer = 0
	# TODO also need to just check is moved some pixels
	tween.interpolate_callback(self, 0.15, "_stop_ignoring_platforms")
	tween.start()

func _do_regular_jump():
	# is on floor and can jump
	if is_on_floor_coyote:
		snap_to_ground = false
		jump_deffered_timer = 0
		is_on_floor_coyote = false
		stickman_visual.InAirState = stickman_visual.EInAirState.jump
		velocity.y = -JumpStrength

func calculate_coyote_jump(is_grounded):
	if is_grounded and velocity.y >= 0:
		snap_to_ground = true
		is_on_floor_coyote = true
		jump_coyote_timer = JumpCoyoteTime
	else:
		jump_coyote_timer -= get_physics_process_delta_time()
		if jump_coyote_timer < 0:
			is_on_floor_coyote = false

# =================================
# Walls

func on_wall():
	var is_wall_colliding = is_wall_detectors_collide()
	
	if is_holding_on_wall:
		if not is_wall_colliding or is_on_floor():
			is_holding_on_wall = false
	else:
		if not is_on_floor():
			# if on the wall and nothing is trying to move the character
			if is_wall_colliding and (sign(velocity.x) == is_facing_right_sign or velocity.x == 0):
				is_holding_on_wall = true
				wall_holding_timer = OnWallStillHoldingTime
				var width = capsule_collison.shape.radius
				global_position.x = get_wall_collision_point().x + (width * (is_facing_right_sign * -1))
				
				# reset forces
				velocity = Vector2()

# =================================
# Gravity

func gravity():
	if is_holding_on_wall:
		slope_ray_collision.disabled = false
		
		# FIX ME with fan
		velocity.y += GRAVITY * MaxGravitySpeedOnWallScale * OnWallGravityCurve.interpolate(wall_holding_timer/ OnWallStillHoldingTime)
		
		var spd = MaxGravitySpeed * MaxGravitySpeedOnWallScale
		if velocity.y > spd:
			velocity.y = spd
	else:
		#velocity.y = lerp(velocity.y, GRAVITY, GravityAcceleration)
		velocity.y += GRAVITY
		
		if velocity.y > MaxGravitySpeed:
			velocity.y = MaxGravitySpeed
		
		if velocity.y < 0:
			slope_ray_collision.disabled = true
		else:
			slope_ray_collision.disabled = false

# =================================
# Animations

func animations():
	# run / idle
	var min_speed = 5.0
	var is_manually_moving_backwards = false
	
	if is_can_manually_rotate() and abs(velocity.x) > min_speed:
		is_manually_moving_backwards = sign(velocity.x) != is_facing_right_sign
	stickman_visual.IsMovingBackward = is_manually_moving_backwards
	
	stickman_visual.GroundMove = stickman_visual.EGroundMove.run if (input_move_direction != 0 and abs(velocity.x) > min_speed) else stickman_visual.EGroundMove.idle
	if abs(velocity.x) > 0:
		stickman_visual.RunTimescale = clamp(abs(velocity.x) / GroundSpeedNormalAnimScale, 0.5, 2)
	
	# aiming angle
	var target_angle = input_look_angle * 0.5 + 0.5
	rotate_weapon_wall_detector(target_angle)
	
	if weapon_wall_detector.is_colliding():
		stickman_visual.AimBlend = lerp(stickman_visual.AimBlend, 0.9, 0.5)
		is_can_use_weapon = false
	else:
		stickman_visual.AimBlend = lerp(stickman_visual.AimBlend, target_angle, 0.5)
		is_can_use_weapon = true
	
	if is_on_floor():
		stickman_visual.SpaceStateWeapon = stickman_visual.ESpaceStateWeapon.ground
		stickman_visual.SpaceState = stickman_visual.ESpaceState.weapon
		stickman_visual.MustHolsterWeapon = false
		
	else:
		if is_holding_on_wall:
			stickman_visual.MustHolsterWeapon = true
			stickman_visual.SpaceState = stickman_visual.ESpaceState.wall
		else:
			stickman_visual.MustHolsterWeapon = false
			stickman_visual.SpaceState = stickman_visual.ESpaceState.weapon
			stickman_visual.SpaceStateWeapon = stickman_visual.ESpaceStateWeapon.air

func rotate_weapon_wall_detector(angle):
	weapon_wall_detector.rotation = lerp(weapon_wall_detector.rotation + 1.5708, (PI * angle), 0.5) - 1.5708
	weapon_wall_detector.force_raycast_update()

func apply_force(force : Vector2):
	velocity += force

func is_can_manually_rotate() -> bool:
	return enable_onfloor_manual_rotation \
					and is_on_floor_coyote \
					and (not is_holding_on_wall and wall_jump_manual_rotation_timer < 0)

func rotate_character_dir(dir : float):
	if dir == 0 or is_can_manually_rotate():
		return
	
	rotate_character(dir > 0)

func rotate_character(is_right: bool):
	if is_facing_right != is_right:
		is_facing_right = is_right
		is_facing_right_sign = 1 if is_facing_right else -1
		
		stickman_visual.scale.x = is_facing_right_sign * StickmanScale.x
		rays.scale = Vector2(is_facing_right_sign, 1)
		
		force_update_rays()

func force_update_rays():
	for w in wall_detectors:
		w.force_raycast_update()
	
	weapon_wall_detector.force_raycast_update()

func is_wall_detectors_collide() -> bool:
	for w in wall_detectors:
		if not w.is_colliding():
			return false
	return true

func get_wall_collision_point() -> Vector2:
	return wall_detectors[0].get_collision_point()

func set_current_weapon(val : int):
	if CurrentWeaponType != val:
		CurrentWeaponType = val
		if stickman_visual:
			stickman_visual.HasGun = CurrentWeaponType != WeaponTypes.None
		if weapon_slot:
			if CurrentWeaponType == WeaponTypes.None:
					current_weapon = null
					connect_weapon_signals(current_weapon, null)
			else:
				for c in weapon_slot.get_children():
					if c == weapons_map[CurrentWeaponType]:
						connect_weapon_signals(current_weapon, c)
						c.equiped()
						
						current_weapon = c
						c.visible = true
					else:
						c.visible = false
