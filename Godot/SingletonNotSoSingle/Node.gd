extends Node

func _ready():
	var global2 = load("res://global.gd").new()
	global2.name = "global2"
	add_child(global2)
	global2.a = 2
	
	print(global.a)
	print(global2.a)
