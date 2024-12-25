@tool
class_name BodyTwistBoneConstraint
extends SkeletonModifier3D

#This modifier is just a 1:1 of a blender driver to fix wrist rotation
#same vaules just with a bit of code to get the Y quat from the target rotation
#can be applied to anything else that has some kind of twist to automagicially fix weirdness
#only issue is that godot still uses LBS ( Linear Blend Skinning ) so it still looks like shit
#fix for this is to either implement a shader that uses a better skinning method (dual quaternion skinning or direct delta mush skinning)
#or add a bunch of helper bones to get rid of the candy wrapper issue ala Last of Us

@export_enum(" ") var TwistBone: String
@export_enum(" ") var TargetBone: String

@export_flags("X","Y","Z") var RotationAxis

@export var flip=false


func _validate_property(property: Dictionary) -> void:
	if property.name == "TwistBone":
		var skeleton: Skeleton3D = get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()
	if property.name == "TargetBone":
		var skeleton: Skeleton3D = get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()

func _process_modification() -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if !skeleton:
		return # Never happen, but for the safety.
	var TargetBasis = skeleton.get_bone_pose(skeleton.find_bone(TargetBone)).basis
	var TwistPose = skeleton.get_bone_pose(skeleton.find_bone(TwistBone))
	var TwistRest = skeleton.get_bone_rest(skeleton.find_bone(TwistBone))
	
	var DefaultQuat=TwistRest.basis.get_rotation_quaternion()
	var TargetQuat=TargetBasis.get_rotation_quaternion()
	var ya = sqrt((TargetQuat.w*TargetQuat.w)+(TargetQuat.y*TargetQuat.y))
	
	var NewQuat = Quaternion(0,TargetQuat.y,0,TargetQuat.w/ya)
	
	
	var adjustfix=1
	if flip==true:
		adjustfix=-1
	var NewNewQuat=DefaultQuat*NewQuat.normalized().inverse()*Quaternion.from_euler(Vector3(0,PI*0.5*adjustfix,0))
	TwistPose.basis=Basis(DefaultQuat.slerp(NewNewQuat,0.75))
	TwistPose.origin.y+=abs(TargetQuat.z * .025)
	skeleton.set_bone_pose(skeleton.find_bone(TwistBone),TwistPose)
