extends Control

const Utils = preload("res://Utils.gd")

func _ready():
	
	$buttonGameOptions.connect("button_down", self, "preferences_show_hide")
	$gameOptionsPanel/ScrollContainer/VBoxContainer/buttonResetProgress.connect("button_down", get_parent(), "game_reset")
	$gameOptionsPanel/ScrollContainer/VBoxContainer/buttonRestartMap.connect("button_down", get_parent(), "game_regenerate")
	$gameOptionsPanel/ScrollContainer/VBoxContainer/sliderVolume.connect("value_changed", self, "preferences_volume_changed")
	$gameOptionsPanel/ScrollContainer/VBoxContainer/sliderSFXVolume.connect("value_changed", self, "preferences_SFXVolume_changed")
	$gameOptionsPanel/ScrollContainer/VBoxContainer/sliderMusicVolume.connect("value_changed", self, "preferences_MusicVolume_changed")
	$gameOptionsPanel/ScrollContainer/VBoxContainer/selectGame.connect("item_selected", self, "preferences_Game_changed")
	$gameOptionsPanel/buttonExit.connect("button_down", get_tree(), "quit")

	# Resolution dependent update
	get_viewport().connect("size_changed", self, "update_responsive_ui")
	
	# Translations
	$gameOptionsPanel/ScrollContainer/VBoxContainer/buttonResetProgress.text = tr("RESET_PROGRESS")
	$gameOptionsPanel/ScrollContainer/VBoxContainer/buttonRestartMap.text = tr("RELOAD_MAP")
	$gameOptionsPanel/ScrollContainer/VBoxContainer/labelSliderVolume.text = tr("VOLUME_GENERAL")
	$gameOptionsPanel/ScrollContainer/VBoxContainer/labelSliderSFXVolume.text = tr("VOLUME_SFX")
	$gameOptionsPanel/ScrollContainer/VBoxContainer/labelSliderMusicVolume.text = tr("VOLUME_MUSIC")
	$gameOptionsPanel/buttonExit.text = tr("EXIT")

func update_responsive_ui():
	
	var available = rect_size
	
	# The option panel should be responsive
	if available.x < available.y:
		$gameOptionsPanel.margin_right = available.x
	else:
		$gameOptionsPanel.margin_right = min(400, available.x)
		

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
			$gameOptionsPanel/ScrollContainer/VBoxContainer/sliderVolume.value = volume
		if "sfx_volume" in data.keys():
			var volume = (data["sfx_volume"])
			AudioServer.set_bus_volume_db(2, Utils.percent2volume(volume))
			$gameOptionsPanel/ScrollContainer/VBoxContainer/sliderSFXVolume.value = volume
		if "music_volume" in data.keys():
			var volume = (data["music_volume"])
			AudioServer.set_bus_volume_db(1, Utils.percent2volume(volume))
			$gameOptionsPanel/ScrollContainer/VBoxContainer/sliderMusicVolume.value = volume
			
		# Load current game
		var parent = get_parent()
		
		if "game" in data.keys():
			var game = data["game"]
			
			if game in parent.available_games.keys():
				parent.game_switch_to(game)
	
func preferences_save():
	
	var data = {
		volume = Utils.volume2percent(AudioServer.get_bus_volume_db(0)),
		sfx_volume = Utils.volume2percent(AudioServer.get_bus_volume_db(2)),
		music_volume = Utils.volume2percent(AudioServer.get_bus_volume_db(1)),
		game = get_parent().current_game_id
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
	if not get_parent().game_is_initializing and index >= 0:
		var id = $gameOptionsPanel/ScrollContainer/VBoxContainer/selectGame.get_item_metadata(index)
		get_parent().game_switch_to(id)
	
func preferences_show_hide():
	if(not $gameOptionsPanel.visible):
		$AnimationPlayer.play("show_panel")
	else:
		$gameOptionsPanel.visible = false
		
func preferences_hide():
	$gameOptionsPanel.visible = false
		
func clear_game_selection():
	$gameOptionsPanel/ScrollContainer/VBoxContainer/selectGame.clear()
	
func add_game_selection_item(data):
	
	var id = data["id"]
	
	var select = $gameOptionsPanel/ScrollContainer/VBoxContainer/selectGame
	select.add_item(data["name"].to_lower())
	select.set_item_metadata(select.get_item_count() - 1, id)
	
func update_game_selection(game_id):
	var select = $gameOptionsPanel/ScrollContainer/VBoxContainer/selectGame
	if select.get_selected_metadata() != game_id:
		for i in range(select.get_item_count()):
			if select.get_item_metadata(i) == game_id:
				select.select(i)
				break
	
	preferences_save()