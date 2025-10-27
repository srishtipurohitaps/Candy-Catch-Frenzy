extends Node2D

@onready var background = $ColorRect
@onready var spawn_timer = $SpawnTimer
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var lives_label = $CanvasLayer/LivesLabel
@onready var timer_label = $CanvasLayer/TimerLabel
@onready var camera = $Camera2D
@onready var game_over_panel = $CanvasLayer/GameOverPanel
@onready var final_score_txt = $CanvasLayer/GameOverPanel/VBoxContainer/FinalScore
@onready var restart_button = $CanvasLayer/GameOverPanel/VBoxContainer/RestartButton

var candy_scene = preload("res://candy.tscn")
var bomb_scene = preload("res://bomb.tscn")

# Level 2: Medium (harder)
var bomb_chance = 0.20
var spawn_wait_start = 0.8
var max_time = 50.0

var score = 0
var lives = 3
var game_time = 50.0
var time_pass = 0.0
var shake_amount = 0.0
var game_active = true
var combo_count = 0
var combo_timer = 0.0
var shield_active = false
var double_active = false

func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	restart_button.pressed.connect(_on_restart_pressed)
	game_time = max_time
	spawn_timer.wait_time = spawn_wait_start

func _process(delta):
	time_pass += delta
	var hue = fmod(time_pass * 0.1, 1.0)
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

	if combo_timer > 0:
		combo_timer -= delta
	else:
		combo_count = 0

func _on_spawn_timer_timeout():
	if not game_active:
		return
	spawn_timer.wait_time = max(0.3, spawn_wait_start - ((max_time - game_time) / 100.0))
	
	var r = randf()
	if r < bomb_chance:
		spawn_bomb()
	else:
		spawn_candy()

func spawn_candy():
	var candy = candy_scene.instantiate()
	candy.position = Vector2(randf_range(100, 1052), -50)

	var r = randf()
	if r < 0.05:
		candy.get_node("Sprite2D").texture = preload("res://assets/Rainbow_Candy.png")
		candy.points = 0
		candy.fall_speed = 200
		candy.is_rainbow = true
	elif r < 0.45:
		candy.get_node("Sprite2D").texture = preload("res://assets/Red_Candy.png")
		candy.points = 10; candy.fall_speed = 220
	elif r < 0.75:
		candy.get_node("Sprite2D").texture = preload("res://assets/Blue_Candy.png")
		candy.points = 15; candy.fall_speed = 250
	elif r < 0.90:
		candy.get_node("Sprite2D").texture = preload("res://assets/Yellow_Candy.png")
		candy.points = 25; candy.fall_speed = 280
	elif r < 0.97:
		candy.get_node("Sprite2D").texture = preload("res://assets/Green_Candy.png")
		candy.points = 5;  candy.fall_speed = 260
	else:
		candy.get_node("Sprite2D").texture = preload("res://assets/Purple_Candy.png")
		candy.points = 50; candy.fall_speed = 300

	candy.fall_speed += (max_time - game_time) * 2.5
	add_child(candy)

func spawn_bomb():
	var bomb = bomb_scene.instantiate()
	bomb.position = Vector2(randf_range(100, 1052), -50)
	bomb.fall_speed = 270 + (max_time - game_time) * 3.5
	add_child(bomb)

func catch_candy(points):
	if double_active:
		points *= 2
	
	if combo_timer > 0:
		combo_count += 1
	else:
		combo_count = 1
	combo_timer = 3.0
	points = int(points * (1 + combo_count * 0.15))
	
	score += points
	score_label.text = "Score: %d" % score
	
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.3,1.3), 0.1)
	tween.tween_property(score_label, "scale", Vector2.ONE, 0.1)
	
	if combo_count > 1:
		var lbl = Label.new()
		lbl.text = "x%d COMBO!" % combo_count
		lbl.add_theme_font_size_override("font_size", 36)
		lbl.global_position = $Basket.global_position - Vector2(0,100)
		add_child(lbl)
		var tw = create_tween()
		tw.tween_property(lbl, "global_position:y", lbl.position.y - 50, 0.8)
		tw.tween_property(lbl, "modulate:a", 0, 0.8)

func catch_bomb():
	lives -= 1
	lives_label.text = "Lives: %d" % lives
	shake_amount = 10.0
	if lives <= 0:
		game_over()

func missed_candy():
	lives -= 1
	lives_label.text = "Lives: %d" % lives
	if lives <= 0:
		game_over()

func activate_shield():
	shield_active = true
	$Basket.modulate = Color(1,1,1,0.5)
	await get_tree().create_timer(5.0).timeout
	shield_active = false
	$Basket.modulate = Color(1,1,1,1)

func activate_double():
	double_active = true
	await get_tree().create_timer(10.0).timeout
	double_active = false

func activate_rainbow_powerup():
	$Basket.scale = Vector2(1.5,1.5)
	await get_tree().create_timer(5.0).timeout
	$Basket.scale = Vector2.ONE

func game_over():
	game_active = false
	spawn_timer.stop()
	final_score_txt.text = "Final Score: %d" % score
	game_over_panel.visible = true
	game_over_panel.scale = Vector2.ZERO
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK); tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(game_over_panel, "scale", Vector2.ONE, 0.5)
	
	var file = FileAccess.open("user://highscores.json", FileAccess.READ)
	var list = []
	if file:
		var json_text = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			list = json.data
	
	list.append(score)
	list.sort_custom(func(a,b): return b > a)
	if list.size() > 5:
		list = list.slice(0, 5)
	
	file = FileAccess.open("user://highscores.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(list))
		file.close()

func _on_restart_pressed():
	get_tree().reload_current_scene()
