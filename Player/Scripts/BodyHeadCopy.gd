@tool
extends SkeletonModifier3D
class_name BodyHeadCopy

var OldTarget_1 : Skeleton3D
var Target_1 : Skeleton3D
@export_node_path("Skeleton3D") var Target_1_Path

var OldRotation : Basis
var BoneRotation : Basis
var ReturnedRotation : Basis

var interp : float = 0.0



func _process(delta: float) -> void:
	interp=ExpDecay(interp,1,2,delta)

func _process_modification() -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if !skeleton:
		return # Never happen, but for the safety.
	ReturnedRotation=skeleton.get_bone_pose(skeleton.find_bone("Head")).basis
	#process only if we have a target and IK
	if Target_1==null:
		if Target_1_Path==null:
			return
		Target_1=get_node_or_null(Target_1_Path)
		OldTarget_1=Target_1
		if !is_instance_valid(Target_1):
			return
			
	if Target_1!=OldTarget_1:
		OldRotation=ReturnedRotation
		OldTarget_1=Target_1
		interp = 0.0
		
	
	
	#FUCK YOU GODOT
	CopyBones(skeleton,Target_1,"Head")
	ReturnedRotation=skeleton.get_bone_pose(skeleton.find_bone("Head")).basis

func CopyBones(my_skeleton:Skeleton3D, target_skeleton: Skeleton3D ,bone_name : String):
	var my_bone_id  = my_skeleton.find_bone(bone_name)
	var targ_bone_id = target_skeleton.find_bone(bone_name)
	if targ_bone_id==null:
		return
	my_skeleton.set_bone_pose(my_bone_id,target_skeleton.get_bone_pose(targ_bone_id))

static func ExpDecay(a,b,decay,dt):
	return b+(a-b)*exp(-decay*dt)
