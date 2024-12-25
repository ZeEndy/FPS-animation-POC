extends CharacterBody3D

class_name  Player

#The code for the player character is somewhat simple but I would NOT recommend using this.
#This controller is very much thrown together as a form of glue for all the systems in this demo
#and there hasn't been any future proofing of any kind done to make this work in other games
#along with the code just being very bad in general

#The only good parts of the code are MoveNodeRelativeToPointsDynamics() MoveNodeRelativeToPointsGeneric() MoveNodeRelativeToPointsLerp()
#These are very useful functions for aligning nodes relative to a point inside said nodes
#Everything else should not be used in any project. 

const CROUCHED_SPEED = 1.38889
const JOGGING_SPEED = 2.69444
const RUNNING_SPEED = 3.88889
const SPRINT_SPEED = 6.66667


enum SpeedState{
	Stop,
	Jog,
	Run,
	Sprint,
	Crouched
}

signal WatchChanged()

enum GroundState{
	Stand,
	Crouch,
	Jump
}

var CSpeedState=SpeedState.Jog
var CGroundState=GroundState.Stand
var MovementPoint = Vector2(0,0)
const JUMP_VELOCITY = 4.5

var CutscenePlayback : AnimationNodeStateMachinePlayback
var Head := Vector3(0,0,0)
var HeadDelay := Vector3(0,0,0)
var AddedZoom=1.0
@onready var CameraHolder = get_node("Body/CameraHolder")

@onready var ShoulderPoint : Marker3D = get_node("Body/CameraHolder/Hands/godot_rig/GeneralSkeleton/PreCopyAttachment/ShoulderPoint")
@onready var Hands : Node3D = get_node("Body/CameraHolder/Hands")
@onready var EquipedItems : Node3D = get_node("Body/CameraHolder/Equiped")
@onready var BodyCopyLeft  : BodySideCopy= get_node("Body/CameraHolder/Hands/godot_rig/GeneralSkeleton/BodyCopyLeft")
@onready var BodyCopyRight : BodySideCopy = get_node("Body/CameraHolder/Hands/godot_rig/GeneralSkeleton/BodyCopyRight")
@onready var BodyCopyHead : BodyHeadCopy = get_node("Body/CameraHolder/Hands/godot_rig/GeneralSkeleton/BodyHeadCopy")

@onready var Camera : Camera3D = get_node("Body/CameraHolder/Camera3D")
@onready var Crosshair : Sprite3D = get_node("Body/CameraHolder/Sprite3D")

@onready var InteractCast : RayCast3D = get_node("Body/CameraHolder/Camera3D/InteractCast")



var ADSFollowSpeed = 1.0
var ADSFollowStrength = 0.0

var Stamina = 3.0


var RecoilRemove = Vector3(0.0,0.0,0.0)
var BaseFov = 20.0

@onready var AnimTree : AnimationTree = get_node("Body/CameraHolder/AnimationTree")

var CustomState=""

