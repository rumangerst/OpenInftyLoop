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
	tile.set_tile_type(tile_type)
	tile.set_tile_rotation(tile_rotation)
	tile.rect_size = Vector2(10, 10)
	tile.rect_pivot_offset = Vector2(5, 5)
	tile.rect_position = Vector2(x * 10, y * 10)
	tile.set_name("tile" + str(x) + "_" + str(y))
	
	add_child(tile)
	map_tiles[x + y * map_width] = tile
