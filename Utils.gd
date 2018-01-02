#
# Some utilities
#

# HSV within 0 ... 1
static func hsv2rgb(h, s, v):
	
	var deg60 = 60.0 / 360.0
	
	var hi = int(floor(h / deg60))
	var f = (h / deg60) - hi
	
	var p = v * ( 1.0 - s)
	var q = v * ( 1.0 - s * f)
	var t = v * ( 1.0 - s * ( 1.0 - f) )
	
	if hi == 0 or hi == 6:
		return Color(v, t, p)
	elif hi == 1:
		return Color(q, v, p)
	elif hi == 2:
		return Color(p, v, t)
	elif hi == 3:
		return Color(p, q, v)
	elif hi == 4:
		return Color(t, p, v)
	elif hi == 5:
		return Color(v, p, q)