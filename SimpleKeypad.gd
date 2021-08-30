tool
extends Node2D

export var KeypadID := "UNNAMED" setget set_keypad_id
export var KeycardID := "UNNAMED" setget set_keycard_id
export var IsOneshot := false

export var InteractionSubjectID := "UNNAMED" setget set_interaction_subject_id
export var IsActive := true

onready var anim := $AnimationPlayer

var is_opened := false
var _is_ready = false
var interaction_subjects = []
var tmp_sender

func _ready() -> void:
	_is_ready = true
	self.InteractionSubjectID = InteractionSubjectID
	
	if IsOneshot:
		is_opened = G.get_interactable_state(G.InteractableTypes.Keypad, KeypadID, false)
		if is_opened:
			anim.play("Activated")
			yield(get_tree(), "idle_frame")
			yield(get_tree(), "idle_frame")
			anim.seek(anim.current_animation_length, true)
		else:
			anim.play("Base")
	else:
		anim.play("Base")

func set_keypad_id(val : String):
	KeypadID = val
	upd_text()

func set_keycard_id(val : String):
	KeycardID = val
	upd_text()

func upd_text():
	if has_node("EditorOnly2D/Label"):
		$EditorOnly2D/Label.text = "KeypadID:\n%s\nKeycardID:\n%s" % [KeypadID, KeycardID]

func set_interaction_subject_id(val : String):
	InteractionSubjectID = val
	if not Engine.editor_hint:
		var subs = get_tree().get_nodes_in_group("interaction_subject")
		for sub in subs:
			if sub.InteractionSubjectID == InteractionSubjectID:
				interaction_subjects.append(sub)

func interact(_sender : StickmanCharacter):
	if anim.current_animation in ["", "Base"]:
		if _sender.has_keycard(KeycardID):
			if not is_opened and IsOneshot:
				anim.play("Activated")
				tmp_sender = _sender
				
				is_opened = true
				G.set_interactable_state(G.InteractableTypes.Keypad, KeypadID, true)
		else:
			anim.play("ActivatedWrong")

func _send_interact():
	for sub in interaction_subjects:
		sub.interact(tmp_sender, self)
	tmp_sender = null

func _try_to_change_anim():
	if not IsOneshot:
		anim.play("Base")
