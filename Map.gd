extends Control

var tile_size = 32

var map_width = 0
var map_height = 0
var map_tiles = []

func _ready():
	randomize()
	#initialize_map(10, 10)
	#map_generator(3, 8, 4)
	
	deserialize("current.level")
	
func initialize_map(width, height):
	
	# Remove existing tiles
	for child in map_tiles:
		child.queue_free()
	
	map_tiles = []
	for i in range(width * height):
		map_tiles.append(null)
		
	map_width = width
	map_height = height
	
func map_generator(min_generated_lines, min_line_length, max_bouncing):
	
	var generated_lines = 0
	
	while generated_lines < min_generated_lines:
		
		var x = randi() % map_width
		var y = randi() % map_height
		
		if(get_tile(x,y) != null):
			continue
		
		var generator_pre = []		
		for i in range(map_width * map_height):
			generator_pre.append(0)
			
		# Find some path that does not disturb already generated tiles
		var dirUpRight = randi() % 2 == 1
		var dirInvert = 1 if randf() < 0.5 else -1		
		
		# Count how long the generated line will be
		var line_length = 0
		var bounce_count = 0
		 
		while true:			
			if randf() < 0.5:
				dirUpRight = randi() % 2 == 1
				dirInvert = 1 if randf() < 0.5 else -1
				
			var dirX = dirInvert if dirUpRight else 0
			var dirY = dirInvert if not dirUpRight else 0	
				
			x += dirX
			y += dirY
			
			if(get_tile(x,y) != null or x < 0 or x >= map_width or y < 0 or y >= map_height):
				if bounce_count < max_bouncing:
					x -= dirX
					y -= dirY
					bounce_count += 1
				else:
					break
							
			generator_pre[x + y * map_width] = 1
			line_length += 1
		
		# The map must be at least given length (but to prevent deadlock, only require for first line)
		if(line_length < min_line_length and generated_lines == 0):
			generated_lines -= 1
			continue
			
		# Generate the map by simple connection
		for i in range(map_width):
			for j in range(map_height):
				
				var current = generator_pre[i + j * map_width]
				
				if current > 0:
					
					var north = generator_pre[i + (j - 1) * map_width] if j - 1 >= 0 else 0
					var south = generator_pre[i + (j + 1) * map_width] if j + 1 < map_height else 0
					var east = generator_pre[(i + 1) + j * map_width] if i + 1 < map_width else 0
					var west = generator_pre[(i - 1) + j * map_width] if i - 1 >= 0 else 0
					
					var count = north + south + east + west
					
					if count == 1:
						add_tile("end", 0, i, j)
					elif count == 2 and north == south:
						add_tile("straight", 0, i, j)
					elif count == 2 and north != south:
						add_tile("curve", 0, i, j)
					elif count == 3:
						add_tile("tri", 0, i, j)
					elif count == 4:
						add_tile("cross", 0, i, j)
					else:
						print("Empty line generated")
						
				
		generated_lines += 1
	
	
func add_tile(tile_type, tile_rotation, x, y):
	
	remove_tile(x,y)
	print("Adding tile of type " + tile_type + " with rotation " + str(tile_rotation) + " to " + str(x) + ", " + str(y))
	
	var tile = load("Tile.tscn").instance()
	map_tiles[x + y * map_width] = tile
	tile.set_tile_type(tile_type)
	tile.set_tile_rotation(tile_rotation)
	tile.rect_size = Vector2(tile_size, tile_size)
	tile.rect_pivot_offset = Vector2(tile_size / 2.0, tile_size / 2.0)
	tile.rect_position = Vector2(x * tile_size, y * tile_size) + rect_size / 2.0 - Vector2(map_width * tile_size, map_height * tile_size) / 2.0
	tile.set_name("tile" + str(x) + "_" + str(y))
	
	add_child(tile)
	tile.connect("updated_tile_rotation", self, "check_if_solved")
	
	
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
	
func check_if_solved():
	
	if(is_solved()):
		print("Map is solved!")
	else:
		print("Map not solved yet")
		
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

