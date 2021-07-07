tool
extends Area2D

export var ShapeSize : Vector2 = Vector2(250, 64) setget set_shape_size
export var Force : float = 11000
export var ForceCurve : Curve
var objs := []

onready var col := $CollisionShape2D
onready var col_rect : RectangleShape2D = col.shape

func _ready() -> void:
	_update_shape()

func _process(delta: float) -> void:
	if not Engine.editor_hint:
		var frc = Vector2.RIGHT.rotated(rotation) * Force * delta
		for obj in objs:
			var power = ForceCurve.interpolate((obj.position - position).length() / (col_rect.extents.length() * 2))
			obj.apply_force(power * frc)

func _on_Area2D_body_entered(body: Node) -> void:
	if body.has_method("apply_force"):
		objs.append(body)

func _on_Area2D_body_exited(body: Node) -> void:
	if objs.has(body):
		objs.erase(body)

func _update_shape():
	if $CollisionShape2D:
		$CollisionShape2D.shape.extents = ShapeSize / 2
		$CollisionShape2D.position = Vector2(ShapeSize.x / 2, 0)

func set_shape_size(val : Vector2):
	ShapeSize = val
	_update_shape()
