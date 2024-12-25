extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _init() -> void:
	RenderingServer.set_debug_generate_wireframes(true)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("DEBUGRESTART"):
		get_tree().reload_current_scene()
	if Input.is_action_just_pressed("DEBUGPAUSE"):
		get_tree().paused=true
