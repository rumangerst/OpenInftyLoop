extends Control

const Utils = preload("res://Utils.gd")

const TEXTURE_BUTTON_PREFERENCES_INGAME_NORMAL = preload("res://gfx/ui/menu.svg")
const TEXTURE_BUTTON_PREFERENCES_INGAME_HOVER = preload("res://gfx/ui/menu_hover.svg")
const TEXTURE_BUTTON_PREFERENCES_PREFERENCES_NORMAL = preload("res://gfx/ui/play.svg")
const TEXTURE_BUTTON_PREFERENCES_PREFERENCES_HOVER = preload("res://gfx/ui/play_hover.svg") 

var available_game_buttons = {}

func _ready():
	
	$buttonGameOptions.connect("toggled", self, "open_preferences_toggled")
	get_preferences_element("buttonResetProgress", "Game").connect("button_down", get_parent(), "game_reset")
	get_preferences_element("buttonRestartMap", "Game").connect("button_down", get_parent(), "game_regenerate")
	get_preferences_element("sliderVolume", "Volume").connect("value_changed", self, "preferences_volume_changed")
	get_preferences_element("sliderSFXVolume", "Volume").connect("value_changed", self, "preferences_SFXVolume_changed")
	get_preferences_element("sliderMusicVolume", "Volume").connect("value_changed", self, "preferences_MusicVolume_changed")
	get_preferences_element("toggleFullscreen", "System").connect("toggled", self, "preferences_Fullscreen_changed")
	get_preferences_element("buttonExit", "System").connect("button_down", get_tree(), "quit")
	
	# Textures
	get_preferences_element("sliderVolume", "Volume").set_icon(load("res://gfx/ui/volume_iconvolume.svg"))
	get_preferences_element("sliderSFXVolume", "Volume").set_icon(load("res://gfx/ui/volume_iconsfx.svg"))
	get_preferences_element("sliderMusicVolume", "Volume").set_icon(load("res://gfx/ui/volume_iconmusic.svg"))

	# Resolution dependent update
	get_viewport().connect("size_changed", self, "update_responsive_ui")
	update_responsive_ui()
	
	# Translations
	get_preferences_element("buttonResetProgress", "Game").hint_tooltip = tr("RESET_PROGRESS")
	get_preferences_element("buttonRestartMap", "Game").hint_tooltip = tr("RELOAD_MAP")
	get_preferences_element("toggleFullscreen", "System").hint_tooltip = tr("FULLSCREEN")
	get_preferences_element("buttonExit", "System").hint_tooltip = tr("EXIT")
	get_preferences_element("sliderVolume", "Volume").hint_tooltip = tr("VOLUME_GENERAL")
	get_preferences_element("sliderSFXVolume", "Volume").hint_tooltip = tr("VOLUME_SFX")
	get_preferences_element("sliderMusicVolume", "Volume").hint_tooltip = tr("VOLUME_MUSIC")
	
	open_preferences_toggled(false)
	$gameOptionsPanel.visible = false
	
func open_preferences_toggled(toggle):
	
	#$gameOptionsPanel.visible = toggle
	
	if toggle:
		$gameOptionsPanel.visible = true
		update_responsive_ui()
		$AnimationPlayer.play("show_panel")
	else:
		$AnimationPlayer.play("hide_panel")
	
	
	
	if toggle:
		$buttonGameOptions.texture_normal = TEXTURE_BUTTON_PREFERENCES_PREFERENCES_NORMAL
		$buttonGameOptions.texture_focused = TEXTURE_BUTTON_PREFERENCES_PREFERENCES_NORMAL
		$buttonGameOptions.texture_disabled = TEXTURE_BUTTON_PREFERENCES_PREFERENCES_NORMAL
		$buttonGameOptions.texture_hover = TEXTURE_BUTTON_PREFERENCES_PREFERENCES_HOVER
		$buttonGameOptions.texture_pressed = TEXTURE_BUTTON_PREFERENCES_PREFERENCES_HOVER
	else:
		$buttonGameOptions.texture_normal = TEXTURE_BUTTON_PREFERENCES_INGAME_NORMAL
		$buttonGameOptions.texture_focused = TEXTURE_BUTTON_PREFERENCES_INGAME_NORMAL
		$buttonGameOptions.texture_disabled = TEXTURE_BUTTON_PREFERENCES_INGAME_NORMAL
		$buttonGameOptions.texture_hover = TEXTURE_BUTTON_PREFERENCES_INGAME_HOVER
		$buttonGameOptions.texture_pressed = TEXTURE_BUTTON_PREFERENCES_INGAME_HOVER
	
func get_preferences_element(id, group = null):	
	return get_node("gameOptionsPanel/centerMenu/boxMenu/gridControls/" + id)

