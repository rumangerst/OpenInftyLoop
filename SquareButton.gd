extends TextureButton

const FONT_PT_PX_W = 100.0 / 50.0
const FONT_PT_PX_H = 100.0 / 44.0
const SIZE_FACTOR = 0.5


func _ready():
	
	# Create the font
	var font_data = DynamicFontData.new()
	font_data.font_path = "res://gfx/fonts/OxygenMono-Regular.ttf"
	var font = DynamicFont.new()
	font.font_data = font_data
	font.size = 20
	$Label.set("custom_fonts/font", font)
	
	# Resolution dependent update
	connect("resized", self, "update_responsive_ui")
	update_responsive_ui()

func update_responsive_ui():
	
	if !$Label.text.empty():
		var available_x = rect_size.x * SIZE_FACTOR / float(len($Label.text))
		var available_y = rect_size.y * SIZE_FACTOR
				
		$Label.get("custom_fonts/font").size = min(available_x * FONT_PT_PX_W, available_y * FONT_PT_PX_H)
		#$Label.get("custom_fonts/font").extra_spacing_bottom = -5