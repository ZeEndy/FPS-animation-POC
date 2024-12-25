extends SkeletonModifier3D
class_name BulletBones

#This is a simple moddifier to handle dealing with bullet placement in the weapons using a naming convention to loop trough a list of bones
#The casing mode slightly changes the logic to allow the spawning of casing in certain conditions

@export_node_path("MeshInstance3D") var ModelPath
@export_node_path("MeshInstance3D") var MagPath
var skeleton : Skeleton3D
@export var DebugIgnoreMag:=false

@onready var Mag = get_node(MagPath)
var Model : MeshInstance3D

var InitModels := false

@export var NamingConvention = "GUN_Mag1Bullet"
var BoneArray:=[]
@export var MagSize = 50

@export_category("Casing mode")
@export var casing_mode=false
var CasinngRigid : RigidBody3D
var PhysicsSpeed : Vector3
var OldPosition : Vector3

func _ready() -> void:
	OldPosition=global_position
	if casing_mode==true:
		CasinngRigid = get_node("CasingRigid")

var global_delta = 0.0

func _process(delta : float) -> void:
	global_delta = delta
	pass

func _physics_process(delta: float) -> void:
	if !skeleton || !casing_mode:
		return
	PhysicsSpeed = (OldPosition-global_position)/delta
	#PhysicsSpeed=PhysicsSpeed.abs().minf(1.0)
	#print(PhysicsSpeed)
	OldPosition = global_position
	
func _process_modification() -> void:
	skeleton = get_skeleton()
	if !skeleton:
		return
	if !ModelPath:
		return
	else:
		if Model == null:
			Model = get_node(ModelPath)
			for i in MagSize+1:
				var BoneCheck = skeleton.find_bone(NamingConvention+str(i))
				if BoneCheck != -1:
					var ChildMesh = Model.duplicate()
					add_child(ChildMesh)
					BoneArray.append([BoneCheck,ChildMesh])
	for i in BoneArray:
		var CModel = i[1] as MeshInstance3D
		var OldTransform = CModel.global_transform
		CModel.transform = skeleton.get_bone_global_pose(i[0])
		var saved_visible=CModel.visible
		CModel.visible=(CModel.scale>Vector3.ONE*0.98 && (Mag.visible == true || DebugIgnoreMag==true))
		if casing_mode==true:
			if CModel.visible==false && saved_visible==true:
				var LinearVelocity = ((CModel.global_transform.origin-OldTransform.origin)/global_delta)
				var RandomDir=(Vector3.ZERO.direction_to(LinearVelocity)*Vector3(randf_range(0.5,1.0),randf_range(0.5,1.0),randf_range(0.5,1.0))).normalized()
				var RandomizedSpeed=0.0
				var Particle : RigidBody3D = CasinngRigid.duplicate()
				get_tree().current_scene.add_child(Particle)
				
				Particle.global_transform=CModel.global_transform
				Particle.global_position+=LinearVelocity*global_delta
				Particle.set_deferred("linear_velocity",LinearVelocity)
				Particle.call_deferred("apply_central_impulse",-PhysicsSpeed*Particle.mass)
				Particle.freeze=false
				Particle.visible=true
				Particle.scale=Vector3(1,1,1)
				Particle.angular_velocity = (CModel.global_transform.basis*OldTransform.basis.inverse()).get_euler()/global_delta*Vector3(randf_range(0.5,1.0),randf_range(0.5,1.0),randf_range(0.5,1.0))
	
	
	
#func MoveBullets(SModel,skeleton,i):
	#SModel.transform = skeleton.get_bone_global_pose(i[0])