func _ready() -> void:
	Head.y = global_rotation.y
	global_rotation.y = 0.0
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	AnimTree["parameters/CutsceneOneshot/request"]=AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	CutscenePlayback=AnimTree["parameters/Cutscene/playback"]
	CutscenePlayback.start("Intro")
	Watch.MenuStatusChanged.connect(BringUpMenu)
	#print(AnimTree.get_property_list())


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("Crouch"):
		if CGroundState==GroundState.Stand:
			CGroundState=GroundState.Crouch
		else:
			CGroundState=GroundState.Stand
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("LEFT", "RIGHT", "UP", "DOWN")
	if Watch.MenuEnabled:
		input_dir=Vector2.ZERO
	var direction := (Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP,Head.y)).normalized()
	
	if CSpeedState==SpeedState.Sprint:
		Stamina=max(Stamina-delta,0.0)
		if Stamina==0.0:
			CSpeedState=SpeedState.Run
	else:
		Stamina=min(Stamina+delta,3)
	
	if CGroundState==GroundState.Stand:
		if input_dir.length()>0.1:
			if CSpeedState==SpeedState.Stop || CSpeedState==SpeedState.Crouched || Input.is_action_pressed("ACTION2") || Input.is_action_pressed("ACTION1"):
				CSpeedState=SpeedState.Jog
			if Input.is_action_just_pressed("RUN") && !Input.is_action_pressed("ACTION2") && !Input.is_action_pressed("ACTION1"):
				if CSpeedState==SpeedState.Jog:
					CSpeedState=SpeedState.Run
				elif CSpeedState==SpeedState.Run && Stamina>1.0:
					CSpeedState=SpeedState.Sprint
		else:
			CSpeedState=SpeedState.Stop
	elif CGroundState==GroundState.Crouch:
		if input_dir.length()>0.1:
			CSpeedState=SpeedState.Crouched
		else:
			CSpeedState=SpeedState.Stop
	
	
	
	var CurrentSpeed=get_movement_speed(CSpeedState)
	if direction:
		#velocity.x = direction.x * CurrentSpeed
		#velocity.z = direction.z * CurrentSpeed
		velocity.x = ExpDecay(velocity.x,direction.x * CurrentSpeed,20,delta)
		velocity.z = ExpDecay(velocity.z,direction.z * CurrentSpeed,20,delta)
	else:
		velocity.x = ExpDecay(velocity.x,0,20,delta)
		velocity.z = ExpDecay(velocity.z,0,20,delta)
		#velocity.z = 0
		#velocity.x = 0
	move_and_slide()
	
	if InteractCast.is_colliding():
		var GotObj = InteractCast.get_collider()
		if GotObj is Weapon && Input.is_action_just_pressed("ACTION3"):
			PickUpWeapon(GotObj)
		if GotObj is Door && Input.is_action_just_pressed("ACTION3"):
			RemoveEquipedVis(EquipedItems.get_children())
			for i in EquipedItems.get_children():
				if i is Weapon && i.CurProcess==Weapon.ProcessMode.Equiped:
					if GotObj.RequestedHand==Door.ReqHand.Left:
						i.CurBeheivour=Weapon.InvBeheiv.EquipedVisLeft
						i.CurProcess=Weapon.ProcessMode.EquipedVis
					elif GotObj.RequestedHand==Door.ReqHand.Right:
						i.CurBeheivour=Weapon.InvBeheiv.EquipedVisRight
						i.CurProcess=Weapon.ProcessMode.EquipedVis
					else:
						i.CurProcess=Weapon.ProcessMode.Holstered
						i.CurBeheivour=Weapon.InvBeheiv.Holstered
					
			GotObj.interact(self)


func PickUpWeapon(GotWeapon : Weapon):
	if EquipedItems.get_child_count()==0:
		GotWeapon.reparent(EquipedItems)
		GotWeapon.set_holder(self)
		GotWeapon.teleport=true
		GotWeapon.visible=false
		GotWeapon.CurBeheivour=Weapon.InvBeheiv.Equiped
		GotWeapon.CurProcess=Weapon.ProcessMode.Equiped
	else:
		GotWeapon.reparent(EquipedItems)
		GotWeapon.set_holder(self)
		GotWeapon.AnimTree["parameters/Inactive/blend_amount"]=1.0
		GotWeapon.teleport=true
		GotWeapon.visible=false
		GotWeapon.CurBeheivour=Weapon.InvBeheiv.Holstered
		GotWeapon.CurProcess=Weapon.ProcessMode.Holstered

