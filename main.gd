extends Node2D

@onready var background = $ColorRect
var time = 0.0

func _process(delta):
	time += delta
	var hue = fmod(time * 0.1, 1.0)
	background.color = Color.from_hsv(hue, 0.3, 0.95)
