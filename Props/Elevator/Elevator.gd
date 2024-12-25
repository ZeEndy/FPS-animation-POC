extends AnimatableBody3D


# Called when the node enters the scene tree for the first time.
@export var SelectTargets : Array[NodePath]
var Targets : Array
var CurrentTarget=0
@export_range(1,20,1,"suffix:km/h") var MaxSpeed : float = 8.
var Speed : float = 0.0

var Arrived=true
var StartStop=false
@onready var MovingAudio : AudioStreamPlayer3D = get_node("Model/Elevator/Skeleton3D/MovingAudio")
@onready var Bell : AudioStreamPlayer3D = get_node("Model/Elevator/Skeleton3D/Bell")
var BellPlayed=false
@export var IsStatic :=false
@export var AutoMoveTarget := -1

func _ready() -> void:
	if SelectTargets.size()==0:
		IsStatic=true
	else:
		for i in SelectTargets:
			Targets.append(get_node(i))
			
	if AutoMoveTarget!= -1:
		CurrentTarget=AutoMoveTarget
		MovingAudio["parameters/switch_to_clip"]="Move Loop"
		Arrived=false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if Arrived==false:
		
		var DistToTarget=global_position.distance_to(Targets[CurrentTarget].global_position)
		if DistToTarget>3.0:
			Speed=ExpDecay(Speed,MaxSpeed*0.277778,10,delta)
		else:
			Speed=ExpDecay(Speed,MaxSpeed*0.277778*max(min(DistToTarget,2),0.01),30,delta)
			if StartStop==false:
				StartStop=true
				MovingAudio["parameters/switch_to_clip"]="Move End"
		if DistToTarget<0.05 && BellPlayed==false:
			BellPlayed=true
			Bell.play()
		var NewPosition=global_position.move_toward(Targets[CurrentTarget].global_position,Speed*delta)
		global_position=NewPosition
		if global_position.distance_to(Targets[CurrentTarget].global_position)==0.0:
			Arrived=true
	pass



static func ExpDecay(a,b,decay,dt):
	if typeof(a)==TYPE_BASIS:
		var result = Basis.IDENTITY
		result.x = ExpDecay(a.x,b.x,decay,dt)
		result.y = ExpDecay(a.y,b.y,decay,dt)
		result.z = ExpDecay(a.z,b.z,decay,dt)
		return result.orthonormalized()
	return b+(a-b)*exp(-decay*dt)
