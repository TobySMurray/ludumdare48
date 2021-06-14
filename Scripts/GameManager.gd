extends Node

onready var explosion = load("res://Scenes/Explosion.tscn")
onready var boss_marker = load("res://Scenes/BossMarker.tscn").instance()
onready var splatter_particles = load("res://Scenes/SplatterParticles.tscn")

onready var shotgun_bot = load("res://Scenes/ShotgunnerBot.tscn")
onready var wheel_bot = load("res://Scenes/WheelBot.tscn")
onready var archer_bot = load("res://Scenes/ArcherBot.tscn")
onready var chain_bot = load("res://Scenes/ChainBot.tscn")
onready var flame_bot = load("res://Scenes/FlamethrowerBot.tscn")
onready var exterminator_bot = load("res://Scenes/ExterminatorBot.tscn")
onready var sorcerer_bot = load("res://Scenes/SorcererBot.tscn")
onready var saber_bot = load("res://Scenes/SaberBot.tscn")
onready var viewport = get_viewport()

onready var enemies = [shotgun_bot, wheel_bot, archer_bot, chain_bot, flame_bot, exterminator_bot, sorcerer_bot, saber_bot]

onready var SFX = AudioStreamPlayer.new()
onready var swap_unlock_sound = load("res://Sounds/SoundEffects/Wub1.wav")

signal on_swap

const levels = [
	{
		'map_bounds': Rect2(-500, -250, 2500, 1150),
		'enemy_weights': [1, 1, 0.3, 1, 0.66, 0.3, 0.2, 0],
		'enemy_density': 7,
		'pace': 1.0,
		'dark': false
	},
	{
		'map_bounds': Rect2(-315, -260, 2140, 1510),
		'enemy_weights': [1, 0.66, 0.4, 1, 1, 0.2, 0.2, 0.5],
		'enemy_density': 11,
		'pace': 0.6,
		'dark': true
	}
]

var level_name = "Level1"
var level = levels[0]

var timescale = 1
var target_timescale = 1

var swappable = false

var swap_bar
var player
var camera
var transcender
var total_score = 0
var game_HUD
var ground
var obstacles
var wall
var audio
var player_bullets = []

var variety_bonus = 1.0
var swap_history = ['merchant']

var out_of_control = false

onready var game_time = 0
var spawn_timer = 0
var enemy_soft_cap
var enemy_count = 1
var enemy_hard_cap = 15
var cur_boss = null

var evolution_thresholds = [0, 300, 1000, 2000, 3500, 5000, 999999]
var evolution_level = 1

func _ready():
	add_child(SFX)

func _process(delta):
	if is_instance_valid(player):
		game_time += delta
		spawn_timer -= delta
		timescale = lerp(timescale, target_timescale, delta*12)
		#audio.pitch_scale = timescale
		Engine.time_scale =  timescale
		
		if spawn_timer < 0:
			spawn_timer = 1
			enemy_soft_cap = level["enemy_density"]*(1 + game_time*0.01*level['pace']) #pow(1.3, game_time/60)
			
			if randf() < (1 - enemy_count/enemy_soft_cap):
				print("SPAWN (" + str(enemy_count + 1) +")")
				spawn_enemy()
				
		if is_instance_valid(cur_boss):
			if is_point_offscreen(cur_boss.global_position):
				boss_marker.visible = int(game_time*6)%2 == 0
				
				var screen_size = camera_bounds()
				var to_boss = cur_boss.global_position - player.global_position
				var h = screen_size.x/max(abs(to_boss.x), 1)
				var v = screen_size.y/max(abs(to_boss.y), 1)
				
				if h < v:
					boss_marker.position = to_boss*h - Vector2(20*sign(to_boss.x), 0)
				else:
					boss_marker.position = to_boss*v - Vector2(0, 20*sign(to_boss.y))
				
				if to_boss.x > 0:
					if to_boss.y > 0:
						boss_marker.region_rect.position.x = 0
					else:
						boss_marker.region_rect.position.x = 32
				else:
					if to_boss.y > 0:
						boss_marker.region_rect.position.x = 96
					else:
						boss_marker.region_rect.position.x = 64
				
				
			else:
				boss_marker.visible = false
			


func lerp_to_timescale(scale):
	target_timescale = scale
	
func spawn_explosion(pos, source, size = 1, damage = 20, force = 200, delay = 0, show_visual = true):
	var new_explosion = explosion.instance().duplicate()
	new_explosion.global_position = pos
	new_explosion.source = source
	new_explosion.scale = Vector2(size, size)
	new_explosion.damage = damage
	new_explosion.force = force
	new_explosion.delay_timer = delay
	new_explosion.visible = show_visual
	get_node("/root").add_child(new_explosion)
	
