extends Node2D

export var CharacterScene : PackedScene

func _ready() -> void:
	spawn_character()

func spawn_character():
	var spawn_points = get_tree().get_nodes_in_group("spawn_points")
	var default_sp : SpawnPoint
	var res_sp : SpawnPoint
	
	for sp in spawn_points:
		if sp is SpawnPoint:
			if sp.SpawnName == G.CurrentSpawnPoint:
				res_sp = sp
				break
			else:
				if not default_sp:
					if sp.SpawnName == "default":
						default_sp = sp
	
	if res_sp == null:
		if default_sp:
			res_sp = default_sp
		elif spawn_points.size() > 0:
			res_sp = spawn_points[0]
	
	if res_sp:
		var tmp_char = CharacterScene.instance()
		add_child(tmp_char)
		tmp_char.global_position = res_sp.global_position
		tmp_char.rotate_character(res_sp.IsFacingRight)
		
		yield(get_tree(), "idle_frame")
		LevelSwitchFade.set_character(tmp_char)
	else:
		print("Spawn points does not found. At least one SpawnPoint must be place on the level")
