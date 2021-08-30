tool
extends Node2D

export var CardID := "UNNAMED" setget set_card_id

func _ready() -> void:
	if G.check_collected_card(CardID):
		queue_free()
	$AnimationPlayer.play("Base")

func set_card_id(val : String):
	CardID = val
	
	if has_node("EditorOnly2D/Label"):
		$EditorOnly2D/Label.text = "CardID:\n%s" % [CardID]

func _on_Area2D_body_entered(body: StickmanCharacter) -> void:
	if body is StickmanPlayer:
		G.collect_card(CardID)
		$Tween.interpolate_property($Node2D, "modulate:a", 1.0, 0.0, 0.5)
		$Tween.interpolate_callback(self, 0.5, "queue_free")
		$Tween.start()
		$Area2D.set_deferred("monitoring", false)
