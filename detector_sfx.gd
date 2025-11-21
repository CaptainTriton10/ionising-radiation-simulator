extends AudioStreamPlayer2D

var target: float = 0.01
var current: float = 0

func _process(delta: float) -> void:
	var detector = $".."
	
	target = detector.total_activity * randf_range(0.1, 10)
	
	current += delta
	if current >= target:
		current = 0
		playing = true
