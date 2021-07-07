extends KinematicBody2D

enum WeaponTypes{
	None,
	Gun
}

export var StickmanScale := Vector2(3, 3)
export var MoveAcceleration := 0.25
export var MoveAccelerationInAir := 0.100
export var MoveDeacceleration := 0.5
export var MoveDeaccelerationInAir := 0.05

export(float, 0, 9800) var GRAVITY := 100.0
export(float, 0, 9800) var MaxGravitySpeed := 1000.0
export(float, 0, 9800) var MaxGravitySpeedOnWallScale := 0.5
export(float, 0, 3000) var MaxGroundSpeed := 500.0
export(float, 0, 3000) var GroundSpeedNormalAnimScale := 250.0
export(float, 0, 1) var JumpCoyoteTime := 0.1
export(float, 0.001, 1) var JumpDefferedTime := 0.1
export(float, 0, 25000) var JumpStrength := 1300.0
export(Curve) var OnWallGravityCurve : Curve
export var OnWallStillHoldingTime := 1.8
export var CurrentWeaponType : int = WeaponTypes.None setget set_current_weapon

onready var stickman_visual := $StickmanVisual
onready var capsule_collison := $CS2D
onready var rays := $Rays

onready var weapon_slot := $WeaponSlot
onready var weapon_wall_detector := $Rays/WeaponWallDetector
onready var current_weapon : Node2D
onready var weapons_map := {
	WeaponTypes.None : null,
	WeaponTypes.Gun : $WeaponSlot/Gun,
}

onready var wall_detectors_root := $Rays/WallDetectors

var move_vector : Vector2

var is_on_floor_coyote := false
var jump_coyote_timer := 0.0
var jump_deffered_timer := 0.0

var is_can_use_weapon := true
var velocity := Vector2()
var is_facing_right := true
var is_facing_right_sign := 1

var is_holding_on_wall := false
var wall_detectors := []
var wall_holding_time := 0.0

func _ready() -> void:
	for c in wall_detectors_root.get_children():
		if c is RayCast2D:
			c.add_exception(self)
			wall_detectors.append(c)
	weapon_wall_detector.add_exception(self)
	
	for c in weapons_map.values():
		if c != null:
			c.setup(self, get_parent())
	
	var tmp_type = CurrentWeaponType
	CurrentWeaponType = -1
	set_current_weapon(tmp_type)
	_connect_to_stickman()

func _connect_to_stickman():
	# warning-ignore:return_value_discarded
	stickman_visual.connect("weapon_drop_mag", self, "drop_weapon_mag")
	# warning-ignore:return_value_discarded
	stickman_visual.connect("weapon_create_mag", self, "create_weapon_mag")
	# warning-ignore:return_value_discarded
	stickman_visual.connect("weapon_attach_mag", self, "attach_weapon_mag")

func _physics_process(_delta: float) -> void:
	weapons()
	run()
	on_wall()
	jump()
	gravity()
	
	velocity = move_and_slide(velocity, Vector2.UP)
	
	animations()

# =================================
# Weapons

func weapons():
	if Input.is_action_pressed("fire") and is_can_use_weapon:
		if current_weapon and CurrentWeaponType != WeaponTypes.None and not is_holding_on_wall:
			current_weapon.spawn_bullet()
	if Input.is_action_just_pressed("ui_home"):
		self.CurrentWeaponType = wrapi(CurrentWeaponType + 1, 0, WeaponTypes.size())
	if Input.is_action_just_pressed("reload"):
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

# =================================
# Run

func run():
	# horizontal movement
	move_vector = Vector2((Input.get_action_strength("move_right") - Input.get_action_strength("move_left")), 0)
	if is_on_floor():
		if move_vector != Vector2.ZERO:
			velocity.x = lerp(velocity.x, move_vector.normalized().x * MaxGroundSpeed, MoveAcceleration)
		else:
			velocity.x = lerp(velocity.x, 0, MoveDeacceleration)
	else:
		if move_vector != Vector2.ZERO:
			velocity.x = lerp(velocity.x, move_vector.normalized().x * MaxGroundSpeed, MoveAccelerationInAir)
		else:
			velocity.x = lerp(velocity.x, 0, MoveDeaccelerationInAir)
	rotate_character(move_vector)

