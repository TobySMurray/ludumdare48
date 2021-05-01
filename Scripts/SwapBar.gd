extends TextureProgress

var max_control_time = 15
var swap_threshold = 1

var control_timer = 0

onready var threshold = $Threshold
onready var audio = $AudioStreamPlayer
onready var warning = preload("res://Sounds/SoundEffects/warning.wav")
onready var ready = preload("res://Sounds/SoundEffects/moonready.wav")


var colors = [Color(1,0.8,0.8,1),Color(1,0.5,0.5,1), Color(1,1,1,1)]
		
func _ready():
	self.value = 0
	GameManager.swap_bar = self
	threshold.max_value = max_control_time
	threshold.value = swap_threshold

func _physics_process(delta):
	control_timer = min(control_timer + delta, 100)
	
	self.value = (control_timer / max_control_time) * 100
	
	GameManager.swappable = control_timer > swap_threshold
	
	if control_timer < max_control_time - 3:
		in_control()
	if control_timer > max_control_time - 3:
		out_of_control()
	if control_timer > max_control_time - 0.5:
		GameManager.kill()
		audio.stop()

func reset(init_timer = 0):
	GameManager.out_of_control = false
	audio.stop()
	control_timer = init_timer
	set_swap_threshold(swap_threshold + 3)
	
func set_swap_threshold(value):
	swap_threshold = clamp(value, 0, 15)
	threshold.value = swap_threshold

func out_of_control():
	GameManager.out_of_control = true
	tint_progress = lerp(tint_progress, colors[randi() % colors.size()], 0.9)
	audio.stream = warning
	audio.play()

func in_control():
	if control_timer < swap_threshold:
		tint_progress = lerp(tint_progress, Color(0.58,0.43,0.1,1), 0.5)
	else:
		#audio.stream = ready
		#audio.play()
		tint_progress = lerp(tint_progress, Color(0.58,0.1,0.1,1), 0.1)
