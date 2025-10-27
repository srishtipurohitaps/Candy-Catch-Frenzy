extends Node2D

@onready var background = $ColorRect
@onready var spawn_timer = $SpawnTimer
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var lives_label = $CanvasLayer/LivesLabel
@onready var timer_label = $CanvasLayer/TimerLabel
@onready var level_label = $CanvasLayer/LevelLabel
@onready var camera = $Camera2D
@onready var game_over_panel = $CanvasLayer/GameOverPanel
@onready var final_score_txt = $CanvasLayer/GameOverPanel/VBoxContainer/FinalScore
@onready var restart_button = $CanvasLayer/GameOverPanel/VBoxContainer/RestartButton

var candy_scene = preload("res://candy.tscn")
var bomb_scene = preload("res://bomb.tscn")

const LEVEL_NUMBER = 1
var bomb_chance = 0.16
var spawn_wait_start = 1.0
var max_time = 60.0
var max_lives = 5
var life_threshold = 50

var score = 0
var lives = 3
var game_time = 60.0
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
	level_label.text = "Level %d" % LEVEL_NUMBER

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
	spawn_timer.wait_time = max(0.3, spawn_wait_start - ((max_time - game_time) / 120.0))
	
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
		candy.points = 10; candy.fall_speed = 200
	elif r < 0.75:
		candy.get_node("Sprite2D").texture = preload("res://assets/Blue_Candy.png")
		candy.points = 15; candy.fall_speed = 220
	elif r < 0.90:
		candy.get_node("Sprite2D").texture = preload("res://assets/Yellow_Candy.png")
		candy.points = 25; candy.fall_speed = 250
	elif r < 0.97:
		candy.get_node("Sprite2D").texture = preload("res://assets/Green_Candy.png")
		candy.points = 5; candy.fall_speed = 230
	else:
		candy.get_node("Sprite2D").texture = preload("res://assets/Purple_Candy.png")
		candy.points = 50; candy.fall_speed = 280

	candy.fall_speed += (max_time - game_time) * 1.5
	
	candy.scale = Vector2(0.5, 0.5)
	var tw = create_tween()
	tw.tween_property(candy, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	add_child(candy)

func spawn_bomb():
	var bomb = bomb_scene.instantiate()
	bomb.position = Vector2(randf_range(100, 1052), -50)
	bomb.fall_speed = 240 + (max_time - game_time) * 2.5
	
	var sprite = bomb.get_node("Sprite2D")
	var tw = create_tween().set_loops()
	tw.tween_property(sprite, "modulate", Color(1.3, 0.5, 0.5), 0.3)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	
	add_child(bomb)

func catch_candy(points):
	if double_active:
		points *= 2
	
	if combo_timer > 0:
		combo_count += 1
	else:
		combo_count = 1
	combo_timer = 3.0
	points = int(points * (1 + combo_count * 0.1))
	
	var old_score = score
	score += points
	score_label.text = "Score: %d" % score
	
	if score / life_threshold > old_score / life_threshold:
		if lives < max_lives:
			lives += 1
			lives_label.text = "Lives: %d" % lives
			show_life_gain()
	
	$Basket.modulate = Color(1.5, 1.5, 0.5)
	var blink = create_tween()
	blink.tween_property($Basket, "modulate", Color.WHITE, 0.2)
	
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.3,1.3), 0.1)
	tween.tween_property(score_label, "scale", Vector2.ONE, 0.1)
	
	if combo_count > 1:
		var lbl = Label.new()
		lbl.text = "x%d COMBO!" % combo_count
		lbl.add_theme_font_size_override("font_size", 36)
		lbl.modulate = Color(1, 0.8, 0)
		lbl.global_position = $Basket.global_position - Vector2(0,100)
		add_child(lbl)
		var tw = create_tween()
		tw.tween_property(lbl, "global_position:y", lbl.position.y - 50, 0.8)
		tw.parallel().tween_property(lbl, "modulate:a", 0, 0.8)
		tw.tween_callback(lbl.queue_free)

func show_life_gain():
	var lbl = Label.new()
	lbl.text = "+1 LIFE!"
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.modulate = Color(0.3, 1.0, 0.3)
	lbl.global_position = $Basket.global_position - Vector2(0, 80)
	add_child(lbl)
	var tw = create_tween()
	tw.tween_property(lbl, "global_position:y", lbl.position.y - 50, 0.8)
	tw.parallel().tween_property(lbl, "modulate:a", 0, 0.8)
	tw.tween_callback(lbl.queue_free)
	
	var pulse = create_tween()
	pulse.tween_property(lives_label, "scale", Vector2(1.5,1.5), 0.15)
	pulse.tween_property(lives_label, "scale", Vector2.ONE, 0.15)

func catch_bomb():
	lives -= 1
	lives_label.text = "Lives: %d" % lives
	shake_amount = 12.0
	
	background.modulate = Color(1.5, 0.5, 0.5)
	var flash = create_tween()
	flash.tween_property(background, "modulate", Color.WHITE, 0.3)
	
	if lives <= 0:
		game_over()

func missed_candy():
	lives -= 1
	lives_label.text = "Lives: %d" % lives
	if lives <= 0:
		game_over()

func activate_shield():
	shield_active = true
	$Basket.modulate = Color(0.5, 0.5, 1.0, 0.7)
	await get_tree().create_timer(5.0).timeout
	shield_active = false
	$Basket.modulate = Color.WHITE

func activate_double():
	double_active = true
	score_label.modulate = Color(1.0, 0.8, 0.0)
	await get_tree().create_timer(10.0).timeout
	double_active = false
	score_label.modulate = Color.WHITE

func activate_rainbow_powerup():
	lives = 3
	lives_label.text = "Lives: %d" % lives
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
	LevelManager.next_level()
