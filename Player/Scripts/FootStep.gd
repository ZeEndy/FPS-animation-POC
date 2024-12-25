extends AudioStreamPlayer3D

@onready var Parent : Player = get_parent().get_parent()# this should be the player

@export var JogSound : AudioStream
@export var RunSound : AudioStream

var Playback : AudioStreamPlaybackPolyphonic = null
var SelectedStream = null
var currentdelta : float
var minitimer=0.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play()
	Playback=get_stream_playback()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	currentdelta=delta
	minitimer=max(minitimer-delta,0.0)
	pass

func play_footstep():
	if minitimer==0.0:
		if Parent.is_on_floor():
			if Parent.CSpeedState==Player.SpeedState.Jog || Parent.CSpeedState==Player.SpeedState.Stop:
				SelectedStream = JogSound
			else:
				SelectedStream = RunSound
			Playback.play_stream(SelectedStream)
			minitimer=currentdelta
	
	pass
