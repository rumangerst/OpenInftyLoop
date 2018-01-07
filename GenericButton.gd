extends BaseButton

const SFX_CLICK = preload("res://sfx/click.wav")
const SFX_HOVER = preload("res://sfx/hover2.wav")
var sfx_player_click = AudioStreamPlayer.new()
var sfx_player_hover = AudioStreamPlayer.new()

func _ready():	
	sfx_player_click.bus = "SFX"
	sfx_player_click.stream = SFX_CLICK
	sfx_player_click.volume_db = -10
	add_child(sfx_player_click)	
	
	sfx_player_hover.bus = "SFX"
	sfx_player_hover.stream = SFX_HOVER
	sfx_player_hover.volume_db = -25
	add_child(sfx_player_hover)	
	
	connect("mouse_entered", self, "on_hover")	

func _pressed():
	sfx_player_click.play()
	
func _toggled(toggle):
	sfx_player_click.play()
	
func on_hover():
	sfx_player_hover.play()