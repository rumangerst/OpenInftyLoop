#
# More intelligent random generator
#

const MapUtils = preload("res://map_generators/map_utils.gd")
const PATHFINDER_WEIGHT_OPEN = 4
const PATHFINDER_WEIGHT_OPEN_TAINTED = 2
const PATHFINDER_WEIGHT_BACKTRACKING = 1
const MAX_ADDITIONAL_TRIES = 100
const MAX_ADDITIONAL_PATHING_TRIES = 100

static func map_generator(map_node, min_coverage, min_linelength, min_paths):
	
	min_coverage = max(min_coverage, min_linelength)
	
	var map_width = map_node.map_width
	var map_height = map_node.map_height
	
	var coverage = 0
	var paths = 0
	var first = true
	var tries = 0
	
	while coverage < min_coverage or paths < min_paths:
		
		print("Pathfinder: Attempting to start new path")
		
		if tries > MAX_ADDITIONAL_TRIES and paths >= 1:
			break
			
		tries += 1
		
		var x = randi() % map_width
		var y = randi() % map_height
		
		if(map_node.get_tile(x,y) != null):
			continue
		
		var generator_pre = []
		var generator_tainted = []
		for i in range(map_width * map_height):
			generator_pre.append(0)
			generator_tainted.append(0)
			
		# Initial start of the path
		generator_pre[x + y * map_width] = 1
				
		# Count how long the generated line will be
		var line_length = 1
		
		# For each step we determine all possible paths and go a random one
		var possible_paths = []
		var pathing_tries = 0
		
		while (first and line_length < min_linelength) or (randf() > (float(line_length) / min_coverage)):
			possible_paths.clear()
			
			if paths >= 1 and pathing_tries >= MAX_ADDITIONAL_PATHING_TRIES:
				break
				
			pathing_tries += 1
			
			# Test all directions
			if y - 1 >= 0 and map_node.get_tile(x, y - 1) == null:
				var w = (PATHFINDER_WEIGHT_OPEN if generator_tainted[x + (y - 1) * map_width] == 0 else PATHFINDER_WEIGHT_OPEN_TAINTED) if generator_pre[x + (y - 1) * map_width] == 0 else PATHFINDER_WEIGHT_BACKTRACKING
				for i in range(w):
					possible_paths.append(0)
			if y + 1 < map_height and map_node.get_tile(x, y + 1) == null:
				var w = (PATHFINDER_WEIGHT_OPEN if generator_tainted[x + (y + 1) * map_width] == 0 else PATHFINDER_WEIGHT_OPEN_TAINTED) if generator_pre[x + (y + 1) * map_width] == 0 else PATHFINDER_WEIGHT_BACKTRACKING
				for i in range(w):
					possible_paths.append(2)
			if x - 1 >= 0 and map_node.get_tile(x - 1, y) == null:
				var w = (PATHFINDER_WEIGHT_OPEN if generator_tainted[(x - 1) + y * map_width] == 0 else PATHFINDER_WEIGHT_OPEN_TAINTED) if generator_pre[(x - 1) + y * map_width] == 0 else PATHFINDER_WEIGHT_BACKTRACKING
				for i in range(w):
					possible_paths.append(3)
			if x + 1 < map_width and map_node.get_tile(x + 1, y) == null:
				var w = (PATHFINDER_WEIGHT_OPEN if generator_tainted[(x + 1) + y * map_width] == 0 else PATHFINDER_WEIGHT_OPEN_TAINTED) if generator_pre[(x + 1) + y * map_width] == 0 else PATHFINDER_WEIGHT_BACKTRACKING
				for i in range(w):
					possible_paths.append(1)
					
			if len(possible_paths) == 0:
				break
			
			var taken = possible_paths[randi() % len(possible_paths)]
			
			# Taint the surrounding tiles to prevent clumps
			# !This must be done before updating the position!
			if y - 1 >= 0:
				generator_tainted[(x) + (y-1) * map_width] = 1
			if y + 1 < map_height:
				generator_tainted[(x) + (y+1) * map_width] = 1
			if x - 1 >= 0:
				generator_tainted[(x-1) + (y) * map_width] = 1
			if x + 1 < map_width:
				generator_tainted[(x+1) + (y) * map_width] = 1
					
			# Update the position			
			if taken == 0:
				y -= 1
			elif taken == 1:
				x += 1
			elif taken == 2:
				y += 1
			elif taken == 3:
				x -= 1
				
			if(generator_pre[x + y * map_width] != 1):
				generator_pre[x + y * map_width] = 1
				line_length += 1
				
				
			
			
		if line_length >= 2:
			MapUtils.generate_map_from_generator_pre(map_node, generator_pre)
			coverage += line_length
			paths += 1
			tries = 0
			
	print("Generated map with coverage " + str(coverage))	
	
	MapUtils.make_non_solution(map_node)