func _process(delta: float) -> void:
	Engine.time_scale=1.0-0.9*Input.get_action_strength("DEBUGSLOW")
	if Input.is_action_just_pressed("ui_left"):
		Head.y+=PI*0.1
	var OldRotation=CameraHolder.global_rotation
	CameraHolder.global_rotation=Head
	Camera.basis=Basis.IDENTITY.slerp(BodyCopyHead.ReturnedRotation.orthonormalized(),float(Settings.MotionShake["value"])).orthonormalized()
	BaseFov=ExpDecay(BaseFov,100.0/(BodyCopyHead.ReturnedRotation.get_scale().length()*0.5780346820809249),20,delta)
	Camera.fov=ExpDecay(Camera.fov,BaseFov*AddedZoom,40,delta)
	#print(BodyCopyHead.ReturnedRotation.get_scale().length())
	HeadDelay=ExpDecayAngle(HeadDelay,Head,90,delta)
	#reduce stupid movement
	EquipedItems.rotation=ExpDecayAngle(EquipedItems.rotation,HeadDelay-CameraHolder.global_rotation,50,delta)
	var multiplier = 1.75
	if CSpeedState!=SpeedState.Stop:
		multiplier=(get_real_velocity()*Vector3(1,0,1)).length()/get_movement_speed(CSpeedState)*1.75
	AnimTree["parameters/Speed/scale"] = ExpDecay(AnimTree["parameters/Speed/scale"],log(float(CSpeedState+1-3*float(CSpeedState==SpeedState.Crouched)))*multiplier,20,delta)
	AnimTree["parameters/MovementAnim/blend_position"]=ExpDecay(AnimTree["parameters/MovementAnim/blend_position"],MovementPoint ,10 ,delta)
	AnimTree["parameters/Idle/blend_amount"] = clamp(ExpDecay(AnimTree["parameters/Idle/blend_amount"] ,float(CSpeedState),10,delta),0,1)
	var EquipedChildren = EquipedItems.get_children()
	
	Crosshair.modulate.a=1-min(ADSFollowStrength*2.5,1.0)
	for i in EquipedChildren:
		if i is Weapon:
			if i.CurProcess==Weapon.ProcessMode.Equiped:
				Weapon_Equiped(i,delta)
			if i.CurProcess==Weapon.ProcessMode.EquipedVis:
				Weapon_EquipedVis(i,delta)
			if i.CurProcess==Weapon.ProcessMode.Holstered:
				Weapon_Holstered(i,delta)
			
	if Input.is_action_just_pressed("ACTION4"):
		RemoveEquipedVis(EquipedChildren)
	
	
	if Input.is_action_just_pressed("SwapWeapons"):
		SwapWeapons(EquipedChildren)
	if Watch.MenuEnabled:
		if Input.is_action_just_pressed("UP"):
			CutscenePlayback.start("Watch Menu Up")
		if Input.is_action_just_pressed("DOWN"):
			CutscenePlayback.start("Watch Menu Down")


func BringUpMenu():
	var WeaponChildren = EquipedItems.get_children()
	if Watch.MenuEnabled==false:
		if AnimTree["parameters/CutsceneOneshot/active"]==false:
			RemoveEquipedVis(WeaponChildren)
			for i in WeaponChildren:
				if i is Weapon  && i.CurProcess==Weapon.ProcessMode.Equiped:
					i.CurBeheivour=Weapon.InvBeheiv.Holstered
					i.CurProcess=Weapon.ProcessMode.Holstered
					i.AdsAudio(false)
					
					await i.Holstered
					i.AnimTree["parameters/Inactive/blend_amount"]=1.0
					BodyCopyLeft.Target_1=null
					BodyCopyRight.Target_1=null
					BodyCopyHead.Target_1=null
			AnimTree["parameters/CutsceneOneshot/request"]=AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
			CutscenePlayback.start("Menu Open")
	else:
		CutscenePlayback.travel("Menu Close")
		await WatchChanged
		RestoreEquipStates()


func SwapWeapons(ItemChildren):
	for i in ItemChildren:
		if i is Weapon && i.CurProcess==Weapon.ProcessMode.Equiped:
			var GotHolsteredWeapon : Weapon = null
			var EquipedVisCheck = false
			for x in ItemChildren:
				if x.CurProcess!=Weapon.ProcessMode.Equiped:
					if x.CurProcess==Weapon.ProcessMode.EquipedVis:
						EquipedVisCheck=true
					GotHolsteredWeapon=x
					break
			if GotHolsteredWeapon!=null:
				if !EquipedVisCheck:
					if GotHolsteredWeapon.QuickSwapable==true && i.QuickSwapable==false:
						i.CurBeheivour=Weapon.InvBeheiv.EquipedVisRight
						i.CurProcess=Weapon.ProcessMode.EquipedVis
						i.AdsAudio(false)
						GotHolsteredWeapon.QuickSwaped=true
						await i.RightLetGo
						GotHolsteredWeapon.CurProcess=Weapon.ProcessMode.Equiped
						GotHolsteredWeapon.CurBeheivour=Weapon.InvBeheiv.Equiped
						GotHolsteredWeapon.teleport=true
						GotHolsteredWeapon.AnimTree["parameters/Inactive/blend_amount"]=0.0
					else:
						i.CurBeheivour=Weapon.InvBeheiv.Holstered
						i.CurProcess=Weapon.ProcessMode.Holstered
						i.AdsAudio(false)
						await i.Holstered
						GotHolsteredWeapon.CurProcess=Weapon.ProcessMode.Equiped
						GotHolsteredWeapon.teleport=true
						GotHolsteredWeapon.CurBeheivour=Weapon.InvBeheiv.Equiped
						i.AnimTree["parameters/Inactive/blend_amount"]=1.0
						GotHolsteredWeapon.AnimTree["parameters/Inactive/blend_amount"]=0.0
						
				else:
					i.CurBeheivour=Weapon.InvBeheiv.Holstered
					i.QuickSwaped=false
					i.CurProcess=Weapon.ProcessMode.Holstered
					i.AdsAudio(false)
					await i.Holstered
					GotHolsteredWeapon.teleport=true
					GotHolsteredWeapon.CurProcess=Weapon.ProcessMode.Equiped
					GotHolsteredWeapon.CurBeheivour=Weapon.InvBeheiv.Equiped
					GotHolsteredWeapon.AnimTree["parameters/Inactive/blend_amount"]=0.0
					i.AnimTree["parameters/Inactive/blend_amount"]=1.0
			
			break
