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
	get_node("FinishedUI/VBoxContainer/buttonNextLevel").connect("button_down", self, "game_start_level")
	
	# Load available games and the progress
	load_all_game_definitions()
	game_load_progress()
	game_is_initializing = false
	
	# Game options
	preferences_load()
	$GameUI/buttonGameOptions.connect("button_down", self, "preferences_show")
	$GameUI/gameOptionsPanel/VBoxContainer/buttonResetProgress.connect("button_down", self, "game_reset")
	$GameUI/gameOptionsPanel/VBoxContainer/buttonRestartMap.connect("button_down", self, "game_regenerate")
	$GameUI/gameOptionsPanel/VBoxContainer/sliderVolume.connect("value_changed", self, "preferences_volume_changed")
	$GameUI/gameOptionsPanel/VBoxContainer/sliderSFXVolume.connect("value_changed", self, "preferences_SFXVolume_changed")
	$GameUI/gameOptionsPanel/VBoxContainer/sliderMusicVolume.connect("value_changed", self, "preferences_MusicVolume_changed")
	$GameUI/gameOptionsPanel/VBoxContainer/selectGame.connect("item_selected", self, "preferences_Game_changed")
	$GameUI/gameOptionsPanel/buttonExit.connect("button_down", get_tree(), "quit")
	
	# Load default game if preferences did not load
	if current_game_id == null:
		game_switch_to(available_games.keys()[0])
		
	# Resolution dependent update
	get_viewport().connect("size_changed", self, "update_responsive_ui")
	
	
func _process(delta):
	
	# Update the level counter
	get_node("Level").text = str(game_get_level() + 1)
	
	# Handle input actions
	if Input.is_action_just_released("ui_cancel"):
		preferences_show()
	
# Handling preferences
func preferences_load():
	var file = File.new()
	file.open("user://preferences.json", File.READ)
	
	if file.is_open():
		var data = parse_json(file.get_as_text())
		file.close()
		
		# Load volume
		if "volume" in data.keys():
			var volume = (data["volume"])
			AudioServer.set_bus_volume_db(0, Utils.percent2volume(volume))
			$GameUI/gameOptionsPanel/VBoxContainer/sliderVolume.value = volume
		if "sfx_volume" in data.keys():
			var volume = (data["sfx_volume"])
			AudioServer.set_bus_volume_db(2, Utils.percent2volume(volume))
			$GameUI/gameOptionsPanel/VBoxContainer/sliderSFXVolume.value = volume
		if "music_volume" in data.keys():
			var volume = (data["music_volume"])
			AudioServer.set_bus_volume_db(1, Utils.percent2volume(volume))
			$GameUI/gameOptionsPanel/VBoxContainer/sliderMusicVolume.value = volume
			
		# Load current game
		if "game" in data.keys():
			var game = data["game"]
			
			if game in available_games.keys():
				game_switch_to(game)
	
func preferences_save():
	
	var data = {
		volume = Utils.volume2percent(AudioServer.get_bus_volume_db(0)),
		sfx_volume = Utils.volume2percent(AudioServer.get_bus_volume_db(2)),
		music_volume = Utils.volume2percent(AudioServer.get_bus_volume_db(1)),
		game = current_game_id
		}
	
	var file = File.new()
	file.open("user://preferences.json", File.WRITE)
	file.store_line(to_json(data))
	file.close()
	
func preferences_volume_changed(volume):
	volume = Utils.percent2volume(volume)
	
	AudioServer.set_bus_volume_db(0, volume)
	preferences_save()
	
func preferences_SFXVolume_changed(volume):
	volume = Utils.percent2volume(volume)
	
	AudioServer.set_bus_volume_db(2, volume)
	preferences_save()

func preferences_MusicVolume_changed(volume):
	volume = Utils.percent2volume(volume)
	
	AudioServer.set_bus_volume_db(1, volume)
	preferences_save()
	
func preferences_Game_changed(index):
	if not game_is_initializing and index >= 0:
		var id = $GameUI/gameOptionsPanel/VBoxContainer/selectGame.get_item_metadata(index)
		game_switch_to(id)
	
func preferences_show():
	if(not $GameUI/gameOptionsPanel.visible):
		$AnimationPlayer.play("ShowOptionsPanelUI")
	else:
		$GameUI/gameOptionsPanel.visible = false
		
# Functions for responsive UI

func update_responsive_ui():
	var available = $GameUI.rect_size
	
	# The option panel should be responsive
	if available.x < available.y:
		$GameUI/gameOptionsPanel.margin_right = available.x
	else:
		$GameUI/gameOptionsPanel.margin_right = min(400, available.x)
	

# Game control functions
func game_switch_to(game_id):
	
	$GameUI/gameOptionsPanel.visible = false
	
	if current_game_id == game_id:
		return
	
	current_game_id = game_id	
	
	load_suitable_map()
	game_start_level()
	
	# Update the selectize if needed
	var select = $GameUI/gameOptionsPanel/VBoxContainer/selectGame
	if select.get_selected_metadata() != game_id:
		for i in range(select.get_item_count()):
			if select.get_item_metadata(i) == game_id:
				select.select(i)
				break
	
	preferences_save()
	

func game_start_level():	
	get_node("FinishedUI").visible = false
	load_suitable_map()
	$sfxLoad.play()
	
func game_level_solved():
	
	if(game_is_generating):
		return
		
	$GameUI/gameOptionsPanel.hide()
		
	$sfxSolved.play()
	
	game_set_level(game_get_level() + 1)
	game_save_progress()
	
	get_node("AnimationPlayer").play("ShowFinishedUI")
	
func game_reset():
	$GameUI/gameOptionsPanel.hide()
	game_set_level(0)
	game_save_progress()
	load_suitable_map()
	$sfxLoad.play()
	
func game_regenerate():
	$GameUI/gameOptionsPanel.hide()
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
	
	$GameUI/gameOptionsPanel/VBoxContainer/selectGame.clear()
	
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
	var select = $GameUI/gameOptionsPanel/VBoxContainer/selectGame
	select.add_item(data["name"].to_lower())
	select.set_item_metadata(select.get_item_count() - 1, id)
	

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
	