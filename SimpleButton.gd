tool
extends Node2D

export var ButtonID := "UNNAMED" setget set_button_id
export var InteractionSubjectID := "UNNAMED" setget set_interaction_subject_id
export var IsActive := true

onready var anim := $AnimationPlayer

var _is_ready = false
var interaction_subjects = []

func _ready() -> void:
	_is_ready = true
	self.InteractionSubjectID = InteractionSubjectID

func set_button_id(val : String):
	ButtonID = val
	if has_node("EditorOnly2D/Label"):
		$EditorOnly2D/Label.text = "ButtonID:\n%s" % [ButtonID]

func set_interaction_subject_id(val : String):
	InteractionSubjectID = val
	if not Engine.editor_hint:
		var subs = get_tree().get_nodes_in_group("interaction_subject")
		for sub in subs:
			if sub.InteractionSubjectID == InteractionSubjectID:
				interaction_subjects.append(sub)

func interact(_sender : StickmanCharacter):
	if anim.current_animation == "":
		anim.play("Click")
		
		for sub in interaction_subjects:
			sub.interact(_sender, self)
