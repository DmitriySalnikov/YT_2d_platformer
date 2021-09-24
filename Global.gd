extends Node

enum InteractableTypes{
	Button,
	Keypad,
	Door,
}

var CurrentSpawnPoint := "default"
var WorldState := {}
var CollectedKeycards := []

func _ready() -> void:
	set_meta("ready", true)

func check_collected_card(id : String):
	return CollectedKeycards.has(id)

func collect_card(id : String):
	CollectedKeycards.append(id)

func get_interactable_state(type : int, id : String, default):
	if WorldState.has(type) and WorldState[type].has(id):
		return WorldState[type][id]
	return default

func set_interactable_state(type : int, id : String, state):
	if not WorldState.has(type):
		WorldState[type] = {}
	
	WorldState[type][id] = state
