extends Area2D

@export var is_rainbow = false
var fall_speed = 220.0
var points = 10

func _ready():
	body_entered.connect(_on_caught)
	area_entered.connect(_on_caught)

func _process(delta):
	position.y += fall_speed * delta
	if position.y > 700:
		get_node("/root/Main").missed_candy()
		queue_free()

func _on_caught(body):
	if body.name != "Basket":
		return
	if is_rainbow:
		get_node("/root/Main").activate_rainbow_powerup()
	else:
		get_node("/root/Main").catch_candy(points)
	queue_free()
