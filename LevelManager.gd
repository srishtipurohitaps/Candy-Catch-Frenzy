extends Node

var current = 1
const MAX = 3

func next_level():
	current = current % MAX + 1
	get_tree().change_scene("res://scenes/level%d.tscn" % current)

func reset_to_level_1():
	current = 1
	get_tree().change_scene("res://scenes/level1.tscn")
