@tool
extends SkeletonModifier3D
class_name BodySideCopy

#concept for this system is pretty simple
#you take the current skeleton we want to modify and the target skeleton and start with a certain bone
#in this case you'd be starting from one of the shoulders
#after that you just get the bone's pose and NOT the global pose and apply to the current skeleton
#if you use global pose it will copy the pose in global space and if the roots are not the same it will not apply the pose properly
#after applying the pose you get the next bones in the current skeletons tree and loop until the end or the target doesn't have that specific bone
#the last one shouldn't happen but its there just incase


#//WARNING//
#The interpolation does not work in this version of the system since the previous pose is not saved
#I recommend to slightly rewrite this code push the pose to an array or dictonary that way when the target is lost you can interpolate
#not only between just disabeling but also switching targets.
#I had made an attempt but gave up

#along with that to whomever tries to copy this script, dont bother as its unoptimzed as hell.
#You're better off rewriting everything to allow caching as without caching this script is super heavy




#tldr; this script copies a part of the targeted skeleton, runs like ass and does no caching for the copied pose and the bone structure
#use as a refrence and nothing more
 
var Target_1 : ValidSkeleton3D
var NextTarget : ValidSkeleton3D
var SwapTarget : float = 0.0
@export_node_path("Skeleton3D") var Target_1_Path
@export_enum("Left","Right") var Side : String = "Left"
var IK : SkeletonIK3D
@export_node_path("SkeletonIK3D") var IK_target_path

var ExclusionArray=[]
func _ready() -> void:
	var skeleton = get_skeleton()
	#these two are wrists and since they are a part of the body only and move through code only we dont want to mess with them in any way
	#and this way we dont need to search for it
	ExclusionArray.append(skeleton.find_bone("DEF-wrist.L"))
	ExclusionArray.append(skeleton.find_bone("DEF-wrist.R"))

func _process(delta: float) -> void:
	if Target_1!=NextTarget:
		SwapTarget=min(SwapTarget+delta*10,1.0)
		Target_1=NextTarget
	else:
		SwapTarget=0.0
		NextTarget=null

func _process_modification() -> void:
	#process only if we have a target and IK
	if Target_1==null:
		if IK:
			IK.influence=0.0
		if Target_1_Path==null:
			return
		Target_1=get_node_or_null(Target_1_Path)
		if !is_instance_valid(Target_1):
			return
	
	
	if IK==null:
		IK=get_node_or_null(IK_target_path)
		if !is_instance_valid(IK):
			return
		else:
			IK.start()
	
	var skeleton: Skeleton3D = get_skeleton()
	if !skeleton:
		return # Never happen, but for the safety.
	await Target_1.skeleton_updated 
	#wait for the target to finish dealing with its modifiers & animations
	
	if Target_1!=null: 
		# check weather the skeleton still exists just incase
		CopyBones(skeleton,Target_1,Side+"Shoulder",false,influence)
		IKHands(skeleton,Target_1,1.0)
	
	if NextTarget!=null:
		CopyBones(skeleton,NextTarget,Side+"Shoulder",false,SwapTarget)
		IKHands(skeleton,NextTarget,SwapTarget)

func CopyBones(my_skeleton:Skeleton3D, target_skeleton: Skeleton3D ,bone_name : String, can_scale := false, Influnace:float = 1.0):
	var my_bone_id  = my_skeleton.find_bone(bone_name)
	var targ_bone_id = target_skeleton.find_bone(bone_name)
	if targ_bone_id==null:
		return
	
	var target_transform = target_skeleton.get_bone_pose(targ_bone_id)
	var old_transform = my_skeleton.get_bone_pose(my_bone_id)
	if can_scale==true:
		my_skeleton.set_bone_pose(my_bone_id,target_transform)
	else:
		target_transform.basis.x = target_transform.basis.x.normalized()
		target_transform.basis.y = target_transform.basis.y.normalized()
		target_transform.basis.z = target_transform.basis.z.normalized()
		my_skeleton.set_bone_pose(my_bone_id,old_transform.interpolate_with(target_transform,Influnace))
	var bone_children = my_skeleton.get_bone_children(my_bone_id)
	
	if bone_name.contains("Hand"):
		can_scale=true
	
	for i in bone_children:
		if !(i in ExclusionArray):
			CopyBones(my_skeleton,target_skeleton,my_skeleton.get_bone_name(i),can_scale,Influnace)

func IKHands(skeleton,Target,Influnace):
	#since blending sucks due to the bone structure this the best fix for it
	#There are technically 2 bones per hand but 1 is for the body and the other is for the object
	#if IK isn't used and we just want the motion itself from the target we can just reduce the inflance to zero and get the hand motion
	#as if it was part of the body.
	#useful in some instances where the hand isn't holding any objects
	var IKHand = Target.find_bone("IKHand"+Side.left(1))
	var IKHandTransform = Target.get_bone_global_pose(IKHand)
	var RestBasis = Target.get_bone_global_rest(IKHand).basis
	
	IKHandTransform.basis*=RestBasis.inverse()
	
	var interp=0.0
	if Side=="Left":
		interp=Target.Use_IK_HandLeft
	if Side=="Right":
		interp=Target.Use_IK_HandRight
	IK.influence=lerp(IK.influence,interp,Influnace)
	IK.target = IK.target.interpolate_with(Target.global_transform * IKHandTransform,Influnace)


static func ExpDecay(a,b,decay,dt):
	return b+(a-b)*exp(-decay*dt)
