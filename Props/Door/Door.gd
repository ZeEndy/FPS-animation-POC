extends AnimatableBody3D

class_name Door

var ApproachBack = false

var HandReady = false

var Open = false

var User=null

enum ReqHand{
	Left,
	Right,
	Both
}

@export var RequestedHand = ReqHand.Left
@onready var skeleton = get_node("Door2/godot_rig/GeneralSkeleton")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if User!=null:
		if RequestedHand==ReqHand.Left && User.BodyCopyLeft.NextTarget==null:
			User.BodyCopyLeft.NextTarget=skeleton
			if User.BodyCopyLeft.Target_1==skeleton:
				HandReady=true
	pass

func interact(param_user : Player):
	User=param_user
	pass

func FreeUser():
	User.BodyCopyLeft.NextTarget=null
	User.RestoreEquipStates()
	User=null
	HandReady=false
	
