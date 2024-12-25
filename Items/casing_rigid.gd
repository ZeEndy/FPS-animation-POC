extends RigidBody3D

@onready var col = get_node("CollisionShape3D")
var Audio : AudioStreamPlaybackPolyphonic
var timer = 3.0
var ImpactNormal:=Vector3.ZERO
@export var WallImpact : AudioStream
@export var FloorImpact : AudioStream 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("body_entered",PlayCasingSound)
	contact_monitor=true
	max_contacts_reported=2
	var streamplayer=get_node("AudioStreamPlayer3D")
	streamplayer.play()
	Audio=streamplayer.get_stream_playback()
	continuous_cd=true
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if freeze==false:
		col.disabled=false
		timer-=delta
		if timer<0 && Audio.is_stream_playing(0)==false:
			queue_free()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var ContactCount=state.get_contact_count()
	
	for i in ContactCount:
		ImpactNormal=state.get_contact_local_normal(i)


func PlayCasingSound(body:Node):
	if ImpactNormal.dot(Vector3.UP)<0.5:
		Audio.play_stream(WallImpact)
	else:
		Audio.play_stream(FloorImpact)
	pass
