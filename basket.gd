extends Area2D

var speed = 700.0
var screen_width = 1152
@onready var sprite = $Sprite2D

func _process(delta):
	var direction = Input.get_axis("ui_left", "ui_right")
	position.x += direction * speed * delta
	position.x = clamp(position.x, 80, screen_width - 80)
	if abs(direction) > 0:
		sprite.scale.x = lerp(sprite.scale.x, 1.2, 0.2)
		sprite.scale.y = lerp(sprite.scale.y, 0.8, 0.2)
	else:
		sprite.scale = lerp(sprite.scale, Vector2.ONE, 0.2)
