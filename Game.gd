extends Container

const Utils = preload("res://Utils.gd")
const MapGenerator_Preset = preload("res://map_generators/preset.gd")
const MapGenerator_Random = preload("res://map_generators/random.gd")
const MapGenerator_Pathfinder = preload("res://map_generators/pathfinder.gd")

# Contains the progress of each game
var game_progress = {}
# Contains the available games
var available_games = {}
# The current active game
var current_game_id = null

# Tracks the phases of the game
var game_is_generating = false
var game_is_initializing = true


func _ready():	
	get_node("Map").connect("map_solved", self, "game_level_solved")
	get_node("Map").connect("map_update_color_data", get_node("MapBackground"), "update_color_data")
	get_node("FinishedUI/CenterContainer/VBoxContainer/buttonNextLevel").connect("button_down", self, "game_start_level")
	
	# Load available games and the progress
	load_all_game_definitions()
	game_load_progress()
	game_is_initializing = false
	
	# Game options
	$GamePreferences.preferences_load()
	
	# Load default game if preferences did not load
	if current_game_id == null:
		game_switch_to(available_games.keys()[0])
		
	# Resolution dependent update
	get_viewport().connect("size_changed", self, "update_responsive_ui")
	
	# Load translations
	$FinishedUI/CenterContainer/VBoxContainer/buttonNextLevel.text = tr("NEXT_LEVEL")
	
	
func _process(delta):
	
	# Update the level counter
	get_node("Level").text = str(game_get_level() + 1)
	
	# Handle input actions
	if Input.is_action_just_released("ui_cancel"):
		preferences_show()
	

		
# Functions for responsive UI
func update_responsive_ui():
	pass
	

# Game control functions
func game_switch_to(game_id):
	
	$GamePreferences.preferences_hide()
	
	if current_game_id == game_id:
		return
	
	current_game_id = game_id	
	
	load_suitable_map()
	game_start_level()
	
	# Update the selectize if needed
	$GamePreferences.update_game_selection(game_id)
	

func game_start_level():	
	get_node("FinishedUI").visible = false
	load_suitable_map()
	$sfxLoad.play()
	
func game_level_solved():
	
	if(game_is_generating):
		return
		
	$GamePreferences.preferences_hide()
		
	$sfxSolved.play()
	
	game_set_level(game_get_level() + 1)
	game_save_progress()
	
	get_node("AnimationPlayer").play("ShowFinishedUI")
	
func game_reset():
	$GamePreferences.preferences_hide()
	game_set_level(0)
	game_save_progress()
	load_suitable_map()
	$sfxLoad.play()
	
func game_regenerate():
	$GamePreferences.preferences_hide()
	load_suitable_map()
	$sfxLoad.play()
	
func game_save_progress():
	var file = File.new()
	file.open("user://progress.dat", File.WRITE)
	file.store_line(to_json(game_progress))
	file.close()
	
func game_load_progress():
	var file = File.new()
	file.open("user://progress.dat", File.READ)
	
	if file.is_open():
		game_progress = parse_json(file.get_as_text())
		file.close()
	
func game_empty_progress():
	return { "level" : 0 }
	
func game_get_level():	
	if current_game_id == null:
		return -1
	if not current_game_id in game_progress.keys():
		game_progress[current_game_id] = game_empty_progress()
	return int(game_progress[current_game_id]["level"])
	
func game_set_level(level):
	if current_game_id == null:
		return
	if not current_game_id in game_progress.keys():
		game_progress[current_game_id] = game_empty_progress()
	game_progress[current_game_id]["level"] = level
	
	
# Loads all game definitions from games.json
func load_all_game_definitions():
	
	var file = File.new()
	file.open("res://games.json", File.READ)
	var data = parse_json(file.get_as_text())
	file.close()
	
	$GamePreferences.clear_game_selection()
	
	for item in data:
		load_game_definition(item)
		
	
# Loads a game definition from a file
func load_game_definition(filename):
	
	# Import the data
	var file = File.new()
	file.open(filename, File.READ)
	var data = parse_json(file.get_as_text())
	file.close()
	
	# Load the information
	var id = data["id"]
	data["ramp"].invert() # This is important!
	
	available_games[id] = data
	
	# Add to select
	$GamePreferences.add_game_selection_item(data)
	
	

# Loads the highest (by order within game definition) map that meets the requirements
func load_suitable_map():	
	for definition in available_games[current_game_id]["ramp"]:
		if game_get_level() >= definition["required-level"]:
			load_map_from_ramp(definition)			
			return

# Loads a map from ramp definition
func load_map_from_ramp(definition):
	game_is_generating = true
	print("Loading map from ramp definition ...")
	
	if(definition["generator"]["id"] == "random"):
		var width = int(definition["generator"]["width"])
		var height = int(definition["generator"]["height"])
		var min_generated_lines = int(definition["generator"]["min-generated-lines"])
		var min_line_length = int(definition["generator"]["min-line-length"])
		var max_bouncing = int(definition["generator"]["max-bouncing"])
		
		get_node("Map").initialize_map(width, height)
		MapGenerator_Random.map_generator(get_node("Map"), min_generated_lines, min_line_length, max_bouncing)
		
	elif(definition["generator"]["id"] == "pathfinder"):
		var width = int(definition["generator"]["width"])
		var height = int(definition["generator"]["height"])
		var min_line_length = int(definition["generator"]["min-line-length"])
		var min_coverage = int(definition["generator"]["min-coverage"])
		var min_paths = int(definition["generator"]["min-paths"])
		
		get_node("Map").initialize_map(width, height)
		MapGenerator_Pathfinder.map_generator(get_node("Map"), min_coverage, min_line_length, min_paths)
		
	elif(definition["generator"]["id"] == "preset"):
		var filename = definition["generator"]["file"]
		MapGenerator_Preset.map_generator(get_node("Map"), filename)
		
	else:
		print("Unknown generator " + str(definition["generator"]["id"]))
		
	# Flush!
	get_node("Map").flush_tiles()
	
	# Set color
	apply_map_color()
		
	game_is_generating = false
	
func apply_map_color():
	
	var game_color = Utils.hsv2rgb(randf(), 1, 1)	
	
	get_node("Map").map_color = game_color
	get_node("Map").update_map_colors()
	get_node("FinishedUI/Background").color = Color(game_color.r, game_color.g, game_color.b, 0.5).lightened(0.2)
	