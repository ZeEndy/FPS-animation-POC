extends Node3D

var Health = 100.0

var ResetTimer=0.0
#@onready var AnimTree = 
@onready var AnimTreeSM : AnimationNodeStateMachinePlayback = get_node("AnimationTree")["parameters/playback"]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	ResetTimer=max(ResetTimer-delta,0)
	pass


func _on_hit(HealthRemove: float) -> void:
	if Health!=0:
		Health=max(Health-HealthRemove,0.0)
		if Health>0.0:
			AnimTreeSM.start("Hit")
		if Health==0.0:
			AnimTreeSM.start("Die")
			ResetTimer=2.0
	pass # Replace with function body.

func ResetHealth():
	Health=100.0
