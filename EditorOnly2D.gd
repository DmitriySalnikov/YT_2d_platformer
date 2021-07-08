tool
class_name EditorOnly2D
extends Node2D

func _ready() -> void:
	if not Engine.editor_hint:
		visible = false
		get_parent().call_deferred("remove_child", self)
		queue_free()
