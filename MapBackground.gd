extends Control

var target_color = Color(0,0,0)
var color_animation_speed = 1

func _ready():
	pass

func _process(delta):
	
	# Update the color
	var current_color = Vector3(self_modulate.r, self_modulate.g, self_modulate.b)
	var target_color = Vector3(self.target_color.r, self.target_color.g, self.target_color.b)
	var color_diff = target_color - current_color
	
	var new_color = current_color + color_diff * delta / color_animation_speed
	self.self_modulate = Color(new_color[0], new_color[1], new_color[2])
	
func update_color_data(map_color, entropy):
	# Update background color
	var bgr_color = Color("#bbbbbb").linear_interpolate(map_color, -entropy).lightened(0.5)
	self.target_color = bgr_color
	
func skip_animation():
	self.self_modulate = target_color