func spawn_blood(origin, rot, speed = 500, amount = 20, spread = 5):
	var spray = splatter_particles.instance().duplicate()
	get_node("/root/"+ level_name + "/WorldObjects").add_child(spray)
	spray.global_position = origin
	spray.rotation = rot
	spray.process_material.initial_velocity = speed
	spray.amount = amount
	spray.process_material.spread = spread
	spray.emitting = true
	
func spawn_enemy():
	if not player: return
	
	var spawn_point = random_map_point(true)
	if not spawn_point: return
	
	var spawning_boss = not cur_boss and total_score > evolution_thresholds[evolution_level]
	
	enemy_count += 1
	var new_enemy = choose_weighted(enemies, level['enemy_weights']).instance().duplicate()
	new_enemy.add_to_group("enemy")
	
	if spawning_boss:
		cur_boss = new_enemy
		new_enemy.is_boss = true
		new_enemy.enemy_evolution_level = evolution_level+1
		new_enemy.add_swap_shield(new_enemy.health*(evolution_level*0.5 + 1.5))
		new_enemy.scale = Vector2(1.25, 1.25)
		get_node("/root/"+ level_name +"/Camera2D").add_child(boss_marker)
		
	else:
		var d = game_time/30*level["pace"]
		if randf() < (d/(d+3)/2):
			new_enemy.add_swap_shield(randf()*d*5)

	new_enemy.global_position = spawn_point - Vector2(0, new_enemy.get_node("CollisionShape2D").position.y)
	print("LN " + level_name)
	get_node("/root/"+ level_name +"/WorldObjects/Characters").add_child(new_enemy)
			

func reset():
	total_score = 0
	set_evolution_level(1)
	timescale = 1
	game_time = 0
	spawn_timer = 0
	enemy_count = 1
	swap_history = ['merchant']
	player = null
	boss_marker = load("res://Scenes/BossMarker.tscn").instance()
	
func load_level_props(lv_name):
	level_name = lv_name
	if lv_name != "MainMenu":
		level = levels[int(lv_name[-1])-1]

func kill():
	swappable = false
	player.die()
	
func set_evolution_level(lv):
	evolution_level = min(lv, 6) #min(evolution_level + value/(200+200.0*int(evolution_level)), 5) 
	game_HUD.get_node("EVLShake").get_node("EVL").set_digit(evolution_level)
	game_HUD.get_node("EVLShake").get_node("EVL").express_hype()
	game_HUD.get_node("EVLShake").set_trauma(evolution_level*2)
	
func update_variety_bonus():
	var cur_name = swap_history[-1]
	if swap_history[-2] == cur_name:
		variety_bonus = 0.8
		return
	
	variety_bonus = 0.9
	var used = [cur_name]
	for i in range(2, min(len(swap_history)+1, 8)):
		if not swap_history[-i] in used:
			used.append(swap_history[-i]) 
			variety_bonus += 0.1
		
func increase_score(value):
	var swap_thresh_reduction = value/33/(1 + game_time/200*level["pace"])
	swap_bar.set_swap_threshold(swap_bar.swap_threshold - swap_thresh_reduction)
		
	total_score += value
	game_HUD.get_node("ScoreDisplay").get_node("Score").score = total_score
	
func signal_player_swap():
	emit_signal("on_swap")
	
func random_map_point(off_screen_required = false):
	var i = 0
	var bounds = level['map_bounds']
	while(i < 1000):
		i += 1
		var point = Vector2(bounds.position.x + randf()*bounds.size.x, bounds.position.y + randf()*bounds.size.y)
		if is_point_in_bounds(point) and (not off_screen_required or is_point_offscreen(point, 20)):
			return point
		
	
func is_point_in_bounds(global_point):
	var ground_points = ground.world_to_map(global_point)
	var marble_point = wall.world_to_map(global_point)
	var obstacles_point = obstacles.world_to_map(global_point)
	
	return ground_points in ground.get_used_cells() and not marble_point in wall.get_used_cells() and not obstacles_point in obstacles.get_used_cells()
	
func is_point_offscreen(point, margin = 0):
	var bounds = camera_bounds()
	var from_camera = point - camera.global_position
	return abs(from_camera.x) > bounds.x + margin or abs(from_camera.y) > bounds.y + margin
	
func camera_bounds():
	var ctrans = camera.get_canvas_transform()
	var view_size = camera.get_viewport_rect().size / ctrans.get_scale()
	return view_size/2
	
static func choose_weighted(values, weights):
	var cumu_weights = [weights[0]]
	for i in range(1, len(weights)):
		cumu_weights.append(weights[i] + cumu_weights[i-1])
	
	var rand = randf()*cumu_weights[-1]
	for i in range(cumu_weights.size()):
		if rand < cumu_weights[i]:
			return values[i]
