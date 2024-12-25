@tool
extends SkeletonModifier3D
class_name PreCopyAttachment

@export_enum(" ") var bone: String

func _validate_property(property: Dictionary) -> void:
	if property.name == "bone":
		var skeleton: Skeleton3D = get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()



func _process_modification() -> void:
	#process only if we have a target and IK
	if bone=="":
		return
	var skeleton = get_skeleton()
	if skeleton == null:
		return
	var bone_idx = skeleton.find_bone(bone)
	transform = skeleton.get_bone_global_pose(bone_idx)
	
