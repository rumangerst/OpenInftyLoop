extends Container

const Utils = preload("res://Utils.gd")
const MapGenerator_Preset = preload("res://map_generators/preset.gd")
const MapGenerator_Random = preload("res://map_generators/random.gd")
const MapGenerator_Pathfinder = preload("res://map_generators/pathfinder.gd")

const FONT_PT_PX_W = 50.0 / 50.0
const FONT_PT_PX_H = 50.0 / 44.0

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
	get_node("FinishedUI/buttonNextLevel2").connect("button_down", self, "game_start_level")
	get_node("FinishedUI/CenterContainer/VBoxContainer/starContainer/AnimationPlayer").connect("animation_started", self, "star_animation_playsound")
	
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
	update_responsive_ui()
	
	# Load translations
	#$FinishedUI/CenterContainer/VBoxContainer/buttonNextLevel.text = tr("NEXT_LEVEL")
	
	
func _process(delta):
	
	# Update the level counter
	get_node("Level").text = str(game_get_level() + 1)
	
	# Handle input actions
	if Input.is_action_just_released("ui_cancel"):
		preferences_show()
	
	
func _notification(what):
	
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		if current_game_id != null:
			current_level_store()
	elif what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		if current_game_id != null:
			current_level_store()

		
# Functions for responsive UI
func update_responsive_ui():
	
	# Responsive font for level number
	var level_width = min(Utils.cm2px(5.0), rect_size.x / 3)
	$Level.get("custom_fonts/font").size = level_width * FONT_PT_PX_W
	$Level.get("custom_fonts/font").extra_spacing_bottom = -level_width / 3.5
	
	# Responsive hints
	$LevelHint.get("custom_fonts/font").size = Utils.cm2px(1)
	
	# Responsive next level button
	var available = rect_size
	
	var button_size = min(min(rect_size.x, rect_size.y) / 4.0, Utils.cm2px(4))
	$FinishedUI/CenterContainer/VBoxContainer/buttonNextLevel.rect_min_size = Vector2(button_size, button_size)

	# Responsive level rating stars
	var star_size = min(Utils.cm2px(0.75), rect_size.x / 5.0)
	for i in range(5):
		get_finished_ui_star(i).rect_min_size = Vector2(star_size, star_size)
		
	# Responsive star counter
	var star_counter_star_size = Utils.cm2px(1.5)
	var star_counter_font_size = Utils.cm2px(1.5)
	$FinishedUI/CenterContainer/VBoxContainer/starCounterContainer/star.rect_min_size = Vector2(star_counter_star_size, star_counter_star_size)
	$FinishedUI/CenterContainer/VBoxContainer/starCounterContainer/Label.get("custom_fonts/font").size = star_counter_font_size
	
func get_finished_ui_star(index):
	return get_node("FinishedUI/CenterContainer/VBoxContainer/starContainer/star" + str(index))

# Game control functions
func game_switch_to(game_id):
	
	$GamePreferences.preferences_hide()
	
	if current_game_id == game_id:
		return
	if current_game_id != null:
		current_level_store()
	
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
	
	# Efficiency stars
	$FinishedUI/CenterContainer/VBoxContainer/starCounterContainer/Label.text = str(game_get_stars())
	
	var efficiency = $Map.get_user_efficiency()
	print(efficiency)
	var stars = int(round(efficiency * 5.0))
	
	$FinishedUI/CenterContainer/VBoxContainer/starContainer/AnimationPlayer.queue("wait")
	
	for i in range(5):
		if i <= stars:
			get_node("FinishedUI/CenterContainer/VBoxContainer/starContainer/star" + str(i)).visible = true
			get_node("FinishedUI/CenterContainer/VBoxContainer/starContainer/star" + str(i)).modulate = Color(1,1,1,0)
			if i == 0:
				$FinishedUI/CenterContainer/VBoxContainer/starContainer/AnimationPlayer.queue("show_star" + str(i))
			else:
				$FinishedUI/CenterContainer/VBoxContainer/starContainer/AnimationPlayer.queue("show_star" + str(i))
		else:
			get_node("FinishedUI/CenterContainer/VBoxContainer/starContainer/star" + str(i)).visible = false
	
	
	current_level_clear()
	game_set_level(game_get_level() + 1)
	game_set_stars(game_get_stars() + stars)
	game_save_progress()
	
	get_node("AnimationPlayer").play("ShowFinishedUI")
	
func game_reset():
	$GamePreferences.preferences_hide()
	game_set_level(0)
	game_set_stars(0)
	game_save_progress()
	current_level_clear()
	load_suitable_map()
	$sfxLoad.play()
	
func game_regenerate():
	$GamePreferences.preferences_hide()
	current_level_clear()
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
	return { "level" : 0, "stars" : 0 }
	
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
	
func game_get_stars():	
	if current_game_id == null:
		return -1
	if not current_game_id in game_progress.keys():
		game_progress[current_game_id] = game_empty_progress()
	return int(game_progress[current_game_id]["stars"]) if "stars" in game_progress[current_game_id] else 0
	
func game_set_stars(level):
	if current_game_id == null:
		return
	if not current_game_id in game_progress.keys():
		game_progress[current_game_id] = game_empty_progress()
	game_progress[current_game_id]["stars"] = level
	
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
# Also attempts to restore if available
func load_suitable_map():
	
	var matching_definition = null
	
	for definition in available_games[current_game_id]["ramp"]:
		
		var level_restriction = definition["required-level"] if "required-level" in definition.keys() else 0
		var star_restriction = definition["required-stars"] if "required-stars" in definition.keys() else 0
		
		if game_get_level() >= level_restriction and game_get_stars() >= star_restriction:
			matching_definition = definition 
			break
			
	# Update hint
	if "hint" in matching_definition.keys():
		var hint = matching_definition["hint"]
		
		if not hint.empty() and hint.begins_with("_"):
			$LevelHint.text = tr(hint.right(1)).to_lower()
		else:
			$LevelHint.text = hint.to_lower()
	else:
		$LevelHint.text = ""
	
	if current_level_restore():
		return
	else:
		load_map_from_ramp(matching_definition)
	

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
		
		# For phones: invert width and height
		if (width > height and not rect_size.x > rect_size.y) or (width < height and not rect_size.x < rect_size.y):
			var x = width
			width = height
			height = x
			
			print("Switching width & height for phones")
		
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
	
# Functions for continuing levels
func current_level_store():
	
	if $Map.is_solved():
		return
	
	$Map.serialize("user://current_" + current_game_id + ".dat")
	
func current_level_restore():
	game_is_generating = true
	var savegame = "user://current_" + current_game_id + ".dat"
	var dir = Directory.new()
	
	if dir.file_exists(savegame):
		$Map.deserialize(savegame)
		
		# Flush!
		get_node("Map").flush_tiles()
		
		# Set color
		apply_map_color()
		
		game_is_generating = false
		return true
	else:
		game_is_generating = false
		return false
	
func current_level_clear():
	var savegame = "user://current_" + current_game_id + ".dat"
	var dir = Directory.new()
	
	if dir.file_exists(savegame):
		dir.remove(savegame)
		
# Animation stuff
func star_animation_playsound(animation):
	if animation.begins_with("show_star") and $FinishedUI.visible:
		var label = $FinishedUI/CenterContainer/VBoxContainer/starCounterContainer/Label
		label.text = str(int(label.text) + 1)
		var star = int(animation[-1])		
		get_node("FinishedUI/CenterContainer/VBoxContainer/starContainer/sfxStar" + str(star)).play()
	