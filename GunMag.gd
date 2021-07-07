extends RigidBody2D

func _ready() -> void:
	pass # Replace with function body.

func set_visual_scale(_scale : Vector2):
	$MagLines.scale = _scale
	$CollisionShape2D.scale = _scale

func just_visual():
	collision_mask = 0

func drop():
	$AnimationPlayer.play("Dropped")
	mode = RigidBody2D.MODE_RIGID
	apply_impulse(Vector2.UP * 10, Vector2(250 * sign($MagLines.scale.y), 600))
