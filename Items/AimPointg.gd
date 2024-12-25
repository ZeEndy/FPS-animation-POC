extends Marker3D

@export var FovMultip = 1.0

@onready var BringUpPoint : Marker3D = get_node("BringUpPoint")
@onready var Remote : RemoteTransform3D = get_node("Remote")
@export_node_path("Marker3D") var RealPointPath
@onready var RealPoint = get_node(RealPointPath)


var RemoveBringUp = 0.0
var TimeOut = 0.0



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Remote.transform = BringUpPoint.transform
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	TimeOut-=delta
	if TimeOut<=0.0:
		RemoveBringUp = max(0.0,RemoveBringUp-delta*20)
		var Transform = Transform3D()
		Remote.transform = BringUpPoint.transform.interpolate_with(Transform3D(),RemoveBringUp)
	pass

func get_real_point_node(delta : float):
	RemoveBringUp = min(1.0,RemoveBringUp+delta*20)
	var Transform = Transform3D()
	Remote.transform = BringUpPoint.transform.interpolate_with(Transform3D(),RemoveBringUp)
	TimeOut=delta*2
	return RealPoint
