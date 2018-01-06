extends TextureButton

const INTERACT_VALUE_STEP = 0.1
const SCROLL_VALUE_STEP = 0.05

signal value_changed(value)

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
			set_value(value + SCROLL_VALUE_STEP)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			accept_event()
			interact_value_direction = -1.0
			set_value(value - SCROLL_VALUE_STEP)
	
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
	var opacity_bar0 = clamp(value * 2.0, 0, 1)
	var opacity_bar1 = clamp((value - 0.5) / 0.5, 0, 1) 
	
	$bar0.modulate = Color(1,1,1,opacity_bar0)
	$bar1.modulate = Color(1,1,1,opacity_bar1)
	
func set_icon(texture):	
	$icon.texture = texture
	
	