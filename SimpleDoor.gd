tool
extends Node2D

export var InteractionSubjectID := "UNNAMED" setget set_door_id
export var IsOpened := false setget set_is_opened
export var OpenedPosition := Vector2(0,-128) setget set_opened_position
export(float, 0, 100.0) var OpeningTime := 1.0
export(C.TweenTransitionTypes) var TweenTransType := Tween.TRANS_BOUNCE
export(C.TweenEaseTypes) var TweenEaseType := Tween.EASE_OUT
export var NavMapPartToInfluense : NodePath

var _is_ready := false

func _ready() -> void:
	_is_ready = true
	
	if not Engine.editor_hint:
		IsOpened = G.get_interactable_state(G.InteractableTypes.Door, InteractionSubjectID, IsOpened)
		update_navigations()
	
	$StaticBody2D.position = OpenedPosition if IsOpened else Vector2.ZERO

func set_door_id(val : String):
	InteractionSubjectID = val
	if has_node("EditorOnly2D/Label"):
		$EditorOnly2D/Label.text = "DoorID:\n%s" % [val]

func set_is_opened(val : bool):
	IsOpened = val
	start_anim()

func set_opened_position(val : Vector2):
	OpenedPosition = val
	if IsOpened:
		$StaticBody2D.position = val

func interact(_sender, _by_proxy):
	self.IsOpened = !IsOpened
	G.set_interactable_state(G.InteractableTypes.Door, InteractionSubjectID, IsOpened)

func update_navigations():
	if has_node(NavMapPartToInfluense):
		get_node(NavMapPartToInfluense).enabled = IsOpened

func start_anim():
	if not _is_ready:
		return
	
	var door_len = $StaticBody2D.position.length()
	var seek = door_len / OpenedPosition.length() if door_len > 0 else 0
	
	var start = Vector2.ZERO
	var end = OpenedPosition
	if not IsOpened:
		var tmp = start
		start = end
		end = tmp
		seek = 1.0 - seek
	
	var tween = $Tween
	tween.remove_all()
	tween.interpolate_property($StaticBody2D, "position", start, end, OpeningTime, TweenTransType, TweenEaseType)
	tween.interpolate_callback(self, OpeningTime / 2.0, "update_navigations")
	tween.seek(seek * OpeningTime)
	tween.start()
