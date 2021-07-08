extends Control



func _on_NewGame_pressed() -> void:
	get_tree().change_scene("res://Levels/TestLevel1.tscn")


func _on_Exit_pressed() -> void:
	get_tree().quit()
