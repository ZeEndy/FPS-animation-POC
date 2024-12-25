#@tool
extends RigidBody3D
class_name  Weapon

#This code only takes care of the weapon's animation tree and some basic recoil functionality
#note for future: This script should be obselete for the most part whenever the animationtree gets a blackboard
#because whoever decided to make it all parameters per node is a total fucking moron.
#This shit has been causing so much headache whenever the animationtree
#needs to be architected for more than baby's first 3D game I'm honestly surprised that we're already reaching 4.4 and this STILL hasn't been adressed


var VelocityPos = Vector3()
var VelocityAng = Basis()



enum InvBeheiv{
	Equiped,
	EquipedVisLeft,
	EquipedVisRight,
	Holstered
}

enum ProcessMode{
	Equiped,
	EquipedVis,
	Holstered,
	Free
}

var CurProcess = ProcessMode.Free

var teleport = false
var CurBeheivour=InvBeheiv.Equiped

@export var FirstPickUp = true
@export_range(-1,1) var LeftInfluence : float = 0.0
var OldLeftInfluence
signal LeftGrabbed
signal LeftLetGo

@export_range(-1,1) var RightInfluence : float = 0.0
var OldRightInfluence
signal RightGrabbed
signal RightLetGo

signal Holstered

@onready var DefaultShoulderPoint=get_node("Model/DefaultShoulderPoint")
@onready var skeleton : ValidSkeleton3D = get_node("Model/godot_rig/GeneralSkeleton")
@onready var ADSPoint = get_node("Model/AdsPoint")
@onready var Model : Node3D = get_node("Model")
@onready var Rig : Node3D = get_node("Model/godot_rig")
@onready var ModelPoint : Marker3D = get_node("Model/TransformPoint")

@onready var GunAudioNode : AudioStreamPlayer3D = get_node("Model/godot_rig/GeneralSkeleton/GunBody/GunAudioScript")
var GunAudio : AudioStreamPlaybackPolyphonic
@export var ADSIN : AudioStream
@export var ADSOUT : AudioStream

@onready var AnimTree : AnimationTree = get_node("AnimationTree")

@onready var BulletCast : RayCast3D = get_node("Model/godot_rig/GeneralSkeleton/GunBody/BulletCast")


@onready var Col = get_node("CollisionShape3D")
var ADSState = false
var Reload = false
@export var Firing = false

@export var CanADSMove := true


@export_category("Stats")
@export var QuickSwapable = false
var QuickSwaped=false

@export var RecoilCurve : Curve

@export_range(0,90,1,"radians_as_degrees") var MinRecoilX=0
@export_range(0,90,1,"radians_as_degrees") var MaxRecoilX=0

@export_range(-90,90,1,"radians_as_degrees") var MinRecoilY=0
@export_range(-90,90,1,"radians_as_degrees") var MaxRecoilY=0


@export_range(0,3,0.001,"suffix:cm") var ZPushMin=0.0
@export_range(0,3,0.001,"suffix:cm") var ZPushMax=0.0

@export_range(0,90,1,"radians_as_degrees") var ZTurn=0.0


var AnimADS = 0.0

@export var FireRate = 800.0

@export var MagSize = 50

@onready var Ammo=MagSize+1
@export var InChamberBullet=true
var Mag1AmmoCounterLerp=0.0
var Mag2AmmoCounterLerp=0.0
@export var AmmoCounterSteps = 1.0

var RecoilFactor=0
var Coefficient=0.12
var RecoilPos : Vector3
var RecoilRot : Vector3
var ModelPosition : Vector3
var ModelRotation : Vector3
@export var RecoilReductionStrength : float = 15.0

@export_category("AnimationStuff")
@export var reloading=false

var Mag1UseMag2=false
var Mag2UseMag1=false
var oldreload=false

var MovementSlider=0.0
var MovmentSliderInterp=0.0
var MovementPoint = Vector2(0,0)
var MovementTime = 0.0
var global_delta
@export var ADSReducer = 0.8
@export var CanSprint = true

@export var CopyLeftInfluance = 1.0
@export var CopyRightInfluance = 1.0

var Holder=null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GunAudioNode.play()
	GunAudio=GunAudioNode.get_stream_playback()
	AnimTree["parameters/Inactive/blend_amount"]=1.0
	AnimTree["parameters/FireRate/scale"]=1.0/(60.0/FireRate)
	pass # Replace with function body.


func AdsAudio(DesiredADSState : bool):
	if DesiredADSState != ADSState:
		if DesiredADSState == true:
			AnimADS = ADSReducer
			GunAudio.play_stream(ADSIN)
		else:
			AnimADS = 0.0
			GunAudio.play_stream(ADSOUT)
		ADSState = DesiredADSState
	pass

