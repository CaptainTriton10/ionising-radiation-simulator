extends Label

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var rad_source = $".."
	
	var half_life = rad_source.get_meta("half_life")
	half_life = int(half_life) if half_life > 1 else half_life # Truncate 0s
	
	var label_text = "Mass: %sg\nAtomic Mass: %s\nHalf-life: %ss"
	text = label_text % [rad_source.get_meta("mass"), rad_source.get_meta("element"), half_life]
