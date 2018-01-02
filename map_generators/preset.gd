#
# Loads a map from preset
#

const MapUtils = preload("res://map_generators/map_utils.gd")

static func map_generator(map_node, filename):
	var file = File.new()
	file.open(filename, File.READ)
	
	var map_width = 0
	var map_initialized = false
	var generator_pre = []
	
	while !file.eof_reached():
		var line = file.get_line()
		
		if(line.begins_with("#")):
			continue
		elif line.strip_edges().empty():
			if(len(generator_pre) > 0):				
				if(!map_initialized):
					var map_height = len(generator_pre) / map_width
					map_node.initialize_map(map_width, map_height)
					map_initialized = true
				
				MapUtils.generate_map_from_generator_pre(map_node, generator_pre)
				generator_pre.clear()
		else:
			map_width = len(line)
			for i in range(len(line)):
				generator_pre.append(int(line[i]))
	
	file.close()
	
	MapUtils.make_non_solution(map_node)