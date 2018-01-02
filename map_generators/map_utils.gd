#
# Contains shared method between map generators
#

# Generates the tiles of a map from a 2D matrix with 1 and 0. Automatically fully connects all
# tiles accordingly
# To prevent unwanted connections, apply this algorithm on different matrices
static func generate_map_from_generator_pre(map_node, generator_pre):
	
	var map_width = map_node.map_width
	var map_height = map_node.map_height	
	
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
					map_node.add_tile("end", 0, i, j)
				elif count == 2 and north == south:
					map_node.add_tile("straight", 0, i, j)
				elif count == 2 and north != south:
					map_node.add_tile("curve", 0, i, j)
				elif count == 3:
					map_node.add_tile("tri", 0, i, j)
				elif count == 4:
					map_node.add_tile("cross", 0, i, j)
				else:
					print("Empty line generated")

# Shuffles the tiles until they are no solution
static func make_non_solution(map_node):
	shuffle_tiles(map_node)
	
	while(map_node.is_solved()):
		shuffle_tiles(map_node)
	
static func shuffle_tiles(map_node):	
	for tile in map_node.map_tiles:
		if(tile != null):
			tile.set_tile_rotation(randi() % 4)
			tile.end_tile_animations()