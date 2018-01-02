#
# Random map generator with symmetry
#

static func map_generator_nosolution(map_node, min_generated_lines, min_line_length, max_bouncing):
	
	map_generator(map_node, min_generated_lines, min_line_length, max_bouncing)
	
	while map_node.is_solved():
		map_node.clear_map() 
		map_generator(map_node, min_generated_lines, min_line_length, max_bouncing)
	

static func map_generator(map_node, min_generated_lines, min_line_length, max_bouncing):
	
	var full_map_width = map_node.map_width
	var map_width = int(map_node.map_width / 2)
	var map_height = map_node.map_height	
	
	var generated_lines = 0
	
	while generated_lines < min_generated_lines:
		
		var x = randi() % map_width
		var y = randi() % map_height
		
		if(map_node.get_tile(x,y) != null):
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
			
			if(map_node.get_tile(x,y) != null or x < 0 or x >= map_width or y < 0 or y >= map_height):
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
					
					var random_rotation = randi() % 4
					var random_rotation2 = randi() % 4
					
					if count == 1:
						map_node.add_tile("end", random_rotation, i, j)
						map_node.add_tile("end", random_rotation2, full_map_width - i - 1, j)
					elif count == 2 and north == south:
						map_node.add_tile("straight", random_rotation, i, j)
						map_node.add_tile("straight", random_rotation2, full_map_width - i - 1, j)
					elif count == 2 and north != south:
						map_node.add_tile("curve", random_rotation, i, j)
						map_node.add_tile("curve", random_rotation2, full_map_width - i - 1, j)
					elif count == 3:
						map_node.add_tile("tri", random_rotation, i, j)
						map_node.add_tile("tri", random_rotation2, full_map_width - i - 1, j)
					elif count == 4:
						map_node.add_tile("cross", random_rotation, i, j)
						map_node.add_tile("cross", random_rotation2, full_map_width - i - 1, j)
					else:
						print("Empty line generated")
						
				
		generated_lines += 1
