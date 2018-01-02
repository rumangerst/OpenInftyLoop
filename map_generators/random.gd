#
# Random map generator
#

const MapUtils = preload("res://map_generators/map_utils.gd")

static func map_generator(map_node, min_generated_lines, min_line_length, max_bouncing):
	
	var map_width = map_node.map_width
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
			
		# Generate the line
		MapUtils.generate_map_from_generator_pre(map_node, generator_pre)
				
		generated_lines += 1
		
	MapUtils.make_non_solution(map_node)
