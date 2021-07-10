extends Node

signal dead
signal resurrected

export var MaxHealthPoints : float = 100

onready var HP := MaxHealthPoints

func restore_full():
	HP = MaxHealthPoints

func decrease_hp(amount : float):
	HP = clamp(HP - amount, 0, MaxHealthPoints)
	if HP == 0:
		emit_signal("dead")

func increase_hp(amount : float):
	var ohp = HP
	HP = clamp(HP + amount, 0, MaxHealthPoints)
	if ohp == 0 and HP > 0:
		emit_signal("resurrected")

func is_alive() -> bool:
	return HP>0
