extends Node2D

var map_width = 0
var map_height = 0
var map_tiles = []

func _ready():
	initialize_map(5, 5)
	add_tile("end", 0, 0, 0)
	add_tile("straight", 0, 1, 0)
	add_tile("straight", 0, 2, 0)
	add_tile("tri", 0, 3, 0)
	add_tile("end", 0, 4, 0)
	add_tile("end", 0, 3, 1)
	
func initialize_map(width, height):
	
	map_tiles = []
	for i in range(width * height):
		map_tiles.append(null)
		
	map_width = width
	map_height = height
	
func add_tile(tile_type, tile_rotation, x, y):
	
	print("Adding tile of type " + tile_type + " with rotation " + str(tile_rotation) + " to " + str(x) + ", " + str(y))
	
	var tile = load("Tile.tscn").instance()
	map_tiles[x + y * map_width] = tile
	tile.set_tile_type(tile_type)
	tile.set_tile_rotation(tile_rotation)
	tile.rect_size = Vector2(10, 10)
	tile.rect_pivot_offset = Vector2(5, 5)
	tile.rect_position = Vector2(x * 10, y * 10)
	tile.set_name("tile" + str(x) + "_" + str(y))
	
	add_child(tile)
	tile.connect("updated_tile_rotation", self, "check_if_solved")
	
func get_tile(x,y):
	if(x < 0 or x >= map_width or y < 0 or y >= map_height):
		return null
	return map_tiles[x + y * map_width]
	
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
	
func check_if_solved():
	
	if(is_solved()):
		print("Map is solved!")
	else:
		print("Map not solved yet")
