extends TextureButton

const INTERACT_VALUE_STEP = 0.1

signal value_changed(value)

var texture0 = load("res://gfx/ui/volume_0.svg")
var texture20 = load("res://gfx/ui/volume_20.svg")
var texture40 = load("res://gfx/ui/volume_40.svg")
var texture60 = load("res://gfx/ui/volume_60.svg")
var texture80 = load("res://gfx/ui/volume_80.svg")
var texture100 = load("res://gfx/ui/volume_100.svg")

var value = 0
var interact_value_direction = 1

func _ready():
	self.connect("pressed", self, "on_interact")
	
	update_texture()
	
func _gui_input(event):
	
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			accept_event()
			interact_value_direction = 1.0
			set_value(value + INTERACT_VALUE_STEP)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			accept_event()
			interact_value_direction = -1.0
			set_value(value - INTERACT_VALUE_STEP)
			
func load_textures_from_files(prefix):
	texture0 = load(prefix + "_0.svg")
	texture20 = load(prefix + "_20.svg")
	texture40 = load(prefix + "_40.svg")
	texture60 = load(prefix + "_60.svg")
	texture80 = load(prefix + "_80.svg")
	texture100 = load(prefix + "_100.svg")
	update_texture()
	
func on_interact():
	var old = round(value * 10.0) / 10.0
	var candidate = old + interact_value_direction * INTERACT_VALUE_STEP
	
	if candidate < 0 or candidate > 1:
		interact_value_direction *= -1.0
		candidate = old + interact_value_direction * INTERACT_VALUE_STEP
		
	set_value(candidate)
	
func set_value(v):
	value = clamp(v, 0, 1)
	update_texture()
	
	emit_signal("value_changed", value)
	
func get_value():
	return value

func update_texture():
	if value == 1:
		self.texture_normal = texture100
	elif value >= 0.8:
		self.texture_normal = texture80
	elif value >= 0.6:
		self.texture_normal = texture60
	elif value >= 0.4:
		self.texture_normal = texture40
	elif value >= 0.2:
		self.texture_normal = texture20
	else:
		self.texture_normal = texture0