func RestoreEquipStates():
	var children=EquipedItems.get_children()
	for i in children:
		if i is Weapon:
			if i.CurProcess==Weapon.ProcessMode.Equiped:
				return
	for i in children:
		if i is Weapon:
			if i.CurProcess==Weapon.ProcessMode.EquipedVis:
				i.CurProcess=Weapon.ProcessMode.Equiped
				i.CurBeheivour=Weapon.InvBeheiv.Equiped
				i.QuickSwaped=false
				return
	
	for i in children:
		if i is Weapon:
			if i.CurProcess==Weapon.ProcessMode.Holstered:
				i.CurProcess=Weapon.ProcessMode.Equiped
				i.CurBeheivour=Weapon.InvBeheiv.Equiped
				i.QuickSwaped=false
				await  i.skeleton.skeleton_updated
				i.visible=true
				return
			
	#if EquipedItems.get_child_count()==0:
		#for i in EquipedVisualItems.get_children():
			#if i is Weapon:
				#i.reparent(EquipedItems)
				#i.CurBeheivour=Weapon.InvBeheiv.Equiped
				#return
		#for i in HolsteredItems.get_children():
			#if i is Weapon:
				#i.reparent(EquipedItems)
				#i.CurBeheivour=Weapon.InvBeheiv.Equiped
				#return

func RemoveEquipedVis(Equipped):
	for i in Equipped:
		if i is Weapon && i.CurProcess==Weapon.ProcessMode.EquipedVis:
			i.CurBeheivour=Weapon.InvBeheiv.Holstered
			await i.Holstered
			i.CurProcess=Weapon.ProcessMode.Holstered
			i.AnimTree["parameters/Inactive/blend_amount"]=1.0
			for x in Equipped:
				if x is Weapon && x.CurProcess==Weapon.ProcessMode.Equiped:
					x.QuickSwaped=false
			return

