tool
class_name EditorOnly2D
extends Node2D

export var ShowInDebug = false

func _ready() -> void:
	if not Engine.editor_hint and not (OS.has_feature("debug") and ShowInDebug):
		visible = false
		get_parent().call_deferred("remove_child", self)
		queue_free()
