extends Node

# obstacle scenes
var balloon_scene = preload("res://Scenes/balloon.tscn")
var tree_scene = preload("res://Scenes/tree.tscn")
var castle_scene = preload("res://Scenes/castle.tscn")
var rock_scene = preload("res://Scenes/rock.tscn")
var obstacle_types := [tree_scene, castle_scene, rock_scene]
var obstacles : Array
var can_collide : bool

# reward scenes
var gem_scene = preload("res://Scenes/gem.tscn")
var fire_scene = preload("res://Scenes/fire.tscn")
var loc := [100, 400]
var gems: Array
var fires: Array

# Attack
var fireball_scene = preload("res://Scenes/fireball.tscn")
var atk_btn = preload("res://sceneassets/attack.tres")

# game constants
const DRAG_START_POS := Vector2i(219, 222)
const CAM_START_POS := Vector2i(576, 324)

var speed : float
const START_SPEED : float = 3.0
const MAX_SPEED : int = 25
var screen_size : Vector2i
var ground_height : int
var game_running : bool
var speed_inc : int
var score : int
var lives : int
var fire_atk : int
var last_obs 
var last_gem
var last_fire

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_window().size
	ground_height = 122
	$GAMEOVER.get_node("RESTART").pressed.connect(new_game)
	new_game()

func new_game():
	lives = 3
	speed_inc = 0
	score = 0
	fire_atk = 0
	show_lives()
	show_score()
	can_collide = true
	game_running = false
	get_tree().paused = false
	
	$HUD.get_node("KILGHARRAH").show()
	$HUD.get_node("KILGHARRAH2").show()
	$HUD.get_node("Bg").show()
	$HUD.get_node("START").show()
	$GAMEOVER.hide()
	
	$Dragon.position = DRAG_START_POS
	$Dragon.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POS
	$GROUND.position = Vector2i(0, 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if game_running:
		speed = START_SPEED + speed_inc / 10000
		if speed > MAX_SPEED:
			speed = MAX_SPEED
	
		show_score()
		show_lives()
		
		# obstacles
		generate_obs()
		
		# rewards
		generate_gem()
		generate_fire()
		
		speed_inc += speed
		# move dragon and cam
		$Dragon.position.x += speed
		$Camera2D.position.x += speed
	
		if $Camera2D.position.x - $GROUND.position.x > screen_size.x * 1.5:
			$GROUND.position.x += screen_size.x
			
		# free memory
		if not obstacles.is_empty():
			for obs in obstacles:
				if obs == null:
					pass
				else:
					if obs.position.x < ($Camera2D.position.x - screen_size.x):
						del_obs(obs)
		
	else:
		if Input.get_action_strength("start"):
			game_running = true
			$HUD.get_node("KILGHARRAH").hide()
			$HUD.get_node("KILGHARRAH2").hide()
			$HUD.get_node("Bg").hide()
			$HUD.get_node("START").hide()
	
func generate_obs():
	# ground obs
	if obstacles.is_empty() or last_obs.position.x < speed_inc + randi_range(300, 500):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs
		obs = obs_type.instantiate()
		var obs_height = obs.get_node("Sprite2D").texture.get_height()
		var obs_scale = obs.get_node("Sprite2D").scale
		var obs_x : int = screen_size.x + speed_inc + 100
		var obs_y : int = screen_size.y - ground_height - (obs_height * obs_scale.y / 2) + 5
		last_obs = obs
		spawn_obs(obs, obs_x, obs_y)
		# sky obs
		if (randi() % 2) == 0:
			obs = balloon_scene.instantiate()
			var ballobs_x : int = screen_size.x + speed_inc + 100
			var ballobs_y : int = 100
			spawn_obs(obs, ballobs_x, ballobs_y)
	
func spawn_obs(obs, x, y):
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs)
	obstacles.append(obs)

func del_obs(obs):
	obs.queue_free()
	obstacles.erase(obs)

func hit_obs(body):
	if can_collide and body.name == "Dragon":
		lives -= 1
		can_collide = false
		$Dragon.get_node("dragon").play("HURT")
		if lives == 0:
			game_over()
		#Wait
		await get_tree().create_timer(1.0).timeout
		#Do
		can_collide = true
		$Dragon.get_node("dragon").play("IDLE")

func generate_gem():
	if gems.is_empty() or last_gem.position.x < speed_inc + randi_range(300, 500):
		if (randi() % 2) == 0:
			var gem
			gem = gem_scene.instantiate()
			var gem_height = gem.get_node("Sprite2D").texture.get_height()
			var gem_scale = gem.get_node("Sprite2D").scale
			var gem_x : int = screen_size.x + speed_inc + 500
			var gem_y : int = loc[randi() % loc.size()]
			last_gem = gem
			spawn_gem(gem, gem_x, gem_y)

func spawn_gem(gem, x, y):
	gem.position = Vector2i(x, y)
	gem.body_entered.connect(hit_gem)
	add_child(gem)
	gems.append(gem)

func hit_gem(body):
	if body.name == "Dragon":
		score += 1

func del_gems(gem):
	gem.queue_free()
	obstacles.erase(gem)

func generate_fire():
	if fires.is_empty() or last_fire.position.x < speed_inc + randi_range(300, 500):
		if (randi() % 2) == 0:
			var fire
			fire = fire_scene.instantiate()
			var fire_height = fire.get_node("Sprite2D").texture.get_height()
			var fire_scale = fire.get_node("Sprite2D").scale
			var fire_x : int = screen_size.x + speed_inc + 300
			var fire_y : int = loc[randi() % loc.size()]
			last_fire = fire
			spawn_fire(fire, fire_x, fire_y)

func spawn_fire(fire, x, y):
	fire.position = Vector2i(x, y)
	fire.body_entered.connect(hit_fire)
	add_child(fire)
	fires.append(fire)

func hit_fire(body):
	if body.name == "Dragon":
		fire_atk += 1

func del_fires(fire):
	fire.queue_free()
	fires.erase(fire)

func show_score():
	$HUD.get_node("Score").text = str(score)
	$GAMEOVER.get_node("HS").text = str(score)

func show_lives():
	$HUD.get_node("NumLife").text = str(lives)

func game_over():
	get_tree().paused = true
	game_running = false
	$GAMEOVER.show()

func _on_dragon_spawn_fireball(location):
	var fball = fireball_scene.instantiate()
	fball.global_position = location
	add_child(fball)
