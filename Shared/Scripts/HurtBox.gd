extends Area3D

class_name HurtBox
signal Hit(HealthRemove : float)
@export var Multiplier = 1.0
@onready var HitSound = get_node_or_null("HitSound")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func RecieveHit(Damage:float):
	if HitSound!=null:
		HitSound.play()
	Hit.emit(Damage*Multiplier)