func update_responsive_ui():
	
	var available = rect_size
	
	# The option panel should be responsive
	#$gameOptionsPanel.margin_right = available.x
		
	# Responsive fonts
	$gameOptionsPanel.theme.default_font.size = Utils.cm2px(0.5)
	
	# Responsive size of preferences button
	$buttonGameOptions.margin_top = $buttonGameOptions.margin_bottom - Utils.cm2px(1)
	$buttonGameOptions.margin_right = $buttonGameOptions.margin_left + Utils.cm2px(1)
	
	# Responsive tile size 
	var columns = 3
	var rows = ceil(float($gameOptionsPanel/centerMenu/boxMenu/gridControls.get_child_count()) / columns) + ceil(float($gameOptionsPanel/centerMenu/boxMenu/gridAvailableGames.get_child_count()) / columns)
	
	var tile_size = min(Utils.cm2px(3), min(available.x / columns, (available.y + 2 * $buttonGameOptions.margin_top) / rows)) * 0.9
	get_preferences_element("sliderVolume", "Volume").rect_min_size = Vector2(tile_size, tile_size)
	get_preferences_element("sliderSFXVolume", "Volume").rect_min_size = Vector2(tile_size, tile_size)
	get_preferences_element("sliderMusicVolume", "Volume").rect_min_size = Vector2(tile_size, tile_size)
	get_preferences_element("buttonResetProgress", "Game").rect_min_size = Vector2(tile_size, tile_size)
	get_preferences_element("buttonRestartMap", "Game").rect_min_size = Vector2(tile_size, tile_size)
	get_preferences_element("buttonExit", "System").rect_min_size = Vector2(tile_size, tile_size)
	get_preferences_element("toggleFullscreen", "System").rect_min_size = Vector2(tile_size, tile_size)
	
	for button in $gameOptionsPanel/centerMenu/boxMenu/gridAvailableGames.get_children():
		button.rect_min_size = Vector2(tile_size, tile_size)

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
			get_preferences_element("sliderVolume", "Volume").set_value(volume)
		if "sfx_volume" in data.keys():
			var volume = (data["sfx_volume"])
			AudioServer.set_bus_volume_db(2, Utils.percent2volume(volume))
			get_preferences_element("sliderSFXVolume", "Volume").set_value(volume)
		if "music_volume" in data.keys():
			var volume = (data["music_volume"])
			AudioServer.set_bus_volume_db(1, Utils.percent2volume(volume))
			get_preferences_element("sliderMusicVolume", "Volume").set_value(volume)
			
		# Load GFX parameters
		if "fullscreen" in data.keys():
			OS.set_window_fullscreen(data["fullscreen"])
			get_preferences_element("toggleFullscreen", "System").pressed = OS.is_window_fullscreen()
			
		# Load current game
		var parent = get_parent()
		
		if "game" in data.keys():
			var game = data["game"]
			
			if game in parent.available_games.keys():
				parent.game_switch_to(game)
	else:
		get_preferences_element("sliderVolume", "Volume").set_value(1.0)
		get_preferences_element("sliderSFXVolume", "Volume").set_value(1.0)
		get_preferences_element("sliderMusicVolume", "Volume").set_value(0.8)
	
func preferences_save():
	
	var data = {
		volume = Utils.volume2percent(AudioServer.get_bus_volume_db(0)),
		sfx_volume = Utils.volume2percent(AudioServer.get_bus_volume_db(2)),
		music_volume = Utils.volume2percent(AudioServer.get_bus_volume_db(1)),
		game = get_parent().current_game_id,
		fullscreen = OS.is_window_fullscreen()
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
	
func preferences_Fullscreen_changed(fullscreen):
	
	OS.set_window_fullscreen(fullscreen)
	preferences_save()
	
func preferences_Game_changed(toggle, game_id):
	if toggle and not get_parent().game_is_initializing:
		get_parent().game_switch_to(game_id)	
		
func preferences_hide():
	$buttonGameOptions.pressed = false
	open_preferences_toggled(false)
		
func clear_game_selection():
	for button in $gameOptionsPanel/centerMenu/boxMenu/gridAvailableGames.get_children():
		button.queue_free()
	
func add_game_selection_item(data):
	
	var id = data["id"]
	
	var button = TextureButton.new()
	button.rect_min_size = Vector2(50, 50)
	button.texture_normal = load(data["icon"])
	button.texture_hover = load(data["icon-hover"])
	button.texture_pressed = load(data["icon-hover"])
	button.expand = true
	button.toggle_mode = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.hint_tooltip = tr("GAME_MODE") + ": " + data["name"].to_lower()
	button.connect("toggled", self, "preferences_Game_changed", [id])
	button.set_script(load("res://GenericButton.gd"))
	
	$gameOptionsPanel/centerMenu/boxMenu/gridAvailableGames.add_child(button)
	available_game_buttons[id] = button
	update_responsive_ui()
	
func update_game_selection(game_id):
	
	for key in available_game_buttons.keys():
		if key == game_id:
			available_game_buttons[key].pressed = true
			available_game_buttons[key].mouse_filter = MOUSE_FILTER_IGNORE
		else:
			available_game_buttons[key].pressed = false
			available_game_buttons[key].mouse_filter = MOUSE_FILTER_STOP
	
	preferences_save()