func Weapon_Equiped(WeaponNode : Weapon , delta : float):
	WeaponNode.AnimTree["parameters/Inactive/blend_amount"]=0.0
	WeaponNode.set_holder(self)
	WeaponNode.MovementTime=AnimTree["parameters/MovementAnim/current_position"]
	WeaponNode.MovementSlider=float(CSpeedState)
	WeaponNode.MovementPoint=MovementPoint
	
	if WeaponNode.LeftInfluence>0:
		BodyCopyLeft.NextTarget = WeaponNode.skeleton
		#print(BodyCopyLeft.influence)
		BodyCopyLeft.influence = WeaponNode.CopyLeftInfluance
		
	if WeaponNode.RightInfluence>0:
		BodyCopyRight.NextTarget = WeaponNode.skeleton
		BodyCopyRight.influence = WeaponNode.CopyRightInfluance
	
	BodyCopyHead.Target_1 = WeaponNode.skeleton
	Camera.rotation*=1-0.5*ADSFollowStrength
	ShoulderPoint.look_at(Vector3(global_position.x,ShoulderPoint.global_position.y,global_position.z)+Vector3(250,0,0).rotated(Vector3.FORWARD,-Head.x).rotated(Vector3.UP,Head.y+PI*0.5))
	ShoulderPoint.position.x=0.025+Head.x*0.025
	ShoulderPoint.position.z=0.038-Head.x*0.0125
	
	
	RecoilRemove.x+=WeaponNode.RecoilRot.x*2*delta
	RecoilRemove.y-=WeaponNode.RecoilRot.y*2*delta
	
	#if WeaponNode.Firing==true:
	var RecoilOld=RecoilRemove
	RecoilRemove=RecoilRemove.lerp(Vector3.ZERO,20*delta)
	Head+=RecoilOld-RecoilRemove
	Head.x=clamp(Head.x,-PI*0.499,PI*0.499)
	if WeaponNode.teleport==false:
		if Input.is_action_pressed("ACTION2") && Vector2(velocity.x,velocity.z).length()<=RUNNING_SPEED*0.8 && WeaponNode.CurBeheivour==Weapon.InvBeheiv.Equiped && WeaponNode.CanADSMove==true:
			WeaponNode.AdsAudio(true)
			var SODOUTPUT = SOD(ADSFollowStrength,ADSFollowSpeed,1.0,Vector3(2.0,0.5,0.25),delta)
			ADSFollowStrength = SODOUTPUT["value"]
			ADSFollowSpeed = SODOUTPUT["velocity"]
			var MovementInput = Vector3(4.0+(6*ADSFollowStrength),0.3+(0.95*ADSFollowStrength),0.5+(0.2*ADSFollowStrength))
			
			MoveNodeRelativeToPointsDynamics(WeaponNode,CameraHolder,WeaponNode.ADSPoint.get_real_point_node(delta),MovementInput,MovementInput,delta)
			AddedZoom=ExpDecay(AddedZoom,WeaponNode.ADSPoint.FovMultip,40,delta)
			#Camera.fov=lerp(BaseFov,BaseFov*WeaponNode.ADSPoint.FovMultip,ADSFollowStrength)
		else:
			WeaponNode.AdsAudio(false)
			var SODOUTPUT = SOD(ADSFollowStrength,ADSFollowSpeed,0.0,Vector3(2.0,0.5,0.5),delta)
			ADSFollowStrength = SODOUTPUT["value"]
			ADSFollowSpeed = SODOUTPUT["velocity"]
			
			
			var sodinput = Vector3(10.0,1.5,0.2)
			#MoveNodeRelativeToPointsDynamics(WeaponNode,ShoulderPoint,WeaponNode.DefaultShoulderPoint,sodinput,sodinput,delta)
			MoveNodeRelativeToPointsGeneric(WeaponNode,ShoulderPoint,WeaponNode.DefaultShoulderPoint,30,30,delta)
			AddedZoom=ExpDecay(AddedZoom,1,40,delta)
	else:
		await  WeaponNode.skeleton.skeleton_updated
		await WeaponNode.AnimTree.mixer_applied
		MoveNodeRelativeToPointsLerp(WeaponNode,ShoulderPoint,WeaponNode.DefaultShoulderPoint,1,1,1)
		WeaponNode.teleport=false
		await  WeaponNode.skeleton.skeleton_updated
		await WeaponNode.AnimTree.mixer_applied
		WeaponNode.visible=true

func Weapon_EquipedVis(WeaponNode : Weapon , delta : float):
	if WeaponNode.LeftInfluence>0.05:
		BodyCopyLeft.NextTarget = WeaponNode.skeleton
	#elif BodyCopyLeft.NextTarget == WeaponNode.skeleton:
		#BodyCopyLeft.NextTarget = null
	if WeaponNode.RightInfluence>0.05:
		BodyCopyRight.NextTarget = WeaponNode.skeleton
	#BodyCopyLeft.SwapTarget = WeaponNode.LeftInfluence
	#BodyCopyRight.SwapTarget = WeaponNode.RightInfluence
	#elif BodyCopyRight.NextTarget == WeaponNode.skeleton:
		#BodyCopyRight.NextTarget = null
	
	MoveNodeRelativeToPointsGeneric(WeaponNode,ShoulderPoint,WeaponNode.DefaultShoulderPoint,30,30,delta)

func Weapon_Holstered(WeaponNode : Weapon , delta : float):
	if WeaponNode.AnimTree["parameters/Inactive/blend_amount"]==0.0:
		WeaponNode.visible=true
		if WeaponNode.LeftInfluence>0.05:
			BodyCopyLeft.NextTarget = WeaponNode.skeleton
		if WeaponNode.RightInfluence>0.05:
			BodyCopyRight.NextTarget = WeaponNode.skeleton
	else:
		WeaponNode.visible=false
	var SODOUTPUT = SOD(ADSFollowStrength,ADSFollowSpeed,0.0,Vector3(2.0,0.5,0.5),delta)
	ADSFollowStrength = SODOUTPUT["value"]
	ADSFollowSpeed = SODOUTPUT["velocity"]
	MoveNodeRelativeToPointsDynamics(WeaponNode,ShoulderPoint,WeaponNode.DefaultShoulderPoint,Vector3(5.0,0.85,0.75),Vector3(5.0,0.85,0.75),delta)


