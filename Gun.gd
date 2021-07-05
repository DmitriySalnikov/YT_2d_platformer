extends Node2D

export var BulletScene : PackedScene
export var MaxBulletSpreadDeg := 4.0
export var MaxDistance := 2000.0
export var FireRate := 0.12

onready var bullet_spawner := $BulletSpawner
onready var tween := $Tween

var can_shoot := true
var owner_node : Node2D
var spawn_on_node : Node2D

func _ready() -> void:
	pass

func setup(owner, spawn_node):
	owner_node = owner
	spawn_on_node = spawn_node

func spawn_bullet():
	if can_shoot:
		var b : Node2D = BulletScene.instance()
		spawn_on_node.add_child(b)
		b.global_position = bullet_spawner.global_position
		b.global_rotation = bullet_spawner.global_rotation + deg2rad(rand_range(-MaxBulletSpreadDeg, MaxBulletSpreadDeg))
		if global_scale.x < 0:
			b.global_rotation += PI
		
		b.shoot(owner_node, MaxDistance)
		start_recovery_tween()

func start_recovery_tween():
	tween.interpolate_property(self, "can_shoot", false, true, FireRate)
	tween.start()
