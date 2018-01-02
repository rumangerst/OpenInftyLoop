extends Control

const tile_margins = [10, 10, 10, 50] # Left, Top, Right, Bottom

var map_width = 0
var map_height = 0
var map_tiles = []
var map_color = Color(0,0,0)

signal map_solved # Triggered if the map is solved
signal map_update_color_data(map_color, entropy) # triggered if the color changes

func _ready():
	randomize()	
	get_viewport().connect("size_changed", self, "update_map")

func update_map():
	for x in range(map_width):
		for y in range(map_height):
			update_tile_position(x, y)
	
func initialize_map(width, height):
	
	clear_map()
	
	map_tiles = []
	for i in range(width * height):
		map_tiles.append(null)
		
	map_width = width
	map_height = height
	
func clear_map():
	
	for i in range(len(map_tiles)):
		var child = map_tiles[i]
		if(child != null):
			child.queue_free()
			map_tiles[i] = null
			

func update_map_colors():
	var entropy = get_entropy()
	
	# Update tile colors
	var tile_color = Color(0,0,0).linear_interpolate(map_color, -entropy).darkened(0.5)
	tile_color.r *= 0.8
	tile_color.g *= 0.8
	tile_color.b *= 0.8
	
	for x in range(map_width):
		for y in range(map_height):
			var tile = get_tile(x,y)
			
			if(tile != null):
				tile.target_color = tile_color
	
	# Update the entropy
	emit_signal("map_update_color_data", map_color, entropy)
		

func update_tile_position(x,y):
	
	var available_width = rect_size.x - tile_margins[0] - tile_margins[2]
	var available_height = rect_size.y - tile_margins[1] - tile_margins[3]
	
	var tile = get_tile(x,y)
	var tile_size = round(min(128, min(available_width / map_width, available_height / map_height)))
	
	
	if(tile != null):
		tile.rect_size = Vector2(tile_size, tile_size)
		tile.rect_pivot_offset = Vector2(tile_size / 2.0, tile_size / 2.0)
		tile.rect_position = Vector2(x * tile_size, y * tile_size) + rect_size / 2.0 - Vector2(map_width * tile_size, map_height * tile_size) / 2.0
	
	
func add_tile(tile_type, tile_rotation, x, y):
	
	remove_tile(x,y)
	print("Adding tile of type " + tile_type + " with rotation " + str(tile_rotation) + " to " + str(x) + ", " + str(y))
	
	var tile = load("Tile.tscn").instance()
	map_tiles[x + y * map_width] = tile
	tile.set_tile_type(tile_type)
	tile.set_tile_rotation(tile_rotation)
	tile.set_name("tile" + str(x) + "_" + str(y))
	update_tile_position(x, y)
	
	get_node("Tiles").add_child(tile)
	tile.connect("updated_tile_rotation", self, "check_if_solved")
	tile.connect("updated_tile_rotation", self, "update_map_colors")
	
	
func get_tile(x,y):
	if(x < 0 or x >= map_width or y < 0 or y >= map_height):
		return null
	return map_tiles[x + y * map_width]
	
func remove_tile(x,y):
	
	var tile = get_tile(x,y)
	if(tile != null):
		tile.queue_free()
	
func get_tile_connection_from(x, y, direction):	
	
	if(direction == "north"):
		var tile = get_tile(x, y - 1)		
		if(tile !=  null):
			return tile.get_tile_connection("south")
			
	elif(direction == "east"):		
		var tile = get_tile(x + 1, y)		
		if(tile !=  null):
			return tile.get_tile_connection("west")
			
	elif(direction == "south"):		
		var tile = get_tile(x, y + 1)		
		if(tile !=  null):
			return tile.get_tile_connection("north")
			
	elif(direction == "west"):		
		var tile = get_tile(x - 1, y)		
		if(tile !=  null):
			return tile.get_tile_connection("east")
	else:
		print("Unknown direction " + direction)
		
	return null
	
func is_fully_connected(x, y):
	
	var tile = get_tile(x, y)
	
	if(tile == null):
		return true
	
	for dir in ["north", "east", "south", "west"]:
		if(tile.get_tile_connection(dir) == 1):
			if(get_tile_connection_from(x,y,dir) != 1):
				return false
	
	return true
	
func is_solved():
		
	for x in range(map_width):
		for y in range(map_height):
			if(!is_fully_connected(x, y)):
				return false
	
	return true
	
func get_entropy():	
	
	var entropy = 0
	var max_entropy = 0
		
	for x in range(map_width):
		for y in range(map_height):
			if(get_tile(x,y) != null):
				max_entropy += 1
				if(is_fully_connected(x, y)):
					entropy -= 1
	
	return entropy / float(max_entropy)
	
func check_if_solved():
	
	if(is_solved()):
		print("Map is solved!")
		
		# Color the map white
		map_color = Color(1,1,1)
		update_map_colors()
		
		emit_signal("map_solved")
		
func serialize(filename):
	var tile_list = []
	
	for x in range(map_width):
		for y in range(map_height):
			var tile = get_tile(x,y)
			
			if tile != null:
				tile_list.append({
					type = tile.tile_type,
					rotation = tile.tile_rotation,
					x = x,
					y = y
					})		
	
			
	var data = {
		tiles = tile_list,
		width = map_width,
		height = map_height
	}
		
	var savegame = File.new()
	savegame.open("user://" + filename, File.WRITE)
	savegame.store_string(to_json(data))
	savegame.close()
	
func deserialize(filename):
	var savegame = File.new()
	savegame.open("user://" + filename, File.READ)
	var data = parse_json(savegame.get_as_text())
	savegame.close()
	
	var width = data["width"]
	var height = data["height"]
	
	initialize_map(width, height)
	
	for tiledata in data["tiles"]:
		
		var x = int(tiledata["x"])
		var y = int(tiledata["y"])
		var type = tiledata["type"]
		var rotation = int(tiledata["rotation"])
		
		add_tile(type, rotation, x, y)