func MoveNodeRelativeToPointsGeneric(MovableNode : Node3D, DesiredPointNode : Node3D, OffsetPoint : Node3D ,PosSpeed,RotSpeed, delta : float):
	var DesiredTransform : Transform3D =  DesiredPointNode.global_transform
	var MovableTransform : Transform3D = MovableNode.global_transform
	
	var MpointGTransform : Transform3D = OffsetPoint.global_transform
	var MpointLTransform : Transform3D = OffsetPoint.transform
	var DesiredMpointRelativeTransform : Transform3D = DesiredTransform * MpointLTransform.inverse()
	var TargetRotation = (DesiredMpointRelativeTransform.basis )
	
	MovableNode.global_transform.basis = (MovableNode.global_transform.basis.orthonormalized()).slerp(TargetRotation.orthonormalized(),delta*RotSpeed).orthonormalized()
	MovableTransform = MovableNode.global_transform
	
	var OffsetPos : Vector3 = OffsetPoint.transform.origin
	OffsetPos = MovableNode.global_basis * OffsetPos
	
	var MovableRelativeTransf : Transform3D = MpointLTransform.affine_inverse() * MovableTransform
	var TargetPos : Vector3 = (DesiredPointNode.global_transform.origin - OffsetPos )
	
	MovableNode.global_transform.origin = ExpDecay(MovableNode.global_transform.origin,TargetPos,PosSpeed,delta)
#math lifted and fixed from https://www.youtube.com/watch?v=lsIba2HZQX0 as the code in the video has unstable in the basis math


func MoveNodeRelativeToPointsLerp(MovableNode : Node3D, DesiredPointNode : Node3D, OffsetPoint : Node3D ,PosSpeed,RotSpeed, delta : float):
	var DesiredTransform : Transform3D =  DesiredPointNode.global_transform
	var MovableTransform : Transform3D = MovableNode.global_transform
	
	var MpointGTransform : Transform3D = OffsetPoint.global_transform
	var MpointLTransform : Transform3D = OffsetPoint.transform
	var DesiredMpointRelativeTransform : Transform3D = DesiredTransform * MpointLTransform.inverse()
	var TargetRotation = (DesiredMpointRelativeTransform.basis )
	
	MovableNode.global_transform.basis = (MovableNode.global_transform.basis.orthonormalized()).slerp(TargetRotation.orthonormalized(),delta*RotSpeed).orthonormalized()
	MovableTransform = MovableNode.global_transform
	
	var OffsetPos : Vector3 = OffsetPoint.transform.origin
	OffsetPos = MovableNode.global_basis * OffsetPos
	
	var MovableRelativeTransf : Transform3D = MpointLTransform.affine_inverse() * MovableTransform
	var TargetPos : Vector3 = (DesiredPointNode.global_transform.origin - OffsetPos )
	
	MovableNode.global_transform.origin = lerp(MovableNode.global_transform.origin,TargetPos,PosSpeed*delta)


func MoveNodeRelativeToPointsDynamics(MovableNode : Weapon, DesiredPointNode : Node3D, OffsetPoint : Node3D ,PosInput:Vector3,RotInput:Vector3, delta : float):
	var DesiredTransform : Transform3D =  DesiredPointNode.global_transform
	var MovableTransform : Transform3D = MovableNode.global_transform
	
	var MpointGTransform : Transform3D = OffsetPoint.global_transform
	var MpointLTransform : Transform3D = OffsetPoint.transform
	var DesiredMpointRelativeTransform : Transform3D = DesiredTransform * MpointLTransform.inverse()
	var TargetRotation = (DesiredMpointRelativeTransform.basis)
	
	
	var DynamicsRotation=SOD(MovableNode.global_basis,MovableNode.VelocityAng,TargetRotation,RotInput,delta)
	MovableNode.VelocityAng = DynamicsRotation["velocity"]
	MovableNode.global_transform.basis = DynamicsRotation["value"].orthonormalized()
	MovableTransform = MovableNode.global_transform
	
	var OffsetPos : Vector3 = OffsetPoint.transform.origin
	OffsetPos = MovableNode.global_basis * OffsetPos
	
	var MovableRelativeTransf : Transform3D = MpointLTransform.affine_inverse() * MovableTransform
	var TargetPos : Vector3 = (DesiredPointNode.global_transform.origin - OffsetPos )
	
	#MovableNode.global_transform.origin = ExpDecay(MovableNode.global_transform.origin,TargetPos,PosSpeed,delta)
	var DynamicsPosition = SOD(MovableNode.global_transform.origin,MovableNode.VelocityPos,TargetPos,PosInput,delta)
	MovableNode.global_transform.origin = DynamicsPosition["value"]
	MovableNode.VelocityPos = DynamicsPosition["velocity"]
	
	#MovableNode.global_transform.origin = WeaponMovementVec3.update(delta,TargetPos)




