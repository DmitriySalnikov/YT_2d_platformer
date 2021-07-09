tool
extends Area2D

# Name of the level inside Levels folder(without extension)
export var LevelName : String
export var SpawnPointName : String = "default"

func _ready() -> void:
	pass

func _on_LevelSwitcher_body_entered(body: Node) -> void:
	if not LevelName.empty():
		if body is StickmanHero:
			var scn = load("res://Levels/"+LevelName+".tscn")
			if scn:
				LevelSwitchFade.set_character(body)
				LevelSwitchFade.start_fade()
				yield(LevelSwitchFade, "anim_finished")
				var _err = get_tree().change_scene_to(scn)
				G.CurrentSpawnPoint = SpawnPointName
				LevelSwitchFade.start_fade_back()
