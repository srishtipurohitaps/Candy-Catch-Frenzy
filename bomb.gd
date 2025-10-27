extends Area2D

var fall_speed = 260.0

func _ready():
	body_entered.connect(_on_caught)
	area_entered.connect(_on_caught)

func _process(delta):
	position.y += fall_speed * delta
	if position.y > 700:
		queue_free()

func _on_caught(body):
	if body.name == "Basket":
		get_node("/root/Main").catch_bomb()
		queue_free()
