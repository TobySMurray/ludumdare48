extends Camera2D

export (NodePath) var init_anchor
onready var anchor = get_node(init_anchor)
onready var smooth_anchor_pos = anchor.global_position
var base_offset = Vector2.ZERO
var smooth_base_offset = base_offset

var mouse_follow = 0

var trauma = 0
export var decay = 5  # How quickly the shaking stops [0, 1].
export var max_offset = Vector2(100, 75)  # Maximum hor/ver shake in pixels.
export var max_roll = 0.1  # Maximum rotation in radians (use sparingly).


func _ready():
	GameManager.camera = self

func _physics_process(delta):
	if anchor:
		base_offset = (get_global_mouse_position() - anchor.global_position)*mouse_follow
		smooth_anchor_pos = lerp(smooth_anchor_pos, anchor.global_position, 0.15)
		smooth_base_offset = lerp(smooth_base_offset, base_offset, 0.5)
		global_position = smooth_anchor_pos + base_offset
		
		if trauma:
			trauma = max(trauma - trauma*decay*delta, 0)
			shake()
			
func set_trauma(amount, new_decay = 8):
	decay = min(decay, new_decay)
	trauma = max(trauma, amount)
			
func shake():
	var amount = pow(trauma, 2)
	rotation = max_roll * amount * (randf()-0.5)
	offset.x = max_offset.x * amount * (randf()-0.5)
	offset.y = max_offset.y * amount * (randf()-0.5)


