extends Node2D

@onready var background = $ColorRect
@onready var spawn_timer = $SpawnTimer
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var lives_label = $CanvasLayer/LivesLabel
@onready var timer_label = $CanvasLayer/TimerLabel
@onready var camera = $Camera2D

var candy_scene = preload("res://candy.tscn")
var bomb_scene = preload("res://bomb.tscn")

var score = 0
var lives = 3
var game_time = 60.0
var time = 0.0
var shake_amount = 0.0
var game_active = true

func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _process(delta):
	time += delta
	var hue = fmod(time * 0.1, 1.0)
	background.color = Color.from_hsv(hue, 0.3, 0.95)
	
	if game_active and lives > 0:
		game_time -= delta
		timer_label.text = "Time: %d" % int(game_time)
		
		if game_time <= 0:
			game_over()
	
	if shake_amount > 0:
		camera.offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		shake_amount = lerp(shake_amount, 0.0, delta * 5.0)
	else:
		camera.offset = Vector2.ZERO

func _on_spawn_timer_timeout():
	if not game_active:
		return
	
	spawn_timer.wait_time = max(0.3, 1.0 - (60.0 - game_time) / 120.0)
	
	if randf() < 0.16:
		spawn_bomb()
	else:
		spawn_candy()

func spawn_candy():
	var candy = candy_scene.instantiate()
	candy.position = Vector2(randf_range(100, 1052), -50)
	
	var r = randf()
	if r < 0.4:
		candy.get_node("Sprite2D").texture = preload("res://assets/Red_Candy.png")
		candy.points = 10
		candy.fall_speed = 220
	elif r < 0.7:
		candy.get_node("Sprite2D").texture = preload("res://assets/Blue_Candy.png")
		candy.points = 15
		candy.fall_speed = 250
	elif r < 0.85:
		candy.get_node("Sprite2D").texture = preload("res://assets/Yellow_Candy.png")
		candy.points = 25
		candy.fall_speed = 280
	elif r < 0.95:
		candy.get_node("Sprite2D").texture = preload("res://assets/Green_Candy.png")
		candy.points = 5
		candy.fall_speed = 260
	else:
		candy.get_node("Sprite2D").texture = preload("res://assets/Purple_Candy.png")
		candy.points = 50
		candy.fall_speed = 300
	
	candy.fall_speed += (60.0 - game_time) * 2.0
	
	add_child(candy)

func spawn_bomb():
	var bomb = bomb_scene.instantiate()
	bomb.position = Vector2(randf_range(100, 1052), -50)
	bomb.fall_speed = 260 + (60.0 - game_time) * 3.0
	add_child(bomb)

func catch_candy(points):
	score += points
	score_label.text = "Score: %d" % score
	
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(score_label, "scale", Vector2.ONE, 0.1)

func catch_bomb():
	lives -= 1
	if lives < 0:
		lives = 0
	lives_label.text = "Lives: %d" % lives
	
	shake_amount = 10.0
	
	if lives <= 0:
		game_over()

func missed_candy():
	lives -= 1
	if lives < 0:
		lives = 0
	lives_label.text = "Lives: %d" % lives
	
	if lives <= 0:
		game_over()

func game_over():
	game_active = false
	spawn_timer.stop()
	
	$CanvasLayer/GameOverPanel.visible = true
	$CanvasLayer/GameOverPanel/VBoxContainer/FinalScore.text = "Final Score: %d" % score
	
	$CanvasLayer/GameOverPanel.scale = Vector2.ZERO
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($CanvasLayer/GameOverPanel, "scale", Vector2.ONE, 0.5)
