extends Node2D

signal ammo_updated(in_mag, total)

export var BulletScene : PackedScene
export var Damage : float = 15.0
export var MagazineScene : PackedScene
export var MaxBulletSpreadDeg := 4.0
export var MaxDistance := 2000.0
export var FireRate := 0.12
export var MaxAmmoInMag := 20
export var MaxTotalAmmo := 200

onready var bullet_spawner := $BulletSpawner
onready var tween := $Tween
onready var static_mag := $Visual/MagLines
onready var ammo_in_mag := MaxAmmoInMag
onready var total_ammo := MaxTotalAmmo

var shoot_cool_down := true
var is_reloading := false
var owner_node : Node2D
var spawn_on_node : Node2D
var new_mag : Node2D

func _ready() -> void:
	pass

func setup(owner, spawn_node):
	owner_node = owner
	spawn_on_node = spawn_node

func shoot():
	if is_can_shoot():
		ammo_in_mag -= 1
		emit_signal("ammo_updated", ammo_in_mag, total_ammo)
		
		var b : Node2D = BulletScene.instance()
		spawn_on_node.add_child(b)
		b.global_position = bullet_spawner.global_position
		b.global_rotation = bullet_spawner.global_rotation + deg2rad(rand_range(-MaxBulletSpreadDeg, MaxBulletSpreadDeg))
		if global_scale.x < 0:
			b.global_rotation += PI
		
		b.shoot(owner_node, Damage, MaxDistance)
		start_recovery_tween()

func start_recovery_tween():
	tween.interpolate_property(self, "shoot_cool_down", false, true, FireRate)
	tween.start()

func clear_new_mag():
	if new_mag:
		new_mag.queue_free()
		new_mag = null

func is_can_shoot() -> bool:
	return shoot_cool_down and ammo_in_mag > 0 and not is_reloading

func is_can_reload() -> bool:
	return ammo_in_mag < MaxAmmoInMag and total_ammo > 0

func is_need_reload() -> bool:
	return ammo_in_mag == 0 and is_can_reload()

func drop_mag():
	clear_new_mag()
	is_reloading = true
	static_mag.visible = false
	var m = MagazineScene.instance()
	spawn_on_node.add_child(m)
	m.global_transform = static_mag.global_transform
	m.scale = Vector2.ONE
	m.set_visual_scale(static_mag.global_scale)
	m.drop()

func equiped():
	static_mag.visible = true

func create_new_mag() -> Node2D:
	clear_new_mag()
	is_reloading = true
	var m = MagazineScene.instance()
	spawn_on_node.add_child(m)
	m.global_transform = static_mag.global_transform
	m.scale = Vector2.ONE
	m.just_visual()
	new_mag = m
	return m

func attach_mag():
	clear_new_mag()
	is_reloading = true
	static_mag.visible = true
	
	total_ammo += ammo_in_mag
	total_ammo -= MaxAmmoInMag
	ammo_in_mag = MaxAmmoInMag
	emit_signal("ammo_updated", ammo_in_mag, total_ammo)

func roload_started():
	is_reloading = true

func roload_finished():
	is_reloading = false
	static_mag.visible = true
