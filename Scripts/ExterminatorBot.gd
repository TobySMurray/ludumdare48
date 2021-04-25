extends "res://Scripts/Enemy.gd"

onready var teleport_sprite = $TeleportSprite
onready var deflector_shape = $Deflector/CollisionShape2D

var teleport_start_point = Vector2.ZERO
var teleport_end_point = Vector2.ZERO
var charging_tp = false
var teleport_timer = 0
var walk_speed = 50

# Called when the node enters the scene tree for the first time.
func _ready():
	health = 200
	max_speed = walk_speed
	flip_offset = 24
	
func _process(delta):
	if charging_tp:
		teleport_timer -= delta
		if teleport_timer < 0.1:
			animplayer.play("Appear")
			if teleport_timer < 0:
				teleport()
			
func player_action():
	if Input.is_action_just_pressed("attack2") and special_cooldown < 0:
		start_teleport();
	
func start_teleport():
	charging_tp = true
	attacking = true
	teleport_start_point = global_position
	teleport_end_point = get_global_mouse_position()
	special_cooldown = 1.6
	teleport_timer = 0.4
	lock_aim = true
	max_speed = 0
	sprite.visible = false
	
	teleport_sprite.global_position = teleport_start_point
	teleport_sprite.frame = 0
	teleport_sprite.play("Vanish")
	
func teleport():
	charging_tp = false
	global_position = teleport_end_point
	teleport_sprite.global_position = teleport_start_point
	animplayer.play("Appear")
	sprite.visible = true
	invincible = true
	
func area_deflect():
	deflect(deflector_shape, true)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Appear":
		lock_aim = false
		max_speed = walk_speed
		attacking = false
		invincible = false
	elif anim_name == "Die":
		queue_free()
