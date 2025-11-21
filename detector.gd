extends Marker2D

var debug_obstructions: Array:
	set(value):
		debug_obstructions = value
		queue_redraw()

var debug_hits: Array:
	set(value):
		debug_hits = value
		queue_redraw()

@export var total_activity: float
@onready var environment: Node = $".."

func _draw() -> void:
	if get_meta("draw_debug") and !debug_hits.is_empty():
		# Draw functions are relative to the node, this offsets it
		var pos = Vector2.ZERO - global_position
		
		for obstruction in debug_obstructions:
			draw_line(pos + obstruction[0], pos + obstruction[1], Color.GREEN, 2)
		
		for hit in debug_hits:
			draw_circle(pos + hit.position, 3, Color.BLUE)

func _physics_process(_delta: float) -> void:
	# idrk what this does, but it is nescessary for physics raycasts
	var space_state = get_world_2d().direct_space_state
	
	var rad_sources: Array[Node] = get_tree().get_nodes_in_group("rad_source")
	
	# Moves detector to mouse pos
	global_position = get_global_mouse_position()
	
	total_activity = calculate_total_activity(space_state, rad_sources)
	
func calculate_total_activity(space_state: PhysicsDirectSpaceState2D, rad_sources: Array[Node]) -> float:
	var activity = 0
	
	# Reset debug drawings
	debug_hits = []
	debug_obstructions = []
	
	for rad_source in rad_sources:
		# Get collision pairs from the detector to the rad source(s)
		
		# It's actually an Tuple[Array, Array], but that's between you and me
		var hits: Array = get_rad_source_path(space_state, rad_source.global_position) 

		# Calculates the stopping power of the objects in between the detector and rad source
		var obstruction_power = get_obstruction_power(hits[0], hits[1], rad_source.global_position)
		
		# Calculates the total activity as a measure of the average period in between particle emissions
		activity += obstruction_power
		
	return 50 / (activity + environment.background_rad)

func get_rad_source_path(space_state: PhysicsDirectSpaceState2D, rad_source: Vector2) -> Array:				
	var hit_objects2: Array = []
	var hit_objects: Array = []
	
	# From detector to rad source (forwards)
	var from = global_position

	# Number of iterations, to prevent while loop continuing infinitely
	var iterations = 0
	
	var prev_objects = []
	
	# If hit object, keep on going until nothing hit
	while true:
		# Ray query
		var query = PhysicsRayQueryParameters2D.create(from, rad_source)
		query.collide_with_areas = true
		query.exclude = prev_objects
		
		# Cast ray
		var result = space_state.intersect_ray(query)
		
		# Stop at 50 objects, or if nothing hit
		if result.is_empty() or iterations >= 50:
			break
			
		# Updates next ray to be from the last collision
		from = result.position
		hit_objects.append(result)
		prev_objects.append(result.rid)
		
		debug_hits.append(result)
		
		iterations += 1
	
	# From rad source to detector (backwards)
	from = rad_source
	iterations = 0
	
	prev_objects = []
		
	# If hit object, keep on going until nothing hit
	while true:
		var query = PhysicsRayQueryParameters2D.create(from, global_position)
		query.collide_with_areas = true
		query.exclude = prev_objects
		
		# Cast ray
		var result = space_state.intersect_ray(query)
		
		# Stop at 50 objects, or if nothing hit
		if result.is_empty() or iterations >= 50:
			break
			
		from = result.position
		hit_objects2.append(result)
		prev_objects.append(result.rid)
		
		debug_hits.append(result)
		
		iterations += 1

	return [hit_objects, hit_objects2]

# Get the total 'strength' of the obstructions in between the rad source and detector
# Accounts for material density, thickness and distance to rad source
func get_obstruction_power(obstructions1: Array, obstructions2: Array, rad_source: Vector2) -> float:
	var total_power: float = 0

	# Simple pythag to calculate the distance from the detector to the rad source
	var a = global_position.x - rad_source.x
	var b = global_position.y - rad_source.y
	
	# Use the inverse square law for power attenuation
	var distance_power = 5000 / sqrt(a ** 2 + b ** 2) ** 0.5
	
	# If arrays are different sizes, remove last element of 2nd array (detector is clipping)
	if len(obstructions1) != len(obstructions2):
		obstructions2.remove_at(len(obstructions2) - 1)
	
	# If no objects hit, just use the distance
	if obstructions1.is_empty() and obstructions2.is_empty():
		total_power += distance_power
	
	# 2nd array is backwards so it must be reversed
	obstructions2.reverse()
	
	var obstructions = []

	for j in range(len(obstructions1)):
		obstructions.append([obstructions1[j].position, obstructions2[j].position])
	
	var total_thickness = 0
	
	for obstruction in obstructions:
		a = obstruction[0].x - obstruction[1].x
		b = obstruction[0].y - obstruction[1].y
		
		debug_obstructions.append([obstruction[0], obstruction[1]])
		
		total_thickness += sqrt(a ** 2 + b ** 2)
		
	# Arbitrary value, smaller value means the material can stop more 
	# radiation, larger value means less of an effect
	var lambda = 0.05
	var reduction_multiplier = exp(-(total_thickness / 650) / lambda)

	total_power += distance_power * reduction_multiplier

	return total_power