func TriggerSound(pressed : bool, Disconnector : AudioStream, DeadTrigger : AudioStream):
	if pressed:
		if Ammo==0:
			GunAudio.play_stream(DeadTrigger)
	else:
		if Ammo>0:
			GunAudio.play_stream(Disconnector)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if OldLeftInfluence!=LeftInfluence:
		if LeftInfluence==0.0:
			LeftLetGo.emit()
		if LeftInfluence==1.0:
			LeftGrabbed.emit()
		OldLeftInfluence=LeftInfluence
	
	if OldRightInfluence!=RightInfluence:
		if RightInfluence==0.0:
			RightLetGo.emit()
		if RightInfluence==1.0:
			RightGrabbed.emit()
		OldRightInfluence=RightInfluence
	
	global_delta=delta
	Mag1AmmoCounterLerp=ExpDecay(Mag1AmmoCounterLerp,((Ammo-1*int(InChamberBullet))/60.0)*AmmoCounterSteps,AnimTree["parameters/FireRate/scale"]*2,delta)
	Mag2AmmoCounterLerp=ExpDecay(Mag2AmmoCounterLerp,(MagSize/60.0)*AmmoCounterSteps,AnimTree["parameters/FireRate/scale"]*2,delta)
	Mag1AmmoCounterLerp=max(Mag1AmmoCounterLerp,0)
	Mag2AmmoCounterLerp=max(Mag2AmmoCounterLerp,0)
	AnimTree["parameters/MAG1AMMO/seek_request"] = Mag1AmmoCounterLerp * float(!Mag1UseMag2) + Mag2AmmoCounterLerp * float(Mag1UseMag2)
	AnimTree["parameters/MAG2AMMO/seek_request"] = Mag2AmmoCounterLerp * float(!Mag2UseMag1) + Mag1AmmoCounterLerp * float(Mag2UseMag1)
	AnimTree["parameters/ADS/blend_amount"]=ExpDecay(AnimTree["parameters/ADS/blend_amount"],AnimADS,40,delta)
	if QuickSwapable==true:
		AnimTree["parameters/QuickSwap/add_amount"]=ExpDecay(AnimTree["parameters/QuickSwap/add_amount"],float(QuickSwaped),2,delta)
	if Holder!=null && CurBeheivour==InvBeheiv.Equiped:
		
		MovmentSliderInterp=ExpDecay(MovmentSliderInterp,MovementSlider,10,delta)
		AnimTree["parameters/HandManipulation/Movement/Moving/blend_amount"]=clamp(MovmentSliderInterp,0,1)
		AnimTree["parameters/HandManipulation/Movement/SpeedState/blend_position"] = ExpDecay(AnimTree["parameters/HandManipulation/Movement/SpeedState/blend_position"],MovementPoint ,10 ,delta)
		AnimTree["parameters/HandManipulation/Movement/TimeSeek/seek_request"] = MovementTime
		AnimTree["parameters/HandManipulation/Reload/ADS/blend_amount"] = AnimTree["parameters/ADS/blend_amount"]
		AnimTree["parameters/HandManipulation/Reload Empty/ADS/blend_amount"] = AnimTree["parameters/ADS/blend_amount"]
		
		
		Reload = Input.is_action_just_pressed("ACTION4")
		Firing = Input.is_action_pressed("ACTION1")
		#if Input.is_action_just_pressed("ACTION3"):
			#AnimTree.active=!AnimTree.active
			#Ammo=0
		
	Model.position=ExpDecay(Model.position,RecoilPos,60,delta)
	Model.rotation=ExpDecay(Model.rotation,ModelPoint.basis*RecoilRot*0.5,60,delta)
	Engine.get_main_loop()
	RecoilPos = ExpDecay(RecoilPos,Vector3.ZERO,RecoilReductionStrength,delta)
	RecoilRot = ExpDecay(RecoilRot,Vector3.ZERO,RecoilReductionStrength,delta)
	
	if Firing==false:
		RecoilFactor=ExpDecay(RecoilFactor,0,RecoilReductionStrength,delta)
	#var KickTransform = Transform3D(Basis.from_euler(RecoilRot*Vector3(-1,1,1),EULER_ORDER_XYZ),RecoilPos*2*Vector3(1,1,1))
	#N_GunKicker.InputTransform = N_GunKicker.InputTransform.interpolate_with(KickTransform,min(20*delta,1))
	await skeleton.skeleton_updated
	var OldRigGlob=Rig.global_position
	var diff = Rig.position-ModelPoint.position
	if CurProcess!=ProcessMode.Free:
		Rig.position=diff
		global_position+=OldRigGlob-Rig.global_position
		Col.disabled=true
	else:
		Col.disabled=false
	#Rig.global_basis=(Rig.global_basis.orthonormalized()*ModelPoint.basis.inverse().orthonormalized()).orthonormalized()

func set_holder(obj):
	if obj==null:
		freeze=false
		Holder=null
		AnimTree["parameters/Inactive/blend_amount"]=1.0
	else:
		freeze=true
		Holder=obj
		AnimTree["parameters/Inactive/blend_amount"]=0.0


func RecoilKick():
	Ammo=max(Ammo-1,0)
	var HitTarget=BulletCast.get_collider()
	if HitTarget is HurtBox:
		HitTarget.RecieveHit(20)
	var Sample=RecoilCurve.sample(RecoilFactor)
	RecoilFactor=min(RecoilFactor+Coefficient,1)
	RecoilPos.z+=(randf_range(ZPushMin,ZPushMax)*0.1)*Sample
	#Model.position.x+=(randf_range(-1,1)*0.025)*RecoilFactor
	RecoilRot.x+=(deg_to_rad(randf_range(MinRecoilX,MaxRecoilX)))*Sample
	RecoilRot.y+=(deg_to_rad(randf_range(MinRecoilY,MaxRecoilY)))*Sample
	RecoilRot.z+= randf_range(-ZTurn,ZTurn)*Sample

func ReloadFunc():
	Ammo=min(Ammo+MagSize,MagSize+1)
	Mag1AmmoCounterLerp=((Ammo)/60.0)*AmmoCounterSteps

#func swap_mags(param:bool):
	#SwapMags=param
	#AnimTree["parameters/MAG1AMMO/seek_request"] = Mag1AmmoCounterLerp * float(!SwapMags) + Mag2AmmoCounterLerp * float(SwapMags)
	#AnimTree["parameters/MAG2AMMO/seek_request"] = Mag2AmmoCounterLerp * float(!SwapMags) + Mag1AmmoCounterLerp * float(SwapMags)

func SwapMag1(param:bool):
	Mag1UseMag2=param

func SwapMag2(param:bool):
	Mag2UseMag1=param

static func ExpDecay(a,b,decay,dt):
	return b+(a-b)*exp(-decay*dt)
