extends TextureButton

var texture_cross = preload("res://gfx/tiles-new-2/cross.svg")
var texture_curve = preload("res://gfx/tiles-new-2/curve.svg")
var texture_end = preload("res://gfx/tiles-new-2/end.svg")
var texture_straight = preload("res://gfx/tiles-new-2/straight.svg")
var texture_tri = preload("res://gfx/tiles-new-2/tri.svg")

var rotation_animation_speed = 15 # old code: 500
var color_animation_speed = 1

var tile_type = "cross"
var tile_rotation = 0
var tile_connections_unrotated = [1, 1, 1, 1] # NESW
var tile_connections_rotated = [1, 1, 1, 1]
var tile_connections_count = 4

var target_color = Color(0,0,0)
var target_rotation = 0

signal updated_tile_rotation # Triggered if the user rotated the tile

func _ready():
	end_tile_animations()
	get_node("AnimationPlayer").play("ShowTile")
	
func _process(delta):
	
	# Update the rotation
	var rotation_diff = target_rotation - self.rect_rotation
	
	if rotation_diff < 0:
		self.rect_rotation = self.rect_rotation - 360
		rotation_diff = target_rotation - self.rect_rotation
		
	if rotation_diff > 1:
		self.rect_rotation += delta * rotation_diff * rotation_animation_speed
	else:
		self.rect_rotation = self.target_rotation
		
	
#	if( abs(rotation_diff) > delta * rotation_animation_speed ):
#
#		self.rect_rotation += delta * rotation_animation_speed
#
#		if (self.rect_rotation > 360):
#			self.rect_rotation = self.rect_rotation - 360
#
#	else:
#		 self.rect_rotation = self.target_rotation
		
	# Update the color
	var current_color = Vector3(self_modulate.r, self_modulate.g, self_modulate.b)
	var target_color = Vector3(self.target_color.r, self.target_color.g, self.target_color.b)
	var color_diff = target_color - current_color
	
	var new_color = current_color + color_diff * delta / color_animation_speed
	self.self_modulate = Color(new_color[0], new_color[1], new_color[2])
		
	
func end_tile_animations():
	self.rect_rotation = self.target_rotation 

func _pressed():	
	set_tile_rotation(self.tile_rotation + 1)
	$sfxRotate.play()

func set_tile_type(type):
	
	self.tile_type = type
	
	if(type == "cross"):
		self.texture_normal = texture_cross
		self.tile_connections_unrotated = [1,1,1,1]
	elif (type == "curve"):
		self.texture_normal = texture_curve
		self.tile_connections_unrotated = [1,0,0,1]
	elif (type == "end"):
		self.texture_normal = texture_end
		self.tile_connections_unrotated = [1,0,0,0]
	elif (type == "straight"):
		self.texture_normal = texture_straight
		self.tile_connections_unrotated = [1,0,1,0]
	elif (type == "tri"):
		self.texture_normal = texture_tri
		self.tile_connections_unrotated = [1,0,1,1]
	else:
		print("Unknown tile type " + type)
		
	self.tile_connections_count = 0
	for x in self.tile_connections_unrotated:
		self.tile_connections_count += x
	

func get_tile_connection(direction):
	
	if(direction == "north"):
		return self.tile_connections_rotated[0]
	elif(direction == "east"):
		return self.tile_connections_rotated[1]
	elif(direction == "south"):
		return self.tile_connections_rotated[2]
	elif(direction == "west"):
		return self.tile_connections_rotated[3]
	else:
		return null

func set_tile_rotation(tile_rotation):
	
	tile_rotation = tile_rotation % 4
	self.tile_rotation = tile_rotation
	var unrotated = self.tile_connections_unrotated
	
	if(tile_rotation == 0):
		self.tile_connections_rotated = unrotated
		self.target_rotation = (0)
	elif (tile_rotation == 1):
		self.tile_connections_rotated = [unrotated[3], unrotated[0], unrotated[1], unrotated[2]]
		self.target_rotation = (90)
	elif (tile_rotation == 2):
		self.tile_connections_rotated = [unrotated[2], unrotated[3], unrotated[0], unrotated[1]]
		self.target_rotation = (180)
	elif (tile_rotation == 3):
		self.tile_connections_rotated = [unrotated[1], unrotated[2], unrotated[3], unrotated[0]]
		self.target_rotation = (270)
	else:
		print("Unknown rotation " + tile_rotation)
		
	emit_signal("updated_tile_rotation")
