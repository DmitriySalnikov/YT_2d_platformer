extends KinematicBody2D

enum WeaponTypes{
	None,
	Gun
}

export var StickmanScale := Vector2(3, 3)
export var MoveAcceleration := 0.25
export var MoveDeacceleration := 0.5
export var GravityAcceleration := 0.3
export var ForceDeacceleration := 0.28

export(float, 0, 9800) var GRAVITY := 1200.0
export(float, 0, 3000) var MaxGroundSpeed := 600.0
export(float, 0, 25000) var JumpStrength := 1900.0
export(Curve) var OnWallGravityCurve : Curve
export var OnWallStillHoldingTimeMsec := 2000
export var CurrentWeaponType : int = WeaponTypes.None setget set_current_weapon

onready var stickman_visual := $StickmanVisual
onready var capsule_collison := $CS2D

onready var weapon_slot := $WeaponSlot
onready var current_weapon : Node2D
onready var weapons_map := {
	WeaponTypes.None : null,
	WeaponTypes.Gun : $WeaponSlot/Gun,
}

var force_velocity := Vector2()
var velocity := Vector2()

var is_holding_on_wall := false
var wall_detectors := []
var is_facing_right := true
var is_facing_right_sign := 1
var wall_holding_start_time := 0

func _ready() -> void:
	for c in $WallDetectors.get_children():
		if c is RayCast2D:
			c.add_exception(self)
			wall_detectors.append(c)
	
	for c in weapons_map.values():
		if c != null:
			c.setup(self, get_parent())
	
	var tmp_type = CurrentWeaponType
	CurrentWeaponType = -1
	set_current_weapon(tmp_type)

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("fire"):
		if current_weapon and CurrentWeaponType != WeaponTypes.None and not is_holding_on_wall:
			current_weapon.spawn_bullet()
	if Input.is_action_just_pressed("ui_home"):
		self.CurrentWeaponType = wrapi(CurrentWeaponType + 1, 0, WeaponTypes.size())
	
	stickman_visual.GroundMove = stickman_visual.EGroundMove.run
	
	# horizontal movement
	var move_direction = Vector2((Input.get_action_strength("move_right") - Input.get_action_strength("move_left")), 0)
	if move_direction != Vector2.ZERO:
		move_direction.normalized()
		
		velocity.x = lerp(velocity.x, move_direction.x * MaxGroundSpeed, MoveAcceleration)
	else:
		velocity.x = lerp(velocity.x, 0, MoveDeacceleration)
	
	var rotation_changed = rotate_character(move_direction)
	var is_wall_colliding = is_wall_detectors_collide()
	var wall_offset_rotation_multiplier = -1 if is_facing_right else 1
	
	# walls
	if is_holding_on_wall:
		if rotation_changed or not is_wall_colliding or is_on_floor():
			is_holding_on_wall = false
	else:
		if not is_on_floor():
			if is_wall_colliding:
				is_holding_on_wall = true
				wall_holding_start_time = OS.get_system_time_msecs()
				var width = capsule_collison.shape.radius
				global_position.x = get_wall_collision_point().x + (width * wall_offset_rotation_multiplier)
				
				# reset forces
				force_velocity = Vector2()
				velocity.x = 0
				velocity.y = 0
	
	stickman_visual.GroundMove = stickman_visual.EGroundMove.run if move_direction != Vector2.ZERO else stickman_visual.EGroundMove.idle
	
	# gravity and jumps
	if is_holding_on_wall:
		if Input.is_action_just_pressed("jump"):
			stickman_visual.InAirState = stickman_visual.EInAirState.jump
			
			var dir = Vector2(wall_offset_rotation_multiplier,-1).normalized()
			var _rotated = rotate_character(dir)
			
			force_velocity.x = dir.x * JumpStrength
			force_velocity.y = dir.y * JumpStrength
			is_holding_on_wall = false
		
		velocity.x += force_velocity.x
		
		if (is_facing_right and velocity.x < 0) or (not is_facing_right and velocity.x > 0):
			is_holding_on_wall = false
	else:
		velocity.x += force_velocity.x
		
		if Input.is_action_just_pressed("jump") and is_on_floor():
			stickman_visual.InAirState = stickman_visual.EInAirState.jump
			force_velocity.y -= JumpStrength
	
	if is_holding_on_wall:
		velocity.y = GRAVITY * OnWallGravityCurve.interpolate((OS.get_system_time_msecs() - wall_holding_start_time + 1.0) / OnWallStillHoldingTimeMsec)
	else:
		velocity.y = lerp(velocity.y, GRAVITY, GravityAcceleration) + force_velocity.y
	
	force_velocity.x = lerp(force_velocity.x, 0, ForceDeacceleration)
	force_velocity.y = lerp(force_velocity.y, 0, ForceDeacceleration)
	
	var _moved = move_and_slide(velocity, Vector2.UP)
	
	# additional animations
	var look_angle = Input.get_action_strength("look_up") - Input.get_action_strength("look_down")
	stickman_visual.AimBlend = lerp(stickman_visual.AimBlend, 0.5 - look_angle * 0.25, 0.5)
	
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

func rotate_character(dir : Vector2) -> bool:
	if dir.x == 0:
		return false
	
	if is_facing_right != (dir.x > 0):
		is_facing_right = dir.x > 0
		is_facing_right_sign = 1 if is_facing_right else -1
		
		stickman_visual.scale.x = is_facing_right_sign * StickmanScale.x
		rotate_wall_detectors(is_facing_right)
		return true
	
	return false

func rotate_wall_detectors(is_right : bool):
	for w in wall_detectors:
		w.rotation = 0.0 if is_right else PI
		w.force_raycast_update()

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
			for c in weapon_slot.get_children():
				if CurrentWeaponType == WeaponTypes.None:
					pass
				else:
					if c == weapons_map[CurrentWeaponType]:
						current_weapon = c
						c.visible = true
					else:
						c.visible = false