# =================================
# Jump

func jump():
	# deffered jump
	jump_deffered_timer -= get_physics_process_delta_time()
	if Input.is_action_just_pressed("jump"):
		jump_deffered_timer = JumpDefferedTime
	
	if is_holding_on_wall:
		#calculate_coyote_jump(true)
		wall_holding_time -= get_physics_process_delta_time()
		
		if Input.is_action_just_pressed("jump"):# and is_on_floor_coyote:
			is_on_floor_coyote = false
			stickman_visual.InAirState = stickman_visual.EInAirState.jump
			
			var dir = Vector2(is_facing_right_sign * -1, -1.2).normalized()
			rotate_character(dir)
			
			velocity.x = dir.x * JumpStrength
			velocity.y = dir.y * JumpStrength
			is_holding_on_wall = false
		
		if (is_facing_right and velocity.x < 0) or (not is_facing_right and velocity.x > 0):
			is_holding_on_wall = false
	else:
		calculate_coyote_jump(is_on_floor())
		
		if jump_deffered_timer > 0 and is_on_floor_coyote:
			jump_deffered_timer = 0
			is_on_floor_coyote = false
			stickman_visual.InAirState = stickman_visual.EInAirState.jump
			velocity.y = -JumpStrength


func calculate_coyote_jump(is_grounded):
	if is_grounded:
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
				wall_holding_time = OnWallStillHoldingTime
				var width = capsule_collison.shape.radius
				global_position.x = get_wall_collision_point().x + (width * (is_facing_right_sign * -1))
				
				# reset forces
				velocity = Vector2()

# =================================
# Gravity

func gravity():
	if is_holding_on_wall:
		# FIX ME
		velocity.y += GRAVITY * MaxGravitySpeedOnWallScale * OnWallGravityCurve.interpolate(wall_holding_time/ OnWallStillHoldingTime)
		
		var spd = MaxGravitySpeed * MaxGravitySpeedOnWallScale
		if velocity.y > spd:
			velocity.y = spd
	else:
		#velocity.y = lerp(velocity.y, GRAVITY, GravityAcceleration)
		velocity.y += GRAVITY
		
		if velocity.y > MaxGravitySpeed:
			velocity.y = MaxGravitySpeed

# =================================
# Animations

func animations():
	# run / idle
	stickman_visual.GroundMove = stickman_visual.EGroundMove.run if (move_vector != Vector2.ZERO and abs(velocity.x) > 15.0) else stickman_visual.EGroundMove.idle
	if abs(velocity.x) > 0:
		stickman_visual.RunTimescale = abs(velocity.x) / GroundSpeedNormalAnimScale
	
	# aiming angle
	var look_angle = Input.get_action_strength("look_up") - Input.get_action_strength("look_down")
	if weapon_wall_detector.is_colliding():
		stickman_visual.AimBlend = lerp(stickman_visual.AimBlend, 0.9, 0.5)
		is_can_use_weapon = false
	else:
		stickman_visual.AimBlend = lerp(stickman_visual.AimBlend, 0.5 - look_angle * 0.25, 0.5)
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


func apply_force(force : Vector2):
	velocity += force

func rotate_character(dir : Vector2):
	if dir.x == 0:
		return
	
	if is_facing_right != (dir.x > 0):
		is_facing_right = dir.x > 0
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
			for c in weapon_slot.get_children():
				if CurrentWeaponType == WeaponTypes.None:
					pass
				else:
					if c == weapons_map[CurrentWeaponType]:
						current_weapon = c
						c.visible = true
					else:
						c.visible = false
