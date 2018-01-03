extends Container

const Utils = preload("res://Utils.gd")
const MapGenerator_Preset = preload("res://map_generators/preset.gd")
const MapGenerator_Random = preload("res://map_generators/random.gd")
const MapGenerator_Pathfinder = preload("res://map_generators/pathfinder.gd")

var game_ramp = []
var game_is_generating = false
var game_id = null

var game_progress = {}

func _ready():	
	get_node("Map").connect("map_solved", self, "game_level_solved")
	get_node("Map").connect("map_update_color_data", get_node("MapBackground"), "update_color_data")
	get_node("FinishedUI/VBoxContainer/buttonNextLevel").connect("button_down", self, "game_start_level")
	
	# Game options
	preferences_load()
	$GameUI/buttonGameOptions.connect("button_down", self, "preferences_show")
	$GameUI/gameOptionsPanel/buttonCloseGameOptions.connect("button_down", $GameUI/gameOptionsPanel, "hide")	
	$GameUI/gameOptionsPanel/VBoxContainer/buttonResetProgress.connect("button_down", self, "game_reset")
	$GameUI/gameOptionsPanel/VBoxContainer/buttonRestartMap.connect("button_down", self, "game_regenerate")
	$GameUI/gameOptionsPanel/VBoxContainer/sliderVolume.connect("value_changed", self, "preferences_volume_changed")
	$GameUI/gameOptionsPanel/VBoxContainer/sliderSFXVolume.connect("value_changed", self, "preferences_SFXVolume_changed")
	$GameUI/gameOptionsPanel/VBoxContainer/sliderMusicVolume.connect("value_changed", self, "preferences_MusicVolume_changed")
	
	# Initial start
	load_game("res://games/default.json")
	game_load_progress()	
	game_start_level()
	
func _process(delta):	
	get_node("Level").text = str(game_get_level() + 1)
	
# Handling preferences
func preferences_load():
	var file = File.new()
	file.open("user://preferences.json", File.READ)
	
	if file.is_open():
		var data = parse_json(file.get_as_text())
		file.close()
		
		# Load volume
		if "volume" in data.keys():
			var volume = clamp(data["volume"], -60, 0)
			AudioServer.set_bus_volume_db(0, volume)
			$GameUI/gameOptionsPanel/VBoxContainer/sliderVolume.value = volume
		if "sfx_volume" in data.keys():
			var volume = clamp(data["sfx_volume"], -60, 0)
			AudioServer.set_bus_volume_db(2, volume)
			$GameUI/gameOptionsPanel/VBoxContainer/sliderSFXVolume.value = volume
		if "music_volume" in data.keys():
			var volume = clamp(data["music_volume"], -60, 0)
			AudioServer.set_bus_volume_db(1, volume)
			$GameUI/gameOptionsPanel/VBoxContainer/sliderMusicVolume.value = volume
	
func preferences_save():
	
	var data = {
		volume = AudioServer.get_bus_volume_db(0),
		sfx_volume = AudioServer.get_bus_volume_db(2),
		music_volume = AudioServer.get_bus_volume_db(1)
		}
	
	var file = File.new()
	file.open("user://preferences.json", File.WRITE)
	file.store_line(to_json(data))
	file.close()
	
func preferences_volume_changed(volume):
	volume = clamp(volume, -60, 0)
	AudioServer.set_bus_volume_db(0, volume)
	preferences_save()
	
func preferences_SFXVolume_changed(volume):
	volume = clamp(volume, -60, 0)
	AudioServer.set_bus_volume_db(2, volume)
	preferences_save()

func preferences_MusicVolume_changed(volume):
	volume = clamp(volume, -60, 0)
	AudioServer.set_bus_volume_db(1, volume)
	preferences_save()
	
func preferences_show():
	if(not $GameUI/gameOptionsPanel.visible):
		$AnimationPlayer.play("ShowOptionsPanelUI")
	else:
		$GameUI/gameOptionsPanel.visible = false

# Game control functions
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
	
	game_progress["current-game-id"] = game_id
	
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
	if game_id == null:
		return -1
	if not game_id in game_progress.keys():
		game_progress[game_id] = game_empty_progress()
	return int(game_progress[game_id]["level"])
	
func game_set_level(level):
	if game_id == null:
		return
	if not game_id in game_progress.keys():
		game_progress[game_id] = game_empty_progress()
	game_progress[game_id]["level"] = level
	
	
# Loads a game definition from a file
func load_game(filename):
	get_node("Map").clear_map()
	
	# Import the data
	var file = File.new()
	file.open(filename, File.READ)
	var data = parse_json(file.get_as_text())
	file.close()
	
	# Load the information
	self.game_ramp = data["ramp"]
	self.game_id = data["id"]
	self.game_ramp.invert() #!Important!
	
	load_suitable_map()

# Loads the highest (by order within game definition) map that meets the requirements
func load_suitable_map():	
	for definition in game_ramp:
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
	