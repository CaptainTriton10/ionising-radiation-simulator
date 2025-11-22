extends Marker2D

@export var activity: float
@onready var half_life: float = self.get_meta("half_life")

func ln(x: float) -> float:
	var e = exp(1)
	
	return log(x) / log(e)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var molar_mass: int = self.get_meta("element")
	var mass: float = self.get_meta("mass")
	
	var nuclei = 6.022E23 * (mass / molar_mass)
	
	activity = nuclei * (ln(2) / half_life)

func _process(delta: float) -> void:
	activity *= 0.5**(delta / half_life)
