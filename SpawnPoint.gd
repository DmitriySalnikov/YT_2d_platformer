tool
class_name SpawnPoint
extends Area2D

export var SpawnName : String = "default" setget set_spawn_name
export var IsFacingRight : bool = true setget set_facing_right

func _ready() -> void:
	pass

func set_spawn_name(val : String):
	SpawnName = val.to_lower()
	if has_node("EditorOnly/Label"):
		$EditorOnly/Label.text = SpawnName

func set_facing_right(val : bool):
	IsFacingRight = val
	if has_node("EditorOnly/RayCast2D"):
		$EditorOnly/RayCast2D.scale = Vector2(1 if IsFacingRight else -1, 1)