func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion):
		var MouseMotion : InputEventMouseMotion = event
		Head.y-=MouseMotion.relative.x*0.001*Settings.MouseSens["value"]
		Head.x=clamp(Head.x-MouseMotion.relative.y*0.001*Settings.MouseSens["value"],-PI*0.499,PI*0.499)


func get_movement_speed(current_state):
	var outputspeed = 0.0
	match (current_state):
		SpeedState.Stop:
			outputspeed = 0.0
			MovementPoint = Vector2(0,0)
		SpeedState.Jog:
			outputspeed = JOGGING_SPEED
			MovementPoint = Vector2(0,0)
		SpeedState.Run:
			outputspeed = RUNNING_SPEED
			MovementPoint = Vector2(-1,1)
		SpeedState.Sprint:
			outputspeed = SPRINT_SPEED
			MovementPoint = Vector2(1,1)
		SpeedState.Crouched:
			outputspeed = CROUCHED_SPEED
			MovementPoint = Vector2(0,0)
	return outputspeed

static func ExpDecay(a,b,decay,dt):
	if typeof(a)==TYPE_BASIS:
		var result = Basis.IDENTITY
		result.x = ExpDecay(a.x,b.x,decay,dt)
		result.y = ExpDecay(a.y,b.y,decay,dt)
		result.z = ExpDecay(a.z,b.z,decay,dt)
		return result.orthonormalized()
	return b+(a-b)*exp(-decay*dt)


func SOD(current_value,current_velocity,target_value, Inputs : Vector3,delta: float) -> Dictionary:
	#x = frequency
	#y = damping ratio
	#z = reactivity
	var k1 = Inputs.y / (PI * Inputs.x)
	var k2 = 1 / pow(2 * PI * Inputs.x, 2)
	var k3 = Inputs.z * Inputs.y / (2 * PI * Inputs.x)
	
	var k2_stable = max(k2,1.1*(delta*delta/4 + delta*k1/2))
	
	if typeof(target_value) == TYPE_BASIS:
		var x_return = SOD(current_value.x,current_velocity.x,target_value.x,Inputs,delta)
		var y_return = SOD(current_value.y,current_velocity.y,target_value.y,Inputs,delta)
		var z_return = SOD(current_value.z,current_velocity.z,target_value.z,Inputs,delta)
		current_value.x=x_return["value"]
		current_value.y=y_return["value"]
		current_value.z=z_return["value"]
		current_velocity.x = x_return["velocity"]
		current_velocity.y = y_return["velocity"]
		current_velocity.z = z_return["velocity"]
	else:
		current_value += delta * current_velocity
		current_velocity += delta * (target_value + k3 * current_velocity - current_value - k1 * current_velocity) / k2_stable
	# Return the updated value and velocity as a dictionary
	return {"value": current_value, "velocity": current_velocity}

func NormalizeSign(Current : Quaternion,Target : Quaternion):
	if Current.dot(Target) >= 0:
		return Target.normalized()
	else:
		Target.inverse().normalized()
		return Target

static func ExpDecayAngle(a, b, decay:float, dt:float):
	var result
	if typeof(a)==TYPE_VECTOR3:
		a.x=ExpDecayAngle(a.x,b.x,decay,dt)
		a.y=ExpDecayAngle(a.y,b.y,decay,dt)
		a.z=ExpDecayAngle(a.z,b.z,decay,dt)
		result = a
	else:
		result = b + (fmod(2.0 * fmod(a - b, TAU),TAU) - fmod(a - b, TAU)) * exp(-decay *dt)
	return result
