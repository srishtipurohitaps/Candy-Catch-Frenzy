extends Area2D

var speed = 700.0
var screen_width = 1152

func _process(delta):
	var direction = Input.get_axis("ui_left", "ui_right")
	position.x += direction * speed * delta
	position.x = clamp(position.x, 80, screen_width - 80)
