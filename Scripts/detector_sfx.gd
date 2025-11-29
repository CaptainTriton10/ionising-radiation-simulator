extends AudioStreamPlayer2D

var target: float = 0.01
var current: float = 0

func _process(delta: float) -> void:
	var activity = $"..".total_activity
	var period = 1 / (0.0015 * activity)

	target = (period) * randf_range(0.1, 10)
		
	current += delta
	
	if current >= target and $"..".get_meta("play_sfx"):
		current = 0
		playing = true
